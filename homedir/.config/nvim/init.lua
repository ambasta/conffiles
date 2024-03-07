require("common.settings")
require("common.keymaps")
require("plugins.treesitter")
require("plugins.gruvbox")
require("plugins.telescope")
-- require('plugins.copilot')
require("plugins.complete")
require("plugins.installer")
require("plugins.formatters")
require("plugins.servers")
-- require('plugins.jdtls')
vim.lsp.set_log_level("debug")
-- autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll

local function get_schema()
  local schema = require("yaml-companion").get_buf_schema(0)
  if schema.result[1].name == "none" then
    return "NoSchema"
  end
  return schema.result[1].name
end

_G.get_schema = get_schema
