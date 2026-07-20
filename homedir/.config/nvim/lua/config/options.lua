-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"

-- Keep tsgo selected for every TypeScript project, including Yarn PnP projects.
-- Native PnP resolution is still upstream work; do not fall back to vtsls.
vim.g.lazyvim_ts_lsp = "tsgo"
