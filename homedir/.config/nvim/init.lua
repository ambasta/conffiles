-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Compat shim for plugins that use vim.hl on nvim < 0.11; never clobber the real API.
vim.hl = vim.hl or vim.highlight
