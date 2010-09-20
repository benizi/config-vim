set noexpandtab softtabstop=4 tabstop=4 shiftwidth=4
set list listchars=tab:\ \ ,trail:·
if $TERM =~ 'rxvt' || $TERM =~ 'xterm'
	set mouse=a
endif
if exists('$VIM_BACK')
	exec "set background=" . $VIM_BACK
else
	if &term == 'cygwin' || &term == 'linux'
		set background=dark
	else
		set background=light
	endif
endif
if &t_Co > 16
	colorscheme dual-converted
endif
set hidden
set laststatus=2 ruler
filetype plugin indent on
syntax enable
syntax sync maxlines=2000
set foldmethod=marker
" ensure that unsaveable buffers are also uneditable
aug NoEditUnsaveable
	au!
	au BufReadPost * let &modifiable = !&readonly
aug END
" make 'l' and 'h' open the fold on the current line
nnoremap <expr> l foldclosed(".")==-1 ? "l" : "zv"
nnoremap <expr> h foldclosed(".")==-1 ? "h" : "zv"
" keep visual mode selection when indenting
vmap > >gv
vmap < <gv
set ofu=syntaxcomplete#Complete
set nostartofline
imap <C-@> <C-Space>
" autocmd FileType * set tabstop=4|set shiftwidth=4|set softtabstop=4|set expandtab
autocmd BufRead *.thtml set syntax=thtml
" map  {gq}
let g:tex_flavor = "context"
"vv from http://items.sjbach.com/319/configuring-vim-right ***
set history=1000
set wildmenu
" set wildmode=list:longest
set modeline
set ignorecase
set smartcase

" hlsearch
set hls
map <esc>h :noh<cr>

if isdirectory(expand("~/.vim-tmp")) < 1
	if exists("*mkdir")
		call mkdir(expand("~/.vim-tmp"), "p", 0700)
	endif
endif
set backupdir=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
set directory=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
"^^ from http://items.sjbach.com/319/configuring-vim-right ***
set runtimepath=~/.vim.local,~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after,~/.vim.local/after
if filereadable(expand("~/.vimrc.local"))
	source ~/.vimrc.local
endif
if exists("g:alpine")
	let alpinevim=globpath(&rtp,"alpine.vim")
	if filereadable(alpinevim)
		exe "source ".alpinevim
	endif
endif
