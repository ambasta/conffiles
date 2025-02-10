local lspconfig_util = require("lspconfig.util")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          root_dir = function(startpath)
            return vim.fs.dirname(vim.fs.find("yarn.lock", { path = startpath, upward = true })[1])
          end,
        },
        clangd = {
          mason = false,
          cmd = {
            "clangd",
            "--background-index",
            "--experimental-modules-support",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
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
        tsserver = {
          enabled = false,
        },
        ts_ls = {
          enabled = false,
        },
        vtsls = {
          root_dir = function(startpath)
            return vim.fs.dirname(vim.fs.find("yarn.lock", { path = startpath, upward = true })[1])
          end,
          settings = {
            autoUseWorkspaceTsdk = true,
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
        ["python"] = { "isort", "black" },
        ["cmake"] = { "gersemi" },
      },
    },
  },
}
