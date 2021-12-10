local handler = require("cmp")
local keymaps = require("common.keymaps")
-- local utils = require("common.utils")
local snippet = require("plugins.snippet")

handler.setup({
	snippet = {
		expand = function(args)
			snippet.handler.lsp_expand(args.body)
		end,
	},
	mapping = {
		[keymaps.mapping.autocomplete_fch] = handler.mapping(handler.mapping.complete(), { "i", "c" }),
		[keymaps.mapping.autocomplete_fwd] = handler.mapping(function(fallback)
			if handler.visible() then
				handler.select_next_item()
			elseif snippet.handler.expand_or_jumpable() then
				snippet.handler.expand_or_jump()
			else
				local copilot_keys = vim.fn["copilot#Accept"]()

				if copilot_keys ~= "" then
					vim.api.nvim_feedkeys(copilot_keys, "i", true)
				else
					fallback()
				end
			end
		end, { "i", "s" }),
		[keymaps.mapping.autocomplete_rev] = handler.mapping(function(fallback)
			if handler.visible() then
				handler.select_prev_item()
			elseif snippet.handler.jumpable(-1) then
				snippet.handler.jump(-1)
			else
				local copilot_keys = vim.fn["copilot#Accept"]()

				if copilot_keys ~= "" then
					vim.api.nvim_feedkeys(copilot_keys, "i", true)
				else
					fallback()
				end
			end
		end, { "i", "s" }),
		[keymaps.mapping.autocomplete_dis] = handler.config.disable,
		[keymaps.mapping.autocomplete_ena] = handler.mapping({
			i = handler.mapping.abort(),
			c = handler.mapping.close(),
		}),
		[keymaps.mapping.autocomplete_cnf] = handler.mapping.confirm({ select = true }),
	},
	sources = handler.config.sources({
		{ name = "nvim_lsp" },
	}),
})

local exports = {
	handler = handler,
}

return exports
