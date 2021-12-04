" True colors for nvim
set termguicolors
set encoding=UTF-8
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab

" tab navigation like firefox
" Map normal mode
nmap <C-t> :tabnew<CR>
nmap <C-x> :tabnext<CR>
nmap <C-z> :tabprevious<CR>

filetype plugin indent on
syntax enable

set completeopt=menu,menuone,noselect

" Color scheme settings
" Our terminal can handle italics so enable that
let g:gruvbox_italic=1
let g:gruvbox_contrast_dark = 'hard'
let g:gruvbox_colors = { 'bg0': ['#000000', 0] }
let g:lsp_installer_use_yarn = 1
colorscheme gruvbox

" ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'}),
" ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})
"
lua << EOF
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

local cmp = require'cmp'
local lsp_installer = require"nvim-lsp-installer"
local nvim_lsp = require'lspconfig'
local null_ls = require('null-ls')
local capabilities = require('cmp_nvim_lsp')
local luasnip = require('luasnip')

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<C-f>', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

local on_attach_no_formatting = function(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
    on_attach(client, bufnr)
end

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

--         ["<Tab>"] = cmp.mapping(function(fallback)
--             if cmp.visible() then
--                 local entry = cmp.get_selected_entry()
--                 if not entry then
--                     cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
--                 end
--                 cmp.confirm()
--             else
--                 local copilot_keys = vim.fn["copilot#Accept"]()
-- 
--                 if copilot_keys ~= "" then
--                     vim.api.nvim_feedkeys(copilot_keys, "i", true)
--                 else
--                     fallback()
--                 end
--             end
--         end, {"i", "s", "c",}),

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    mapping = {
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), {'i', 'c'}),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                local copilot_keys = vim.fn['copilot#Accept']()

                if copilot_keys ~= '' then
                    vim.api.nvim_feedkeys(copilot_keys, 'i', true)
                else
                    fallback()
                end
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                local copilot_keys = vim.fn['copilot#Accept']()

                if copilot_keys ~= '' then
                    vim.api.nvim_feedkeys(copilot_keys, 'i', true)
                else
                    fallback()
                end
            end
        end, { 'i', 's' }),
        ['<C-y>'] = cmp.config.disable,
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
    }, {
        { name = 'buffer' }
    })
})

cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' }
    }
})

cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})

lsp_installer.log_level = vim.log.levels.DEBUG

capabilities.update_capabilities(vim.lsp.protocol.make_client_capabilities())

lsp_installer.on_server_ready(function(server)
    local opts = {
        on_attach = on_attach,
        capabilties = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
    server:setup(opts)
    vim.cmd [[ do User LspAttachBuffers ]]
end)

null_ls.config({
    sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.black
    }
})

local servers = { 'clangd', 'cmake', 'eslint', 'gopls', 'pyright', 'rls', 'tsserver', 'null-ls'}

for _, server in ipairs(servers) do
    local opts = {
        on_attach = on_attach,
        capabilties = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
    if server == 'tsserver' then
        opts.cmd = { 'yarn', 'typescript-language-server', '--stdio' }
    elseif server == 'eslint' then
        opts.cmd = { 'yarn', 'vscode-eslint-language-server', "--stdio" }
    elseif server == 'pyright' then
        opts.on_attach = on_attach_no_formatting
    end
    
    nvim_lsp[server].setup(opts)
    vim.cmd [[ do User LspAttachBuffers ]]
end

nvim_lsp['jsonls'].setup({
    commands = {
      Format = {
        function()
          vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
        end
      }
    }
})

-- vim.lsp.set_log_level("debug")
EOF
