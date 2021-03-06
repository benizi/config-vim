" different locations if running as root
let owner_home = '~'
let s:script = shellescape(expand('~/.vimrc'))
if executable('stat') && system('stat -c %F '.s:script) =~ 'link'
	let owner_home .= split(system('stat -L -c %U '.s:script))[0]
endif
let s:home = owner_home
let s:home_vim = s:home.'/.vim'

" Get directory under the set of 'bundled' files
fun! s:BundleDir(...)
	return join(extend([s:home_vim.'/bundle'],a:000),'/')
endfun

" Add various directories to &rtp, with their '/after' dirs
let s:dirs = [ s:home_vim, s:home_vim.'.local' ]
\ + [ s:home_vim.'/vundle' ]
\ + map(['vim-addon-manager','vim-pathogen'],'s:BundleDir(v:val)')
for dir in map(s:dirs, 'expand(v:val)')
	if isdirectory(dir)
		if index(split(&rtp,','), dir) < 0
			let &rtp = join([ dir, &rtp, dir.'/after' ], ',')
		endif
	endif
endfor

" Set leader chars before activating addons
let g:mapleader = ','
let g:maplocalleader = g:mapleader

fun! InGUI()
	return has('gui') && has('gui_running')
endf

" keep some plugins around w/o loading by default...
let g:pathogen_disabled = []
call add(g:pathogen_disabled, 'CSApprox')

let s:limited_terminal = $TERM =~ 'linux'

" st and konsole support 24-bit color
if $TERM =~ 'st-256color' || exists('$KONSOLE_DBUS_SERVICE')
	se t_Co=1000
end

if $TERM =~ '^st'
	" fix cursor shape in st
	let &t_SI="\e[6 q"
	let &t_EI="\e[2 q"
end

" fix BCE bug in `st` and in rxvt-unicode-24bit
if $TERM =~ '^st' || $TERM =~ 'rxvt.*24bit'
	se t_ut=
end

" fix cursor shape in Konsole
if exists('$KONSOLE_DBUS_SERVICE')
	let &t_SI="\<Esc>]50;CursorShape=1\x7"
	let &t_EI="\<Esc>]50;CursorShape=0\x7"
end

try
	call vam#ActivateAddons() " set up VAM functions
	call pathogen#infect(s:BundleDir() . '/{}') " activate everything
catch
	echomsg 'Caught exception:'
	echomsg v:exception
	echomsg 'Perhaps pathogen or vim-addon-manager is not installed?'
endtry

try
	call vundle#rc(s:BundleDir()) " set up Vundle
	exe 'so' s:home_vim.'/bundles.vim'
catch
	echom 'Caught exception trying to activate Vundle:'
	echom v:exception
endtry

let s:ng = expand(s:home.'/hg/vimclojure/client/ng')
if executable(s:ng)
	let vimclojure#WantNailgun = 1
	let vimclojure#NailgunClient = s:ng
endif

let g:Powerline_symbols = s:limited_terminal ? 'compatible' : 'unicode'
let g:Powerline_cache_enabled = 0

" default 2-space tabstops, no actual tab chars
se noet sts=2 ts=2 sw=2
set list listchars=tab:\ \ ,trail:·
se nowrap cc=80
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

fun! PostColorScheme()
	let colo = get(g:, 'colors_name', '')
	if colo == 'dual-converted'
		hi StatusLineNC ctermfg=252 ctermbg=24
	elseif colo == 'jellybeans'
		if &t_Co <= 256
			" set cursor color
			sil! !printf '\e]12;8\a'
		end
		hi Search cterm=NONE ctermfg=0 ctermbg=220 guifg=#000000 guibg=#ffff00
		hi Normal guibg=black
		hi NonText guibg=black
		hi ColorColumn guibg=#993333
		hi rubyRegexpDelimiter guifg=#ff9900
		hi! link rubyRegexp Constant
		hi! link rubyRegexpSpecial String
	elseif colo == 'railscasts'
		hi TabLine guibg=#0000cc gui=none,reverse guifg=#ffffff
		hi TabLineSel guibg=#0000cc gui=none guifg=#ffffff
		hi TabLineFill guibg=#0000cc gui=none,reverse guifg=#ffffff
		hi Search gui=reverse guifg=#ff9900 guibg=#000000
	end
