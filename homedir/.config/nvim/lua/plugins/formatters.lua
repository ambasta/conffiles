local handler = require("conform")

handler.setup({
  formatters_by_ft = {
    go = { "goimports", "gofmt" },
    lua = { "stylua" },
    python = { "isort", "black" },
    toml = { "taplo" },
    cmake = { "cmake_format" },
  },
})

local formatter = function()
  handler.format({
    async = true,
    lsp_fallback = true,
  })
end


local exports = {
	handler = handler,
  formatter = formatter,
}

return exports
