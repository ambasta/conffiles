local handler = require("null-ls")
local resolver = require("null-ls.helpers.command_resolver")
local utils = require("common.utils")

handler.setup({
	sources = {
		handler.builtins.formatting.black,
		handler.builtins.formatting.cmake_format,
		handler.builtins.formatting.isort,
		handler.builtins.formatting.prettierd.with({
			dynamic_command = resolver.from_yarn_pnp(),
		}),
		handler.builtins.formatting.stylua,
	},
	on_attach = utils.on_attach,
})

local exports = {
	handler = handler,
}

return exports
