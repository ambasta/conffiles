local handler = require('null-ls')

handler.config({
  sources = {
    handler.builtins.formatting.stylua,
    handler.builtins.formatting.black,
  }
})

local exports = {
  handler = handler
}

return exports
