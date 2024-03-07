local handler = require('telescope')
local yaml_companion = require('yaml-companion')

handler.setup({
  defaults = {
    mappings = {
      i = {
        ['<C-h>'] = 'which_key'
      }
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case',
    }
  },
})

handler.load_extension('fzf')
handler.load_extension('yaml_schema')