endf
aug PostColorScheme
	au! ColorScheme * call PostColorScheme()
aug END
if &t_Co > 16
	let s:colors = 'jellybeans'
end
if exists('s:colors')
	exe 'colo' s:colors
end

se nu
set hidden
set laststatus=2 ruler
aug filetypedetect
	au! BufNewFile,BufRead *.markdown,*.md,*.mkd setf markdown
	au! BufNewFile,BufRead *.cron setf crontab
	au! BufNewFile,BufRead *.watchr,Gemfile*,Capfile,Vagrantfile,*.jbuilder,*.rabl setf ruby
	au! BufNewFile,BufRead *.hsc,*xmobarrc setf haskell
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
	au BufWinEnter * if !exists('b:swapname') | let &modifiable = !&readonly | endif
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

" map z= to 'set fold level equal to the fold I'm on'
fun! SetFoldEqual()
	let start = line('.')
	let foldstart = foldclosed('.')
	let fdl = foldlevel(foldstart > 0 ? foldstart : '.')
	let lnum = 1
	while 1
		if foldclosed(lnum) < 0 && foldlevel(lnum) >= fdl
			exe lnum
			norm zc
			let lnum = foldclosedend(lnum)
		end
		if lnum >= line('$')
			break
		end
		let lnum += 1
	endw
	exe start
endf
nn <silent> z= :call SetFoldEqual()<CR>

if &diff
	nnoremap > :.diffput <bar> diffupdate<cr>
	nnoremap < :.diffput <bar> diffupdate<cr>
	au VimEnter * nn ZZ :wa<bar>qa<CR>
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

" getting used to Emacs...
map <C-g> <Esc>
im <C-g> <Esc>

" alt+backspace on commandline removes one dir
cmap <esc><bs> <C-w><C-w>

" pastetoggle
se pastetoggle=<F7>

" Try adding extensions to the detected filename under the cursor
fun! OpenGlobUnderCursor()
	let paths = split(globpath(&path, expand('<cfile>').'.*'), '\n')
	if len(paths) && filereadable(paths[0])
		exe ':new '.fnameescape(paths[0])
		return 1
	end
	return 0
endf

" Let C-w f open a nonexistent file if it fails to find one
fun! OpenOrNewUnderCursor()
	" If we're going to get a directory, try with extensions
	let paths = split(globpath(&path, expand('<cfile>')), '\n')
	if len(paths) && isdirectory(paths[0]) && OpenGlobUnderCursor()
		return
	end
	try
		wincmd f
	catch
		" If we failed, try files with extensions
		if OpenGlobUnderCursor()
			return
		end
		tabnew <cfile>
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

" ZZ = ZZ for all windows, prompt if more than four windows
fun! QuitAll()
	if winnr('$') > 4
		let ans = confirm('Really quit?', "&Yes\n&One\n&No")
		if ans == 2
			x
			return
		elseif ans == 3
			echom 'Cancelled'
			return
		end
	end
	windo x
endf
nn ZZ :call QuitAll()<CR>

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

" make increment work when numbers have leading 0's
se nf=hex

" hlsearch
set hls
" turn off highlighting when refreshing the screen
nn <silent> <C-l> :nohls<CR><C-l>
" incremental search
se is

" mappings for tab navigation
nn <silent> <Esc>t :tabnew<CR>
nn <silent> <Esc>{ gT
nn <silent> <Esc>} gt
fun! CloseAndQuitIfLast()
	let closing = bufnr('')
	let tabpos = tabpagenr() - 1
	winc q
	let allbufs = []
	for t in range(tabpagenr('$'))
		cal extend(allbufs, tabpagebuflist(t + 1))
	endfor
	if -1 == index(allbufs, closing)
		try
			exe closing.'bd'
		catch
			exe tabpos.'tabnew|sil! '.closing.'b'
			unsil echom v:exception
		endtry
	end
endf
nn <silent> <Esc>w :sil call CloseAndQuitIfLast()<CR>

" settings for TOhtml
let g:html_no_progress=1
let g:html_use_css=1
let g:html_number_lines=1
let g:html_ignore_folding=1
let g:html_dynamic_folds=0

" sample python indent munger - au BufWritePre *.py %s/^\( \{8}\)\+/\=substitute(submatch(0), repeat(' ', 8), repeat(' ', 4), 'g')/e
" sample python indent munger - au BufWritePost *.py u

