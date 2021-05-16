" .vimrc@rescenic - heavily inspired by: @millermedeiros
" Last Update: May 16 2021

" Vundle begins here; turn off filetype temporarily
" Set the runtime path to include Vundle and initialize
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Plugins
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-markdown'
Plugin 'tpope/vim-dadbod'
Plugin 'tpope/vim-bundler'
Plugin 'tpope/vim-rake'
Plugin 'tpope/gem-browse'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-dispatch'
Plugin 'tpope/vim-tbone'
Plugin 'tpope/vim-abolish'
Plugin 'tpope/vim-characterize'
Plugin 'vim-scripts/dbext.vim'
Plugin 'preservim/nerdcommenter'
Plugin 'preservim/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'ryanoasis/vim-devicons'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
Plugin 'scrooloose/nerdtree-project-plugin'
Plugin 'PhilRunninger/nerdtree-visual-selection'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'janko-m/vim-test'
Plugin 'bronson/vim-trailing-whitespace'
Plugin 'pangloss/vim-javascript'
Plugin 'othree/javascript-libraries-syntax.vim'
Plugin 'leafgarland/typescript-vim'
Plugin 'elixir-editors/vim-elixir'

" Themes
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'edkolev/tmuxline.vim'
Plugin 'flazz/vim-colorschemes'
Plugin 'morhetz/gruvbox'

call vundle#end()

syntax on
filetype plugin indent on   " Enable detection, plugins and indent.

set spelllang=en_us         " Spell-checking.
set encoding=utf-8 nobomb   " BOM often causes trouble.

" Performance & buffer settings
set hidden                  " Can put buffer to the background without writing
                            "   to disk, will remember history/marks.
set lazyredraw              " Don't update the display while executing macros.
set ttyfast                 " Send more characters at a given time.

" History & file handling settings
set history=999           " Increase history (default = 20).
set undolevels=999          " More undo (default=100).
set autoread                " Reload files if changed externally.

" Backup settings
set nobackup
set nowritebackup
set noswapfile

" Search & regexp settings
set gdefault                " RegExp global by default.
set magic                   " Enable extended regexes.
set hlsearch                " Highlight searches.
set incsearch               " Show the `best match so far' as typed.
set ignorecase smartcase    " Make searches case-insensitive, unless they
                            "   contain upper-case letters.

" Keys settings
set backspace=indent,eol,start  " Allow backspacing over everything.
set esckeys                     " Allow cursor keys in insert mode.
set nostartofline               " Make j/k respect the columns
" set virtualedit=all           " Allow the cursor to go in to 'invalid' places.
set timeoutlen=1000             " How long it wait for mapped commands.
set ttimeoutlen=100             " Faster timeout for escape key and others.

" Use a bar-shaped cursor for insert mode, even through tmux.
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" ----------------------------------------------------------------------------
" UI
" ----------------------------------------------------------------------------
set t_Co=256                " 256 colors terminal.
colorscheme gruvbox
set background=dark

" vim-airline
let g:airline_theme='gruvbox'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 1
let g:airline_highlighting_cache = 1

" vim-tmuxline
let g:tmuxline_preset = 'full'

" gVim - maximized window - default columns=94 lines=54
if has("gui_running")
	set guifont=Hack_NF:h8:b
	set columns=999
	set lines=999
	set mouse=a
	
	" toolbar and scrollbars
    set guioptions-=T       " Remove toolbar.
    set guioptions+=L       " Add left scroll bar.
    set guioptions+=r       " Add right scroll bar.
    "set guioptions+=b      " Add bottom scroll bar.
    "set guioptions-=h      " Only calculate bottom scroll size of current line
    set shortmess=atI       " Don't show the intro message at start and
                            "   truncate msgs (avoid press ENTER msgs).
endif

set cursorline              " Highlight current line.
set laststatus=2            " Always show status line.
set number relativenumber   " Enable relative line numbers.
set nu rnu					" Enable hybrid line numbers.
set numberwidth=4           " Width of numbers line (default on gvim is 4).
set report=0                " Show all changes.
set showmode                " Show the current mode.
set showcmd                 " Show partial command on last line of screen.
set showmatch               " Show matching parenthesis.
set splitbelow splitright   " How to split new windows.
set title                   " Show the filename in the window title bar.

set scrolloff=5             " Start scrolling n lines before horizontal
                            "   border of window.
set sidescrolloff=7         " Start scrolling n chars before end of screen.
set sidescroll=1            " The minimal number of columns to scroll
                            "   horizontally.

" Add useful stuff to title bar (file name, flags, cwd)
if has('title') && (has('gui_running') || &title)
    set titlestring=
    set titlestring+=%f
    set titlestring+=%h%m%r%w
    set titlestring+=\ -\ %{v:progname}
    set titlestring+=\ -\ %{substitute(getcwd(),\ $HOME,\ '~',\ '')}
endif

" --- command completion ---
set wildmenu                " Hitting TAB in command mode will
set wildchar=<TAB>          "   show possible completions.
set wildmode=list:longest
set wildignore+=*.DS_STORE,*.db

" --- diff ---
set diffopt=filler          " Add vertical spaces to keep right
                            "   and left aligned.
set diffopt+=iwhite         " Ignore whitespace changes.

