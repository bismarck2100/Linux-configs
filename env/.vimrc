"NeoBundle Scripts-----------------------------
if has('vim_starting')
  if &compatible
    set nocompatible               " Be iMproved
  endif

  " Required:
  set runtimepath+=/root/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('/root/.vim/bundle'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" Add or remove your Bundles here:
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'ctrlpvim/ctrlp.vim'
NeoBundle 'flazz/vim-colorschemes'
NeoBundle 'terryma/vim-multiple-cursors'
"NeoBundle 'mileszs/ack.vim'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'bronson/vim-trailing-whitespace'
NeoBundle 'majutsushi/tagbar'
NeoBundle 'easymotion/vim-easymotion'
NeoBundle 'bling/vim-airline'
	set laststatus=2

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
"End NeoBundle Scripts-------------------------

colorscheme molokai
"colorscheme hybrid


" ====================================================
" Useful shortcut
" ====================================================

let mapleader=","

nnoremap <leader>te :tabe<Space>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>n :NERDTree<CR>
nnoremap <leader>m :Gblame<CR>
nnoremap <leader>v :Gvdiff<CR><C-w><C-x>
nnoremap <leader>d :Gdiff<CR>
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>:echo $MYVIMRC "has been reloaded>^.^<"<CR>

" move around tabs. conflict with the original screen top/bottom
" " comment them out if you want the original H/L
" " go to prev tab
 map <S-H> gT
" " go to next tab
 map <S-L> gt
"

" " ,/ TURN OFF SEARCH HIGHLIGHTing
 nmap <leader>/ :nohl<CR>"
" "

" ====================================================
" General Setting
" ====================================================
set nocompatible    " not compatible with the old-fashion vi mode
set history=100		" keep 100 lines of command line history
set ruler			" show the cursor position all the time

syntax on			" syntax on/off/enable
filetype on			" Enable filetype detection
filetype plugin on	" Enable filetype-specific plugins
au InsertLeave * set nopaste " disbale paste mode when leaving insert mode
autocmd Syntax * normal zR

set clipboard=unnamed	" yank to the system register (*)"
set autoindent		" auto indentation"
set hlsearch		" search highlighting"
set incsearch       " incremental search"
set ignorecase      " ignore case when searching"
set smartcase       " ignore case if search pattern is all lowercase,case-sensitive otherwise, only work when ignorecase is set
set smartindent		" insert tabs on the start of a line according to context"

set nobackup		" no *~ backup files
set wildmenu
set showmode		" show mode. show filename size when open file
set bs=2			" allow backspacing over everything in insert mode
set wrapscan			" return to top of file when search hit buttom
set fileformat=unix		" fileformat: EOL(end of line: unix=\n dos=\r\n) format when write
set fileformats=unix		" fileformats: input file format is unix file
set viminfo='100,<1000,s100,h		" read/write a .viminfo file,

set showcmd			" display incomplete commands
set mouse=n			" Use mouse function in normal mode
set cursorline
set noexpandtab
set tabstop=4
set shiftwidth=4
set shiftround      " align with shiftwidth
set softtabstop=4
set number
set backspace=indent,eol,start
set matchpairs+=<:>
set t_Co=256
set foldmethod=syntax
set foldnestmax=1
set t_ut= " fix tmux backgroud issue

" ====================================================
" VimDiff setting
" ====================================================
hi DiffAdd                     ctermbg=17
hi DiffChange      ctermfg=181 ctermbg=239
hi DiffDelete      ctermfg=162 ctermbg=53
hi DiffText                    ctermbg=235 cterm=bold

" ====================================================
" Encoding setting
" ====================================================
set encoding=utf-8
set fileencoding=utf-8          " big5/utf8/taiwan(before 6.0)
set termencoding=utf-8		" utf8/big5
"let $LANG="zh_TW.UTF-8"	" locales => zh_TW.UTF-8
if ($LANG == "zh_TW.big5")
	set fileencoding=big5
	set termencoding=big5
elseif ($LANG == "zh_TW.utf-8")
	set fileencoding=utf8
	set termencoding=utf8
endif
set fileencodings=utf-8,big5,gb2312
set tabpagemax=200

set completeopt=menu


" ====================================================
" Plugin setting
" ====================================================

" --- CtrlP
if executable('ag')
	let g:ctrlp_user_command = 'ag %s -i -l --nocolor --nogroup --hidden -g ""'
endif

" --- Cscope
set cscopetag   " Ctrl+], Ctrl+t

" check cscope for definition of a symbol before checking ctags:
" set to 1 if you want the reverse search order.
set csto=1

" Add cscope.out if detect cscope.out nearest 5 parent folder
let $csPath="cscope.out"
for ind in range(0, 5)
	if filereadable($csPath)
		let g:CCTreeCscopeDb = $csPath
		cs add $csPath
		break
	endif
	let $csPath = "../" . $csPath
endfor

nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>


" --- TagBar
" toggle TagBar with F7
nnoremap <silent> <F7> :TagbarToggle<CR>
" set focus to TagBar when opening it
let g:tagbar_autofocus = 1


" --- EasyMotion
map <Leader>w <Plug>(easymotion-bd-w)
map <Leader>l <Plug>(easymotion-lineforward)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>h <Plug>(easymotion-linebackward)
map  / <Plug>(easymotion-sn)
omap  / <Plug>(easymotion-tn)
let g:EasyMotion_smartcase = 1


" --- Ack.vim
" Dont jump to first result automatically
" cnoreabbrev Ack Ack!
"
" nnoremap <Leader>a :Ack<Space>
" if executable('ag')
" 	let g:ackprg = 'ag --nocolor --nogroup --hidden --ignore tags --ignore cscope.out'
" endif

" ====================================================
" Function
" ====================================================

