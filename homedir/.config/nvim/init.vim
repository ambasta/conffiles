" True colors for nvim
set termguicolors
set encoding=UTF-8
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

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

lua << EOF
local cmp = require'cmp'
local lsp_installer = require"nvim-lsp-installer"
local nvim_lsp = require'lspconfig'
local capabilities = require('cmp_nvim_lsp')

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

cmp.setup({
    mapping = {
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), {'i', 'c'}),
        ['<C-y>'] = cmp.config.disable,
        ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'}),
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

local servers = { 'clangd', 'eslint', 'gopls', 'rls', 'cmake'}

for _, server in ipairs(servers) do
    local opts = {
        on_attach = on_attach,
        capabilties = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
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

EOF
