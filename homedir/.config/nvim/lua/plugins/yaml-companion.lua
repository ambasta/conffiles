local handler = require('yaml-companion')
local schemastore = require('schemastore')

handler.setup({
  builtin_matchers = {
    kubernetes = { enabled = true },
  },
  schemas = {
    {
      name = "Kustomization",
      uri = "https://json.schemastore.org/kustomization.json"
    },
    {
      name = "Flux GitRepository",
      uri = "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json"
    },
    {
      name = "GitHub Workflow",
      uri = "https://json.schemastore.org/github-workflow.json"
    }
  },
  lspconfig = {
    settings = {
      yaml = {
        validate = true,
        schemaStore = {
          enable = false,
          url = "",
        },
        schemas = schemastore.yaml.schemas({
          select = {
            'kustomization.yml',
            'Github Workflow',
          }
        })
      }
    }
  }
})

local exports = {
  handler = handler,
}

return exports
