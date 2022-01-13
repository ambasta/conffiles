local handler = require("lspconfig")
local utils = require("common.utils")
local capabilities = require("plugins.capabilities")
local lspconfig_util = require("lspconfig.util")

local servers = {
  "angularls",
	"clangd",
	"cmake",
	"eslint",
	"jsonls",
	"gopls",
	"pyright",
	"rls",
	"tsserver"
}

for _, server in ipairs(servers) do
	local opts = {
		on_attach = utils.on_attach,
		capabilities = capabilities.capabilities,
		flags = {
			debounce_text_changes = 150,
		},
	}

	if server == "tsserver" then
		local default_opts = require("lspconfig.server_configurations.tsserver")
		opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
    opts.root_dir = lspconfig_util.root_pattern(".yarn")
	elseif server == "eslint" then
		local default_opts = require("lspconfig.server_configurations.eslint")
		opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
    opts.root_dir = lspconfig_util.root_pattern(".yarn")
	elseif server == "jsonls" then
		local default_opts = require("lspconfig.server_configurations.jsonls")
		opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
		opts.root_dir = lspconfig_util.root_pattern(".yarn")
	elseif server == "angularls" then
		local default_opts = require("lspconfig.server_configurations.angularls")
    local cmd = {"yarn", "ngserver", "--stdio", "--tsProbeLocations", "./", "--ngProbeLocations", "./"}
    -- opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
    opts.cmd = cmd
		opts.root_dir = lspconfig_util.root_pattern("angular.json")
    opts.on_new_config = function(new_config, new_root_dir)
      new_config.cmd = opts.cmd
    end
	elseif server == "pyright" then
		opts.on_attach = utils.on_attach_noformat
	elseif server == "jsonls" then
		opts.commands = {
			Format = {
				function()
					vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
				end,
			},
		}
	end

	handler[server].setup(opts)
	vim.cmd([[ do User LspAttachBuffers ]])
end

local exports = {
	handler = handler,
}

return exports
