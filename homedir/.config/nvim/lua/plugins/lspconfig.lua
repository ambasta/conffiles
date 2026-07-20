local oxfmt_filetypes = {
  "astro",
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "json5",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "svelte",
  "toml",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        black = false,
        eslint = { enabled = false },
        neocmake = {
          cmd = { "neocmakelsp", "--stdio" },
          single_file_support = true,
          init_options = {
            format = {
              enable = true,
            },
            line = {
              enable = true,
            },
          },
        },
        oxlint = { enabled = true },
        pyright = false,
        ruff = {
          settings = {
            configurationPreference = "filesystemFirst",
          },
          init_options = {},
        },
        ts_ls = { enabled = false },
        tsgo = { enabled = true },
        vtsls = { enabled = false },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_fix", "ruff_format" }
      opts.formatters_by_ft.cmake = { "gersemi" }
      opts.formatters_by_ft.sh = { "shfmt" }

      for _, filetype in ipairs(oxfmt_filetypes) do
        local formatters = vim.tbl_filter(function(formatter)
          return formatter ~= "oxfmt" and formatter ~= "prettier" and formatter ~= "prettierd"
        end, opts.formatters_by_ft[filetype] or {})
        table.insert(formatters, 1, "oxfmt")
        opts.formatters_by_ft[filetype] = formatters
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.shfmt = {
        prepend_args = { "-ci", "-bn" },
      }
    end,
  },
  {
    "smjonas/inc-rename.nvim",
    opts = {},
  },
}
