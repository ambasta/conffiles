local handler = require('yaml-companion')
local schemastore = require('schemastore')

handler.setup({
  builtin_matchers = {
    kubernetes = { enabled = true },
  },
  schemas = {
    result = {
      {
        name = "Kustomization",
        uri = "https://json.schemastore.org/kustomization.json"
      },
      {
        name = "Flux Alert Notification",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/alert-notification-v1beta3.json',
      },
      {
        name = "Flux Bucket Source",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/bucket-source-v1beta2.json',
      },
      {
        name = "Flux GitRepository",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json',
      },
      {
        name = "Flux HelmChart",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmchart-source-v1beta2.json',
      },
      {
        name = "Flux HelmRelease",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrelease-helm-v2beta2.json',
      },
      {
        name = "Flux HelmRepository",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrepository-source-v1beta2.json',
      },
      {
        name = "Flux ImagePolicy",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/imagepolicy-image-v1beta2.json',
      },
      {
        name = "Flux ImageRepository",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/imagerepository-image-v1beta2.json',
      },
      {
        name = "Flux ImageUpdateAutomation",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/imageupdateautomation-image-v1beta1.json',
      },
      {
        name = "Flux Kustomization",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/kustomization-kustomize-v1.json',
      },
      {
        name = "Flux OCIRepository",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/ocirepository-source-v1beta2.json',
      },
      {
        name = "Flux ProviderNotification",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/provider-notification-v1beta3.json',
      },
      {
        name = "Flux ReceiverNotification",
        uri = 'https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/receiver-notification-v1.json',
      },
      {
        name = "GitHub Workflow",
        uri = "https://json.schemastore.org/github-workflow.json"
      },
    },
  },
  lspconfig = {
    settings = {
      redhat = {
        telemetry = {
          enabled = false,
        },
      },
      yaml = {
        validate = {
          enable = true,
        },
        format = {
          enable = true,
        },
        schemaStore = {
          enable = false,
          url = "",
        },
        schemaDownload = {
          enable = true,
        },
        schemas = schemastore.yaml.schemas(),
      }
    }
  }
})

local exports = {
  handler = handler,
}

return exports
