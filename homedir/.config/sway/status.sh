#!/bin/bash

COLOR_TEXT="#cdd6f4"
COLOR_SUBTEXT="#a6adc8"
COLOR_BLUE="#89b4fa"
COLOR_GREEN="#a6e3a1"
COLOR_MAUVE="#cba6f7"
COLOR_PEACH="#fab387"
COLOR_RED="#f38ba8"
COLOR_SAPPHIRE="#74c7ec"

# Output JSON header
echo '{"version":1}'
echo '['

get_audio() {
  local sink_info volume_info volume muted
  local icon=""
  local color="$COLOR_BLUE"

  volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
  [[ -z "$volume_info" ]] && return
  volume=$(echo "$volume_info" | awk '{print int($2 * 100)}')
  muted=$(echo "$volume_info" | grep -o "MUTED")
  sink_info=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null)

  if echo "$sink_info" | grep -iq "headphone\|headset"; then
    icon=""
    if [[ "$muted" == "MUTED" ]]; then
      icon="🗙"
      color="$COLOR_RED"
    fi
  else
    if [[ "$muted" == "MUTED" ]]; then
      icon=""
      color="$COLOR_RED"
    fi
  fi

  echo "{\"full_text\":\" $icon ${volume}% \",\"color\":\"$color\",\"separator\":true}"
}

battery_dir() {
  local dir
  for dir in /sys/class/power_supply/BAT*; do
    if [[ -f "$dir/capacity" ]]; then
      echo "$dir"
      return
    fi
  done
}

get_battery() {
  local dir capacity status
  local icon=""
  local color="$COLOR_GREEN"
  local time_remaining=""

  dir=$(battery_dir)
  [[ -z "$dir" ]] && return

  capacity=$(cat "$dir/capacity")
  status=$(cat "$dir/status")

  if command -v acpi &>/dev/null; then
    time_remaining=$(acpi -b | grep -Po '\d{2}:\d{2}' | head -1)

    if [[ -n "$time_remaining" ]]; then
      time_remaining=" $time_remaining"
    fi
  fi

  case "$status" in
    "Charging")
      icon=""
      color="$COLOR_BLUE"
      ;;
    "Full")
      icon=""
      color="$COLOR_GREEN"
      ;;
    "Discharging" | "Not charging")
      if ((capacity <= 15)); then
        icon=""
        color="$COLOR_RED"
      elif ((capacity <= 30)); then
        icon=""
        color="$COLOR_PEACH"
      elif ((capacity <= 50)); then
        icon=""
        color="$COLOR_BLUE"
      elif ((capacity <= 75)); then
        icon=""
        color="$COLOR_BLUE"
      else
        icon=""
        color="$COLOR_GREEN"
      fi
      ;;
    *)
      icon="?"
      color="$COLOR_RED"
      ;;
  esac

  echo "{\"full_text\":\" $icon ${capacity}%${time_remaining} \",\"color\":\"$color\",\"separator\":true}"
}

get_clock() {
  local datetime
  printf -v datetime '%(%Y-%m-%d %H:%M)T' -1
  echo "{\"full_text\":\"  $datetime \",\"color\":\"$COLOR_TEXT\"}"
}

# CPU usage needs a delta between two /proc/stat samples; the main loop keeps
# the previous sample in cpu_prev_total/cpu_prev_idle and passes usage in $1.
get_cpu() {
  local cpu_usage=$1
  local cpu_mhz color
  local icon=""
  cpu_mhz=$(awk '{sum+=$1; count++} END {printf "%.2f", sum/count/1e6}' /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq)

  if ((cpu_usage > 90)); then
    color="${COLOR_RED}"
  elif ((cpu_usage > 70)); then
    color="${COLOR_PEACH}"
  elif ((cpu_usage > 40)); then
    color="$COLOR_SAPPHIRE"
  else
    color="$COLOR_GREEN"
  fi

  echo "{\"full_text\":\" $icon ${cpu_mhz}GHz ${cpu_usage}% \",\"color\":\"$color\",\"separator\":true}"
}

get_memory() {
  local mem_info mem_percent
  local color="$COLOR_MAUVE"
  local icon=""
  mem_info=$(free -g | awk '/^Mem:/ {printf "%.1f", $3}')
  mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2) * 100}')

  if ((mem_percent > 90)); then
    color="$COLOR_RED"
  elif ((mem_percent > 70)); then
    color="$COLOR_PEACH"
  fi

  echo "{\"full_text\":\" $icon ${mem_info}G \",\"color\":\"$color\",\"separator\":true}"
}

get_microphone() {
  local volume_info muted
  local icon=""
  volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)

  if [[ -z "$volume_info" ]]; then
    return
  fi

  volume=$(echo "$volume_info" | awk '{print int($2 * 100)}')
  muted=$(echo "$volume_info" | grep -o "MUTED")
  local color="$COLOR_GREEN"

  if [[ "$muted" == "MUTED" ]]; then
    icon=""
    color="$COLOR_RED"
  fi

  echo "{\"full_text\":\" $icon ${volume}% \",\"color\":\"$color\",\"separator\":true}"
}

