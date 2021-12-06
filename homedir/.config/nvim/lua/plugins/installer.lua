local handler = require('nvim-lsp-installer')
local utils = require('common.utils')
local capabilities = require('plugins.capabilities')

vim.g.lsp_installer_use_yarn = 1
-- handler.log_level = vim.log.levels.DEBUG

handler.on_server_ready(
  function (server)
    local opts = {
      on_attach = utils.on_attach,
      capabilities = capabilities.capabilities,
      flags = {
        debounce_text_changes = 150,
      }
    }

    if server.name == 'eslint' then
      local default_opts = server:get_default_options()
      opts.cmd = vim.list_extend({'yarn'}, default_opts.cmd)
    elseif server.name == 'lua' or server.name == 'sumneko_lua' then
      opts.settings = {
        Lua = {
          diagnostics = {
            enable = true,
            globals = {
              vim = true,
              vim_lsp = true,
            }
          }
        }
      }
    end

    server:setup(opts)
    vim.cmd [[ do User LspAttachBuffers ]]
  end
)

local exports = {
  handler = handler,
}

return exports