" --- folding---
set foldmethod=indent       "fold based on indent
set foldnestmax=3           "deepest fold is 3 levels
set nofoldenable            "don't fold by default

" --- list chars ---
" list spaces and tabs to avoid trailing spaces and mixed indentation
" see key mapping at the end of file to toggle `list`
set fillchars=fold:-
set list

" --- remove sounds effects ---
set noerrorbells
set visualbell

" -----------------------------------------------------------------------------
" KEYS
" -----------------------------------------------------------------------------
set backspace=indent,eol,start  " allow backspacing over everything.
set esckeys                     " Allow cursor keys in insert mode.
set nostartofline               " Make j/k respect the columns.
"set virtualedit=all            " Allow the cursor to go in to 'invalid' places.

" -----------------------------------------------------------------------------
" INDENTATION AND TEXT-WRAP
" -----------------------------------------------------------------------------
set expandtab                   " Expand tabs to spaces.
set autoindent smartindent      " Auto/smart indent.
set copyindent                  " Copy previous indentation on auto indent.
set softtabstop=4               " Tab key results in # spaces.
set tabstop=4                   " Tab is 4 spaces.
set shiftwidth=4                " The # of spaces for indenting.
set smarttab                    " At start of line, <Tab> inserts shift width
                                "   spaces, <Bs> deletes shift width spaces.
"set wrap                       " Wrap lines.
"set textwidth=79
"set colorcolumn=+1             " Show large lines
set formatoptions=qrn1          " Automatic formating.
set formatoptions-=o            " Don't start new lines w/ comment leader on
                                "   pressing 'o'
set nomodeline                  " Don't use modeline (security).
set pastetoggle=<leader>p       " Paste mode: avoid auto indent, treat chars
                                "   as literal.

" -----------------------------------------------------------------------------
" PLUGINS
" -----------------------------------------------------------------------------
" --- ctrlp ---
let g:ctrlp_map = '<c-p>'

" --- NERDTree ----
let NERDTreeIgnore=['.DS_Store']
let NERDTreeShowBookmarks=0         " Show bookmarks on startup.
let NERDTreeHighlightCursorline=1   " Highlight the selected entry in the tree.
let NERDTreeShowLineNumbers=0
let NERDTreeMinimalUI=1

" --- NERDCommenter ---
let NERDSpaceDelims=1               " Space around delimiters.
let NERDRemoveExtraSpaces=1
let g:NERDCustomDelimiters = {
    \ 'scss': { 'left': '//' }
\ }

" --- vim-devicons ---
" loading the plugin
let g:webdevicons_enable = 1
" adding the flags to NERDTree
let g:webdevicons_enable_nerdtree = 1
" adding the custom source to unite
let g:webdevicons_enable_unite = 1
" adding the column to vimfiler
let g:webdevicons_enable_vimfiler = 1
" adding to vim-airline's tabline
let g:webdevicons_enable_airline_tabline = 1
" adding to vim-airline's statusline
let g:webdevicons_enable_airline_statusline = 1
" ctrlp glyphs
let g:webdevicons_enable_ctrlp = 1
" adding to vim-startify screen
let g:webdevicons_enable_startify = 1
" adding to flagship's statusline
let g:webdevicons_enable_flagship_statusline = 1
" turn on/off file node glyph decorations (not particularly useful)
let g:WebDevIconsUnicodeDecorateFileNodes = 1
" use double-width(1) or single-width(0) glyphs
" only manipulates padding, has no effect on terminal or set(guifont) font
let g:WebDevIconsUnicodeGlyphDoubleWidth = 1
" whether or not to show the nerdtree brackets around flags
let g:webdevicons_conceal_nerdtree_brackets = 1
" the amount of space to use after the glyph character (default ' ')
let g:WebDevIconsNerdTreeAfterGlyphPadding = '  '
" Force extra padding in NERDTree so that the filetype icons line up vertically
let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
" Adding the custom source to denite
let g:webdevicons_enable_denite = 1
" The amount of space to use after the glyph character in vim-airline tabline(default '')
let g:WebDevIconsTabAirLineAfterGlyphPadding = ' '
" The amount of space to use before the glyph character in vim-airline tabline(default ' ')
let g:WebDevIconsTabAirLineBeforeGlyphPadding = ' '

" -----------------------------------------------------------------------------
" KEYS MAPPING
" -----------------------------------------------------------------------------
" vim-nerdtree
map <C-n> :NERDTreeToggle<CR>

" remap keys
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" vim-test
nmap <silent> <leader>t : TestNearest<CR>
nmap <silent> <leader>T : TestFile<CR>
nmap <silent> <leader>a : TestSuite<CR>
nmap <silent> <leader>l : TestLast<CR>
nmap <silent> <leader>v : TestVisit<CR>

" vim-buffer
map gn :bn<cr>
map gp :bp<cr>
map gd :bd<cr>

" Highlight long lines
augroup vimrc_autocmds
  autocmd BufEnter * highlight OverLength ctermbg=darkgrey guibg=#111111
  autocmd BufEnter * match OverLength /\%>74v.\+/
augroup END

" Maximized window
autocmd GUIEnter * simalt ~x

" NERDTree at startup 
autocmd VimEnter * NERDTree | wincmd p

" Remove all trailing whitespace by pressing F4
noremap <F4> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
