-- True color support
vim.opt.termguicolors = true

-- UTF-8 support
vim.opt.encoding = "utf-8"

-- Use 2 spaces for tabs
vim.opt.tabstop = 2

-- When deleting, use the same number of spaces as when adding
vim.opt.softtabstop = 2

-- Expand tabs to spaces
vim.opt.expandtab = true

-- Indent using spaces
vim.opt.shiftwidth = 2

-- Insert blanks as per shiftwidth when inserting before existing text
vim.opt.smarttab = true

-- Insert mode completion options
vim.opt.completeopt = "menuone,noinsert,noselect"

-- Show line diagnostics automatically in hover window
vim.o.updatetime = 250
vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]

-- Foldmethod
-- vim.opt.Foldmethod = "syntax"
