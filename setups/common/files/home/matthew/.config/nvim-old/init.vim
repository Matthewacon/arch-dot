"Vundle config
set nocompatible              " be iMproved, required
filetype off                  " required

"Workaround for use with kitty
let &t_ut=''

" set the runtime path to include Vundle and initialize
set rtp+=/usr/share/vim/vimfiles/autoload/vundle.vim

call vundle#begin('~/.config/nvim/bundle')
 " let Vundle manage Vundle, required
 " Plugin 'VundleVim/Vundle.vim'
 "Autocomplete and syntax highlight
 Plugin 'neoclide/coc.nvim', {'branch': 'release'}
 Plugin 'neovim/nvim-lspconfig'
 Plugin 'hrsh7th/nvim-cmp'
 "Plugin 'jackguo380/vim-lsp-cxx-highlight'
 "Airline
 Plugin 'vim-airline/vim-airline'
 Plugin 'vim-airline/vim-airline-themes'
 "Git integration w/ airline
 Plugin 'tpope/vim-fugitive'
 "File icons
 Plugin 'kyazdani42/nvim-web-devicons'
 "Colour schemes
 Plugin 'arcticicestudio/nord-vim'
 Plugin 'folke/tokyonight.nvim', { 'branch': 'main' }
 Plugin 'rainglow/vim'
 "Gotham colour scheme
 Plugin 'whatyouhide/vim-gotham'
 "CMake build integration
 Plugin 'vhdirk/vim-cmake'
 "Nvim-tree
 "NOTE: Nice plugin, but very bugggy unfortunately
 "Plugin 'kyazdani42/nvim-tree.lua'
 "Nvim-treesitter
 Plugin 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
 "Vim telescope
 Plugin 'nvim-lua/plenary.nvim'
 Plugin 'nvim-telescope/telescope.nvim'
 "barbar
 Plugin 'romgrk/barbar.nvim'
 "Glow (markdown preview)
 Plugin 'ellisonleao/glow.nvim'
 "Indent-blankline (adds indent markers)
 "NOTE: Nice plugin, but I only use single space indentation, so kind of
 " pointless
 "Plugin 'lukas-reineke/indent-blankline.nvim'
 "Render terminal colour escape sequences
 Plugin 'chrisbra/Colorizer'
call vundle#end()
filetype plugin indent on    " required


"Airline config
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_theme = 'dark'

"Configure coc.nvim
let g:coc_global_extensions = ['coc-json', 'coc-git', 'coc-clangd']
let g:coc_default_semantic_highlight_groups = 0
lua <<EOF
 require'lspconfig'.ccls.setup{
  init_options = {
   highlight = {
     lsRanges = true;
   },
   index = {
    multiVersion = 1
   }
  }
 }
EOF

"Configure nvim-treesitter
lua <<EOF
 require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  highlight = {
   enable = true,
   additional_vim_regex_highlighting = true
  },
  incremental_selection = {
   enable = true
  }
 }
EOF
"TODO: Play around with folding
"set foldmethod=expr
"set foldexpr=nvim_treesitter#foldexpr()

"Configure tokyonight colorscheme
"TODO Get code colorscheme configs working
let g:tokyonight_italic_functions = 1
let g:tokyonight_sidebars = ["terminal"]
let g:tokyonight_style = "night"
colorscheme tokyonight-night

"Set up nvim-telescope
lua <<EOF
 local actions = require'telescope.actions'
 require'telescope'.setup {
  defaults = {
   mappings = {
    i = {
     ['<ESC>'] = actions.close
    }
   },
   preview = {
    timeout = 1000
   }
  }
 }
EOF
nnoremap tf <cmd>Telescope find_files<cr>
nnoremap tg <cmd>Telescope live_grep<cr>
nnoremap tb <cmd>Telescope buffers<cr>

