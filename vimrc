for dir in map([ '~/.vim', '~/.vim.local' ], 'expand(v:val)')
	if isdirectory(dir)
		if index(split(&rtp,','), dir) < 0
			let &rtp = join([ dir, &rtp, dir.'/after' ], ',')
		endif
	endif
endfor
set noexpandtab softtabstop=4 tabstop=4 shiftwidth=4
set list listchars=tab:\ \ ,trail:·
let g:mapleader = ','
let g:maplocalleader = g:mapleader
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
aug filetypedetect
	au! BufNewFile,BufRead *.md
	au BufNewFile,BufRead *.markdown,*.md,*.mkd setf markdown
	au BufNewFile,BufRead *.cron setf crontab
	au BufNewFile,BufRead *.watchr setf ruby
aug END
filetype plugin indent on
syntax enable
syntax sync maxlines=2000

" no maximum syntax column, but only if the first line isn't long
aug NoMaxSyntaxLength
	au!
	au BufReadPre * let &l:smc = 3000
	au BufRead * let &l:smc = len(getline(1)) < 3000 ? 0 : 3000
aug END

set foldmethod=marker
aug NoInsertFolding
	au!
	au InsertEnter * if !exists('w:oldfdm') | let w:oldfdm = &fdm | setl fdm=manual | endif
	au InsertLeave,WinLeave * if exists('w:oldfdm') | let &l:fdm = w:oldfdm | unlet w:oldfdm | endif
aug END
" ensure that unsaveable buffers are also uneditable
aug NoEditUnsaveable
	au!
	au BufWinEnter * let &modifiable = !&readonly
aug END

" Default foldtext to include byte length
fun! FoldTextWithOffsets()
	let txt = foldtext()
	let txt = substitute(txt, ':', printf(':%5d', line2byte(v:foldend+1)-line2byte(v:foldstart)).' bytes:','')
	return txt
endfun
se fdt=FoldTextWithOffsets()

" When editing stdin, set it initially to unmodified
aug StdinNotModified
	au!
	au VimEnter * if !bufname('') && (strlen(&fenc) || &bin) | se nomod | endif
aug END
" improve horizontal scrolling (opens folds, alt+{l,h} = faster)
fun! OpenFoldOrDo(action)
	return foldclosed('.') == -1 ? a:action : 'zv'
endfun
nnoremap <expr> l OpenFoldOrDo('l')
nnoremap <expr> h OpenFoldOrDo('h')
nnoremap <expr> <esc>l OpenFoldOrDo('30l')
nnoremap <expr> <esc>h OpenFoldOrDo('30h')

" map \z to a kind of 'reset the folds'
nnoremap <Leader>z zMzvz.

if &diff
	nnoremap > :.diffput <bar> diffupdate<cr>
	nnoremap < :.diffput <bar> diffupdate<cr>
else
	" keep visual mode selection when indenting
	vmap > >gv
	vmap < <gv
endif

" record macros into register 'q', playback with Q
nnoremap Q @q
" allow fully-collapsed windows
set winminheight=0
" allow backspace to erase before insertion point
set backspace=2

" treat '*' in visual mode similarly to normal mode
vmap * y/<C-R>=substitute(tolower(getreg('"')), '\([/$~^*\[\]\\]\)', '\\\1', 'g')<CR><CR>

" window mappings
map <esc>m <C-W>_
map <esc>- <C-W>-
map <esc>= <C-W>+

" pastetoggle
se pastetoggle=<F7>

" Let C-w f open a nonexistent file if it fails to find one
fun! OpenOrNewUnderCursor()
	try
		wincmd f
	catch
		new <cfile>
	endtry
endfun
nnoremap <C-w>f :call OpenOrNewUnderCursor()<CR>

" Ctrl+Arrow = window movement
map <C-Left> <C-W>h
map <C-Down> <C-W>j
map <C-Up> <C-W>k
map <C-Right> <C-W>l
" Ctrl+jk = window movement (C-h and C-l have other meanings)
map <C-j> <C-W>j
map <C-k> <C-W>k

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

" complete filenames after equals signs
set isf-==

" hlsearch
set hls
" turn off highlighting when refreshing the screen
nn <silent> <C-l> :nohls<CR><C-l>

" settings for TOhtml
let g:html_no_progress=1
let g:html_use_css=1
let g:html_number_lines=1
let g:html_ignore_folding=1
let g:html_dynamic_folds=0

if isdirectory(expand("~/.vim-tmp")) < 1
	if exists("*mkdir")
		call mkdir(expand("~/.vim-tmp"), "p", 0700)
	endif
endif
set backupdir=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
set directory=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
"^^ from http://items.sjbach.com/319/configuring-vim-right ***
if filereadable(expand("~/.vimrc.local"))
	source ~/.vimrc.local
endif
if exists("g:alpine")
	let alpinevim=globpath(&rtp,"alpine.vim")
	if filereadable(alpinevim)
		exe "source ".alpinevim
	endif
endif
