vim.api.nvim_set_keymap("n", "<C-t>", ":tabnew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-x>", ":tabnext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-z>", ":tabprevious<CR>", { noremap = true, silent = true })

local exports = {
	mapping = {
		-- Fetch competion options
		autocomplete_fch = "<C-Space>",
		-- Autocomplete forward
		autocomplete_fwd = "<Tab>",
		-- Autocomplete backward
		autocomplete_rev = "<S-Tab>",
		-- Autocomplete disable
		autocomplete_dis = "<C-y>",
		-- Autocomplete enable
		autocomplete_ena = "<C-e>",
		-- Autocomplete Confirm
		autocomplete_cnf = "<CR>",
	},
}

return exports
