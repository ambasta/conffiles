#!/bin/bash

COLOR_TEXT="#cdd6f4"
COLOR_SUBTEXT="#a6adc8"
COLOR_BLUE="#89b4fa"
COLOR_GREEN="#a6e3a1"
COLOR_MAUVE="#cba6f7"
COLOR_PEACH="#fab387"
COLOR_RED="#f38ba8"
COLOR_SAPPHIRE="#74c7ec"

json_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/ }
  value=${value//$'\r'/ }
  printf '%s' "$value"
}

emit_block() {
  local name=$1 text=$2 color=$3 urgent=${4:-false}
  printf '{"name":"%s","full_text":" %s ","color":"%s","separator":true,"separator_block_width":10,"urgent":%s}' \
    "$name" "$(json_escape "$text")" "$color" "$urgent"
}

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
    icon="HP"
    if [[ "$muted" == "MUTED" ]]; then
      icon="HP"
      color="$COLOR_RED"
    fi
  else
    icon="VOL"
    if [[ "$muted" == "MUTED" ]]; then
      color="$COLOR_RED"
    fi
  fi

  if [[ "$muted" == "MUTED" ]]; then
    emit_block audio "$icon muted" "$color"
  else
    emit_block audio "$icon ${volume}%" "$color"
  fi
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
  local state_text=""
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
      state_text=" · charging"
      color="$COLOR_BLUE"
      ;;
    "Full")
      state_text=" · full"
      color="$COLOR_GREEN"
      ;;
    "Discharging" | "Not charging")
      [[ "$status" == "Not charging" ]] && state_text=" · idle"
      if ((capacity <= 15)); then
        color="$COLOR_RED"
      elif ((capacity <= 30)); then
        color="$COLOR_PEACH"
      elif ((capacity <= 50)); then
        color="$COLOR_BLUE"
      elif ((capacity <= 75)); then
        color="$COLOR_BLUE"
      else
        color="$COLOR_GREEN"
      fi
      ;;
    *)
      state_text=" · $status"
      color="$COLOR_RED"
      ;;
  esac

  emit_block battery "BAT ${capacity}%${time_remaining}${state_text}" "$color" \
    "$([[ $color == "$COLOR_RED" ]] && printf true || printf false)"
}

get_clock() {
  local datetime
  printf -v datetime '%(%Y-%m-%d %H:%M)T' -1
  emit_block clock "$datetime" "$COLOR_TEXT"
}

# CPU usage needs a delta between two /proc/stat samples; the main loop keeps
# the previous sample in cpu_prev_total/cpu_prev_idle and passes usage in $1.
get_cpu() {
  local cpu_usage=$1
  local cpu_mhz color urgent=false f khz total_khz=0 count=0 average_khz

  # SMT-off leaves cpufreq links for offline siblings that return EBUSY. Read
  # one value per live policy instead of spawning an awk that logs an error on
  # every refresh.
  for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq; do
    IFS= read -r khz <"$f" 2>/dev/null || continue
    [[ $khz =~ ^[0-9]+$ ]] || continue
    total_khz=$((total_khz + khz))
    count=$((count + 1))
  done
  if ((count > 0)); then
    average_khz=$((total_khz / count))
    printf -v cpu_mhz '%d.%02d' \
      "$((average_khz / 1000000))" "$(((average_khz % 1000000) / 10000))"
  else
    cpu_mhz="N/A"
  fi

  if ((cpu_usage > 90)); then
    color="${COLOR_RED}"
  elif ((cpu_usage > 70)); then
    color="${COLOR_PEACH}"
  elif ((cpu_usage > 40)); then
    color="$COLOR_SAPPHIRE"
  else
    color="$COLOR_GREEN"
  fi
  ((cpu_usage > 90)) && urgent=true

  emit_block cpu "CPU ${cpu_mhz} GHz · ${cpu_usage}%" "$color" "$urgent"
}

get_memory() {
  local mem_info mem_percent urgent=false
  local color="$COLOR_MAUVE"
  mem_info=$(free -g | awk '/^Mem:/ {printf "%.1f", $3}')
  mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2) * 100}')

  if ((mem_percent > 90)); then
    color="$COLOR_RED"
  elif ((mem_percent > 70)); then
    color="$COLOR_PEACH"
  fi
  ((mem_percent > 90)) && urgent=true

  emit_block memory "RAM ${mem_info}G · ${mem_percent}%" "$color" "$urgent"
}