"Set up nvim-tree
"NOTE: Uncomment if plugin is ever added back
"lua <<EOF
" -- following options are the default
" -- each of these are documented in `:help nvim-tree.OPTION_NAME`
" require'nvim-tree'.setup {
"   disable_netrw       = true,
"   hijack_netrw        = true,
"   open_on_setup       = false,
"   ignore_ft_on_setup  = {},
"   auto_close          = false,
"   open_on_tab         = false,
"   hijack_cursor       = true,
"   update_cwd          = false,
"   update_to_buf_dir   = {
"     enable = true,
"     auto_open = true,
"   },
"   diagnostics = {
"     enable = false,
"     icons = {
"       hint = "",
"       info = "",
"       warning = "",
"       error = "",
"     }
"   },
"   update_focused_file = {
"     enable      = false,
"     update_cwd  = false,
"     ignore_list = {}
"   },
"   system_open = {
"     cmd  = nil,
"     args = {}
"   },
"   filters = {
"     dotfiles = false,
"     custom = {}
"   },
"   git = {
"     enable = true,
"     ignore = true,
"     timeout = 500,
"   },
"   view = {
"     width = 30,
"     height = 30,
"     hide_root_folder = false,
"     side = 'left',
"     auto_resize = true,
"     mappings = {
"       custom_only = false,
"       list = {}
"     },
"     number = false,
"     relativenumber = false
"   },
"   trash = {
"     cmd = "trash",
"     require_confirm = true
"   },
"   tree_follow = true
" }
"EOF
"let g:nvim_tree_indent_markers = 1
"let g:nvim_tree_window_picker_exclude = {
"    \   'filetype': [
"    \     'notify',
"    \     'packer',
"    \     'qf'
"    \   ],
"    \   'buftype': [
"    \     'terminal'
"    \   ]
"    \ }
"nnoremap <C-n> :NvimTreeToggle<CR>
"nnoremap <leader>r :NvimTreeRefresh<CR>
"nnoremap <leader>n :NvimTreeFindFile<CR>
" NvimTreeOpen, NvimTreeClose, NvimTreeFocus, NvimTreeFindFileToggle, and NvimTreeResize are also available if you need them

set termguicolors " this variable must be enabled for colors to be applied properly

"Configure barbar
nnoremap <C-Left> :BufferPrevious<cr>
nnoremap <C-Right> :BufferNext<cr>
nnoremap <C-s> :BufferPick<cr>
nnoremap <A-Left> :BufferMovePrevious<cr>
nnoremap <A-Right> :BufferMoveNext<cr>

"Add binding for Glow markdown preview
nnoremap <A-g> :Glow<cr>

"set bg=dark

"Enable 256 colours
set t_Co=256

"Misc Config
filetype plugin indent on
syntax on
set tabstop=1
set expandtab
set number
"set relativenumber
set mouse=a
set noshowmode
"set cursorline
set showmatch
set nostartofline
set wrap
set hidden
set path+=**
set fillchars+=vert:\│
set exrc
set secure
"set tagcase=snart
set wrap!

"Formatting
set tabstop=1
set shiftwidth=1
set expandtab
set smartindent

"Scrolling
set scrolloff=8
set sidescrolloff=15
set sidescroll=5

set colorcolumn=80

"TODO
"Navigate through display lines rather than physical lines (for long wrapped lines)
"nnoremap j gj
"nnoremap k gk
"vnoremap j gj
"vnoremap k gk
nnoremap <C-Down> gj
nnoremap <C-Up> gk
vnoremap <C-Down> gj
vnoremap <C-Up> gk
inoremap <C-Down> <C-o>gj
inoremap <C-Up> <C-o>gk

"Map CTRL+ALT+[LEFT/RIGHT] to [HOME/END] since Dell XPS 9700 does not have
"FN+[LEFT/RIGHT] mapped to [HOME/END]
inoremap <C-M-Left> <Home>
inoremap <C-M-Right> <End>
nmap <C-M-Left> <Home>
nmap <C-M-Right> <End>
vnoremap <C-M-Left> <Home>
vnoremap <C-M-Right> <End>
tnoremap <C-M-Left> <Home>
tnoremap <C-M-Right> <End>

"Delete word (to next whitespace or special character)
imap <C-d> <C-[>diwi

"Portable current file and buffer delete
nnoremap <C-Del> :call delete(expand('%')) \| bdelete!<CR>

"Redraw screen
"nnoremap <silent> <c-l> :nohl<CR><C-l>

"Command for trimming trailing whitespace from the current buffer
fun! TrimWhitespace()
 let l:save = winsaveview()
 keeppatterns %s/ \+$//e
 call winrestview(l:save)
endfun
command! Trw call TrimWhitespace()
command! TrimWhitespace call TrimWhitespace()

"Highlight redundant trailing spaces
"highlight RedundantSpaces ctermbg=red guibg=red
"match RedundantSpaces /\s\+$/
autocmd BufWinEnter <buffer> match Error /\s\+$/
autocmd InsertEnter <buffer> match Error /\s\+\%#\@<!$/
autocmd InsertLeave <buffer> match Error /\s\+$/
autocmd BufWinLeave <buffer> call clearmatches()

"Disable line numbers in terminal buffers
autocmd TermOpen * setlocal nonumber norelativenumber 
