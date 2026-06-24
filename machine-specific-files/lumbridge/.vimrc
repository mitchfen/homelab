set nocompatible
set encoding=utf-8

""" Split to the right by default
set splitright

" Tabs and things
set autoindent
set tabstop=2
set shiftwidth=2
set softtabstop=-1

""" Auto complete and menu
set wildmenu
set wildmode=longest,list,full
set number relativenumber

""" Syntax and searchinng
syntax on
set hlsearch
set showmatch
set ignorecase
set incsearch

""" Status bar and ruler
set laststatus=1
set ruler
set rulerformat=%55(%{strftime('%a\ %b\ %e\ %I:%M\ %p')}\ %5l,%-6(%c%V%)\ %P%)

""" Avoid annoying macro Q key
nnoremap Q q
nnoremap q <Nop>

""" Map F6 to spell check
map <F6> :setlocal spell! spelllang=en_us<CR>