get_microphone() {
  local volume_info muted
  volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)

  if [[ -z "$volume_info" ]]; then
    return
  fi

  volume=$(echo "$volume_info" | awk '{print int($2 * 100)}')
  muted=$(echo "$volume_info" | grep -o "MUTED")
  local color="$COLOR_GREEN"

  if [[ "$muted" == "MUTED" ]]; then
    color="$COLOR_RED"
    emit_block microphone "MIC muted" "$color"
  else
    emit_block microphone "MIC ${volume}%" "$color"
  fi
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
          ssid=$(iw dev "$ifname" link 2>/dev/null | sed -n 's/^[[:space:]]*SSID: //p')

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
      fi
    fi
  done

  if [[ ${#interfaces[@]} -eq 0 ]]; then
    emit_block network "NET offline" "$COLOR_RED" true
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

  emit_block network "NET${combined_status}" "$color"
}

get_temp() {
  local temp temp_max temp_crit color
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
    emit_block temperature "TEMP N/A" "$COLOR_SUBTEXT"
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

  emit_block temperature "TEMP ${temp}°C" "$color" \
    "$([[ $color == "$COLOR_RED" ]] && printf true || printf false)"
}

get_power_mode() {
  local runtime_root=${XDG_RUNTIME_DIR:-/run/user/$UID}
  local user_dir="$runtime_root/extreme-powersave-user"
  local runtime_policy_file=/run/extreme-powersave.runtime-pm-policy
  local root_on=0 user_on=0 boost=unknown runtime_policy=unknown

  if [[ -e /run/extreme-powersave.recovery ]]; then
    emit_block power "POWER recovery" "$COLOR_RED" true
    return
  fi

  if [[ -e /run/extreme-powersave.pending || -e "$user_dir/pending" ]]; then
    emit_block power "POWER transition" "$COLOR_RED" true
    return
  fi

  [[ -e /run/extreme-powersave.state ]] && root_on=1
  [[ -e "$user_dir/state" ]] && user_on=1

  if [[ -r $runtime_policy_file ]]; then
    IFS= read -r runtime_policy <"$runtime_policy_file"
  fi

  if [[ ! $runtime_policy =~ ^(performance|powersave)$ ]]; then
    emit_block power "POWER policy-missing" "$COLOR_RED" true
  elif ((root_on)) && [[ $runtime_policy != powersave ]]; then
    emit_block power "POWER mismatch" "$COLOR_RED" true
  elif ((root_on && user_on)); then
    emit_block power "POWER max-save" "$COLOR_BLUE"
  elif ((root_on)); then
    emit_block power "POWER root-save" "$COLOR_PEACH"
  elif ((user_on)); then
    emit_block power "POWER user-save" "$COLOR_PEACH"
  else
    [[ -r /sys/devices/system/cpu/cpufreq/boost ]] && \
      IFS= read -r boost </sys/devices/system/cpu/cpufreq/boost
    if [[ $boost == 1 && $runtime_policy == performance ]]; then
      emit_block power "POWER performance" "$COLOR_GREEN"
    else
      emit_block power "POWER limited" "$COLOR_RED" true
    fi
  fi
}

get_display_brightness() {
  local helper="$HOME/.local/bin/display-brightness" status color=$COLOR_BLUE
  [[ -x $helper ]] || return
  status=$($helper status --bar 2>/dev/null) || return
  [[ -n $status ]] || return
  [[ $status == *"unavailable"* || $status == *"offline"* ]] && color=$COLOR_RED
  emit_block display "$status" "$color"
}

add_block() {
  [[ -n "$1" ]] && blocks+=("$1")
}

cpu_prev_total=0
cpu_prev_idle=0
display_block=""
display_last_refresh=-5

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

  add_block "$(get_power_mode)"
  if ((SECONDS - display_last_refresh >= 5)); then
    display_block=$(get_display_brightness)
    display_last_refresh=$SECONDS
  fi
  add_block "$display_block"
  add_block "$(get_network)"
  add_block "$(get_cpu "$cpu_usage")"
  add_block "$(get_temp)"
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
  # The user-session extreme power toggle owns this marker. Poll less often
  # while it is active, then return to the normal responsive interval on off.
  if [[ -f ${XDG_RUNTIME_DIR:-/run/user/$UID}/extreme-powersave-user/state ]]; then
    sleep 5
  else
    sleep 1
  fi
done
