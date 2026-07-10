-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Compat shim for plugins that use vim.hl on nvim < 0.11; never clobber the real API.
vim.hl = vim.hl or vim.highlight

-- Yarn PnP projects ship their own eslint language server; respawn the client
-- with `yarn exec` so it resolves the project's SDK instead of a global install.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client or client.name ~= "eslint" then
      return
    end

    if client.config._pnp_respawned then
      return
    end

    local root = client.config.root_dir
    if not root then
      return
    end

    local uv = vim.uv or vim.loop
    if not (uv.fs_stat(root .. "/.pnp.cjs") or uv.fs_stat(root .. "/.pnp.js")) then
      return
    end

    local desired = { "yarn", "exec", "vscode-eslint-language-server", "--stdio" }
    local current = client.config.cmd

    if type(current) == "table" and #current == #desired then
      local same = true
      for i, arg in ipairs(desired) do
        if current[i] ~= arg then
          same = false
          break
        end
      end
      if same then
        return
      end
    end

    local buf = args.buf
    local cfg = vim.tbl_deep_extend("force", {}, client.config, {
      cmd = desired,
      _pnp_respawned = true,
    })

    vim.lsp.stop_client(client.id, true)
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_call(buf, function()
          vim.lsp.start(cfg)
        end)
      end
    end, 20)
  end,
})
