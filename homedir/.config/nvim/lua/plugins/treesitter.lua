local handler = require("nvim-treesitter.configs")

handler.setup({
  ensure_installed = "all",
  highlight = {
    enable = true,
  }
})

vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 4
vim.o.foldtext =
  [[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]
vim.opt.fillchars = {
  vert = "│", -- alternatives │
  fold = " ",
  eob = " ", -- suppress ~ at EndOfBuffer
  diff = "╱", -- alternatives = ⣿ ░ ─
  msgsep = " ",
  foldopen = "▾",
  foldsep = "│",
  foldclose = "▸",
}
vim.o.foldnestmax = 3
vim.o.foldminlines = 1
