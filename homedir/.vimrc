set term=xterm-256color
set encoding=UTF-8
set expandtab

" tab navigation like firefox
" Map normal mode
nmap <C-t> :tabnew<CR>
nmap <C-x> :tabnext<CR>
nmap <C-z> :tabprevious<CR>

" Rootpatterns for typescript/javascript monorepo w/ pnp
" autocmd FileType typescript let b:coc_root_patterns=["yarn.lock", "npm.lock"]

" Use vim mode (instead of pure vi mode)
if &compatible
  set nocompatible
endif
"-----------------------------dein Scripts-----------------------------
" Add the dein installation directory into runtimepath
set runtimepath+=/home/amitprakash/.cache/dein/repos/github.com/Shougo/dein.vim
" Add the dein installation directory into runtimepath
call dein#begin('/home/amitprakash/.cache/dein')
" Start dein
call dein#add('/home/amitprakash/.cache/dein/repos/github.com/Shougo/dein.vim')

" Add coc
call dein#add('neoclide/coc.nvim', { 'merged': 0, 'rev': 'release' })
" Add gentoo syntax
call dein#add('gentoo/gentoo-syntax')
" JSON with C style comments
call dein#add('kevinoid/vim-jsonc')

" Required by dein
call dein#end()

" Install missing plugins on startup
if dein#check_install()
  call dein#install()
endif

"-----------------------------dein Scripts-------------------------

" Enable filetype detection (filetype on)
" Enable plugins on the basis of filetype (filetype plugin on)
" Enable indentation on the basis of filetype (filetype indent on)
filetype plugin indent on

" Enable syntax highlighting
syntax enable
"-------------------------coc settings-------------------------
" Map control-space to trigger completion
inoremap <silent><expr> <NUL> coc#refresh()

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Map carriage return to confirm competion only when there is a selected
" complete item
if exists('*complete_info')
  inoremap <silent><expr> <cr> complete_info(['selected'])['selected'] != -1 ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Enable semantic highlights
let g:coc_default_semantic_highlight_groups = 1
"-------------------------coc settings-------------------------
