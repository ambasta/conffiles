-- local unpack = table.unpack
local formatter = require("plugins.formatters")

local has_words_before = function()
	local line, column = unpack(vim.api.nvim_win_get_cursor(0))
	return column ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(column, column):match("%s") == nil
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local allowed

local format_sync = function()
	vim.lsp.buf.format({
		async = false,
		timeout_ms = 5000,
	})
end

local on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	local opts = {
		noremap = true,
		silent = true,
		buffer = bufnr,
	}

	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		client.server_capabilities.document_formatting = true

		-- if client.name ~= "tsserver" then
		-- 	if client.name == "eslint" then
		-- 		vim.api.nvim_create_autocmd("BufWritePre", {
		-- 			buffer = bufnr,
		-- 			command = "EslintFixAll",
		-- 		})
		-- 	else
		-- 		vim.api.nvim_create_autocmd("BufWritePre", {
		-- 			group = augroup,
		-- 			buffer = bufnr,
		-- 			callback = function()
		-- 				vim.lsp.buf.format({
		-- 					async = true,
		-- 					timeout_ms = 5000,
		-- 				})
		-- 			end,
		-- 		})
		-- 	end
		-- end
	end

	-- if client.name == "tsserver" then
	-- 	client.server_capabilities.document_formatting = false
	-- 	client.server_capabilities.document_range_formatting = false
	-- elseif client.name == "eslint" then
	-- 	client.server_capabilities.document_formatting = true
	-- end

	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set("n", "<C-f>", formatter.formatter, opts)
	vim.keymap.set("n", "<C-d>", "<cmd>EslintFixAll<CR>", opts)
end

local exports = {
	on_attach = on_attach,
	has_words_before = has_words_before,
}

return exports
