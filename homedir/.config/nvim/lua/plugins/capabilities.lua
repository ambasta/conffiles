local handler = require("cmp_nvim_lsp")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = handler.update_capabilities(vim.lsp.protocol.make_client_capabilities())

local exports = {
	handler = handler,
	capabilities = capabilities,
}

return exports