if isdirectory(expand("~/.vim-tmp")) < 1
	if exists("*mkdir")
		call mkdir(expand("~/.vim-tmp"), "p", 0700)
	endif
endif
set backupdir=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
set directory=~/.vim-tmp//,~/.tmp//,~/tmp//,/tmp//
"^^ from http://items.sjbach.com/319/configuring-vim-right ***
if filereadable(expand(s:home.'/.vimrc.local'))
	exe 'source '.s:home.'/.vimrc.local'
endif

let g:no_time_tracking = 1

"" Ctrl-P settings
" default to horizontal open
let g:ctrlp_prompt_mappings = {
	\ 'AcceptSelection("e")': ['<cr>'],
	\ 'AcceptSelection("h")': ['<c-x>'],
	\ }
" no path management ( == use cwd)
let g:ctrlp_working_path_mode = 0
let g:ctrlp_custom_ignore = {
	\ 'dir': '\.git$\|\.hg$\|\.svn$\|tmp$\|uploads$',
	\ 'file': '\.o$',
	\ }
let g:ctrlp_max_height = 100
let g:ctrlp_show_hidden = 1
let g:ctrlp_mruf_max = 1000000
let g:ctrlp_switch_buffer = 'et'

nm <Leader>n :CtrlPCurFile<CR>
nm <expr> <Leader>e ':e '.expand('%:h').'/'
nm <expr> <Leader>t ':tabnew '.expand('%:h').'/'
nm <expr> <Leader>v ':vne '.expand('%:h').'/'

" cycle through different ways of opening a buffer on the cmdline
fun! SwapOpenType(cmdline)
	let opens = ['e', 'tabnew', 'vne', 'new']
	let [cmd, rest] = matchlist(a:cmdline, '^\(\S\+\)\(\%(\s\+.\{-\}\)\?\)$')[1:2]
	let i = index(opens, cmd)
	if i < 0
		return a:cmdline
	end
	let newcmd = opens[(1 + i) % len(opens)]
	return newcmd . rest
endf
cno <C-t> <C-\>eSwapOpenType(getcmdline())<CR>

let g:NERDDefaultAlign = 'left'
let g:NERDCustomDelimiters = {
\   'sql': { 'left': '/*', 'right': '*/', 'leftAlt': '-- ' },
\   'puppet': { 'left': '#' },
\ }

let g:rtn_open_with = 'vnew'

let g:txt_256color_settings = 1
if InGUI()
	fun! SetupGUI()
		let &gfn = 'DejaVu Sans Mono 14'
		se go-=m go-=T
	endf
	au GUIEnter * call SetupGUI()
else
	" use degraded 256-color palette for Solarized
	let g:solarized_termcolors = 256
end

" Clean up interline spacing
let s:blank_line = '^\s*$'

fun! CleanBlankLinesOrBackspace(...)
	let insert = a:0 ? a:1 : 0

	let start = line('.')
	let col = col('.')

	let stop = start
	let total = line('$')

	" If we're not on a blank line, normal backspace
	if col != 1 || getline(start) !~ s:blank_line
		return "\<BS>"
	end

	" Find the first line of the run of blanks
	while start > 1 && getline(start - 1) =~ s:blank_line
		let start -= 1
	endwhile

	" Find the last line of the run of blanks
	while stop < total && getline(stop + 1) =~ s:blank_line
		let stop += 1
	endwhile

	" We're at an 'end' of the file if we're on the first or last line
	let at_end = (start == 1 || stop == total)

	" Nothing to do if:
	" 1. there's only one blank line and it's not the end of the file
	"    We're compacting lines to 1, or removing them at the end
	" or 2. we're at the end of the file and we're in insert mode
	"       It's disconcerting to clean up lines in insert mode
	if (start == stop && !at_end) || (at_end && insert)
		return "\<BS>"
	end

	" Construct the set of commands to clean up the lines
	let exit_insert_mode = insert ? "\<C-[>" : ""
	let delete_blank_lines = ":".start.",".stop."d"
	let add_blank_line = at_end ? "" : "|i\<CR>\<CR>."
	return exit_insert_mode.delete_blank_lines.add_blank_line."\<CR>"
endf
nn <silent> <expr> <BS> CleanBlankLinesOrBackspace()
