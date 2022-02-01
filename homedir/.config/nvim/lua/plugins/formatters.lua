local handler = require("null-ls")

handler.setup({
  sources = {
    handler.builtins.formatting.stylua,
    -- handler.builtins.formatting.prettier.with({
    --   command = "yarn",
    --   args = { "run", "-B", "prettier", "--stdin-filepath", "$FILENAME" }
    -- }),
    handler.builtins.formatting.black,
    handler.builtins.formatting.cmake_format,
  }
})

local exports = {
  handler = handler,
}

return exports
