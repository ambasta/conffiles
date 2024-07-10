return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = { mason = false },
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
}
