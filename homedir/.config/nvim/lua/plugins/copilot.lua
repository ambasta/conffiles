vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

local keys = vim.fn["copilot#Accept"]()

local exports = {
	keys = keys,
}

return exports
