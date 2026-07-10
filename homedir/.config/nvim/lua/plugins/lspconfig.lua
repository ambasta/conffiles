return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        black = false,
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
        pyright = false,
        ruff = {
          settings = {
            configurationPreference = "filesystemFirst",
          },
          init_options = {},
        },
        tsgo = false,
        vtsls = {
          settings = {
            typescript = {
              tsdk = "./.yarn/sdks/typescript/lib",
            },
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["python"] = { "ruff_fix", "ruff_format" },
        ["cmake"] = { "gersemi" },
        ["sh"] = { "shfmt" },
      },
      formatters = {
        shfmt = {
          prepend_args = { "-ci", "-bn" },
        },
      },
    },
  },
  {
    "smjonas/inc-rename.nvim",
    opts = {},
  },
}