get_network() {
  local interfaces=()

  for iface in /sys/class/net/*; do
    local ifname
    ifname=$(basename "$iface")

    [[ "$ifname" == "lo" ]] && continue

    if [[ -f "$iface/carrier" ]]; then
      local carrier operstate

      carrier=$(cat "$iface/carrier" 2>/dev/null || echo "0")
      operstate=$(cat "$iface/operstate" 2>/dev/null || echo "down")

      if [[ "$carrier" == "1" ]] && [[ "$operstate" == "up" ]]; then
        local status=""

        if [[ "$ifname" =~ ^wl ]]; then
          local ssid
          ssid=$(iwgetid -r "$ifname" 2>/dev/null)

          if [[ -n "$ssid" ]]; then
            status="  $ssid"
          else
            status="  WiFi"
          fi
        elif [[ "$ifname" =~ ^en|^eth ]]; then
          status=" $ifname"
        else
          status=" $ifname"
        fi

        interfaces+=("$status")
      elif [[ "$operstate" == "down" ]] || [[ "$carrier" == "0" ]]; then

        if [[ "$ifname" =~ ^wl ]]; then
          interfaces+=("")
        elif [[ "$ifname" =~ ^en|^eth ]]; then
          interfaces+=("")
        fi
      fi
    fi
  done

  if [[ ${#interfaces[@]} -eq 0 ]]; then
    return
  fi

  local combined_status=""

  for i in "${!interfaces[@]}"; do
    combined_status+="${interfaces[$i]}"

    if [[ $i -lt $((${#interfaces[@]} - 1)) ]]; then
      combined_status+=" | "
    fi
  done

  local color="$COLOR_SAPPHIRE"

  if [[ "$combined_status" =~ "Down" ]]; then
    color="$COLOR_PEACH"
  fi

  echo "{\"full_text\":\" $combined_status \",\"color\":\"$color\",\"separator\":true}"
}

get_temp() {
  local temp temp_max temp_crit color
  local icon="󰔏"
  local base f label

  # hwmon numbering is not stable across boots; scan all of them for the CPU sensor.
  for f in /sys/class/hwmon/hwmon*/temp*_input; do
    label=$(cat "${f%_input}_label" 2>/dev/null)
    [[ "$label" == "cpu_f75303@4d" || "$label" == "Tctl" || "$label" == "Package id 0" ]] || continue
    base="${f%_input}"
    temp=$(awk '{printf "%.0f", $1/1000}' "$f")
    temp_max=$(awk '{printf "%.0f", $1/1000}' "${base}_max" 2>/dev/null)
    temp_crit=$(awk '{printf "%.0f", $1/1000}' "${base}_crit" 2>/dev/null)
    break
  done

  if [[ -z "$temp" ]]; then
    echo "{\"full_text\":\" $icon N/A \",\"color\":\"$COLOR_SUBTEXT\",\"separator\":true}"
    return
  fi

  if [[ -n "$temp_crit" ]] && ((temp > temp_crit)); then
    color="$COLOR_RED"
  elif [[ -n "$temp_max" ]] && ((temp > temp_max)); then
    color="$COLOR_PEACH"
  elif [[ -n "$temp_max" ]] && ((temp > temp_max * 75 / 100)); then
    color="$COLOR_SAPPHIRE"
  else
    color="$COLOR_GREEN"
  fi

  echo "{\"full_text\":\" $icon ${temp}°C \",\"color\":\"$color\",\"separator\":true}"
}

add_block() {
  [[ -n "$1" ]] && blocks+=("$1")
}

cpu_prev_total=0
cpu_prev_idle=0

while true; do
  echo "["

  # shellcheck disable=SC2034 # discard trailing /proc/stat fields
  read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
  cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  cpu_idle=$((idle + iowait))
  cpu_dt=$((cpu_total - cpu_prev_total))
  cpu_usage=0
  if ((cpu_dt > 0)); then
    cpu_usage=$(((cpu_dt - (cpu_idle - cpu_prev_idle)) * 100 / cpu_dt))
  fi
  cpu_prev_total=$cpu_total
  cpu_prev_idle=$cpu_idle

  blocks=()

  add_block "$(get_network)"
  add_block "$(get_temp)"
  add_block "$(get_cpu "$cpu_usage")"
  add_block "$(get_memory)"
  add_block "$(get_audio)"
  add_block "$(get_microphone)"
  add_block "$(get_battery)"
  add_block "$(get_clock)"

  for i in "${!blocks[@]}"; do
    printf '%s' "${blocks[$i]}"

    if [[ $i -lt $((${#blocks[@]} - 1)) ]]; then
      printf ','
    fi
  done

  echo "],"
  sleep 1
done
