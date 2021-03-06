com! ShowSpacing verb se ts? sts? sw? et? listchars?

fun! SetupTabstop(width, expand, ...)
	let &l:sts = a:width
	let &l:sw = a:width
	let &l:ts = a:0 ? a:1 : a:width
	let &l:et = a:expand ? 1 : 0
	let &l:listchars = 'tab:'.(a:expand ? '» ' : '  ').',trail:·'
endf

fun! HighlightSpacingErrors()
	if !exists('w:spacing_match_groups')
		let w:spacing_match_groups = []
	end

	" if not mixed tabs+spaces, hilight as errors
	if (! &l:sts) || (&l:sts == &l:ts)
		call add(w:spacing_match_groups, matchadd('Error', '^\t\+\ '))
		call add(w:spacing_match_groups, matchadd('Error', '^\ \+\t'))
	endif
	if &l:ft != 'mail'
		" trailing whitespace, except for the current cursor position
		call add(w:spacing_match_groups, matchadd('Error', '\S\zs[\t ]\+\%#\@!$'))
		" tabs anywhere but leading
		call add(w:spacing_match_groups, matchadd('Error', '\%(^\|\t\)\@<!\t'))
	end
	hi Error cterm=reverse
endfun

fun! ResetSpacingErrors(...)
	let todelete = []
	if exists('w:spacing_match_groups')
		call extend(todelete, w:spacing_match_groups)
	end
	if a:0 " 'force' mode
		call extend(todelete, map(filter(getmatches(), 'v:val.group == "Error"'), 'v:val.id'))
	end
	for group in todelete
		call matchdelete(group)
	endfor
	let w:spacing_match_groups = []
endf

fun! SetInModeline(var)
	redir => last_set
	exe "silent! verbose set ".a:var."?"
	redir END
	return -1 == match(last_set, 'from modeline') ? 0 : 1
endfun

fun! DetectSpacing()
	let expand_tabs = exists('g:spacing_expand_tabs') ? g:spacing_expand_tabs : 0
	let default_spacing = exists('g:spacing_default') ? g:spacing_default : 4
	let max_lines = exists('g:spacing_max_lines') ? g:spacing_max_lines : 1000
	let max_consider = exists('g:spacing_max_spaces') ? g:spacing_max_spaces : 5

	let ret = []
	if SetInModeline('ts')
		call add(ret, &l:ts)
		call add(ret, SetInModeline('et') ? &l:et : expand_tabs)
		if &l:ts != &l:sts && SetInModeline('sts')
			call add(ret, &l:sts)
		endif
		return ret
	endif

	let chars_scanned = 0
	let indented_lines = 0
	let tab_indented = 0
	let mixed_tabs = 0
	let line_indents = []
	for lnum in range(1,min([max_lines,line('$')]))
		let line = getline(lnum)
		let chars_scanned += len(line)

		" ignore lines whose first significant syntax item is a comment
		let is_comment = 0
		for col in range(1,strlen(line))
			let item = synIDattr(synIDtrans(synID(lnum, col, 0)), "name")
			if item =~? 'region' || item ==? 'none' || item == ''
				continue
			endif
			let is_comment = (item =~? 'comment')
			break
		endfor

		let ws = matchlist(line, '^\(\s*\)')
		if !is_comment
			if strlen(ws[1])
				let indented_lines += 1
				if len(matchlist(line, '^\t'))
					let tab_indented += 1
					if len(matchlist(line, '^\t\+ '))
						let mixed_tabs += 1
					end
				endif
			endif
			call add(line_indents, {'num':lnum,'indent':strlen(ws[1])})
		endif

		if chars_scanned > max_lines * 100
			break
		endif
	endfor

	if !len(line_indents) " can't tell
		return []
	end

	let diffs = {}
	let significant = 0
	for i in range(len(line_indents)-1)
		let a = line_indents[i]
		let b = line_indents[i+1]
		if a.num + 1 != b.num " skip disjoint sections
			continue
		endif
		let d = abs(a.indent - b.indent)
		if d > max_consider
			continue
		endif
		if d
			let significant += 1
			let diffs[d] = get(diffs, d) + 1
		endif
	endfor

	if !indented_lines || !len(keys(diffs)) " can't tell
		return []
	endif

	if mixed_tabs > 5 || mixed_tabs > indented_lines / 10 " some mixed
		return [ 4, 0, 8 ] " Emacs-style mixed tabs/spaces
	end

	if tab_indented > 20 || tab_indented > indented_lines / 3 " mostly tabs
		return [ default_spacing, 0 ]
	endif

	let mx = max(values(diffs))
	let mxi = max(map(copy(diffs), 'v:val == mx ? v:key : 0'))

	if mx < significant / 4 " can't tell
		return []
	endif

	return [ mxi, 1 ]
endfun

fun! SetupSpacingAutocmd()
	aug SetupSpacing
		au!
		au BufWinEnter * call SetupSpacing()
	aug END
endfun

fun! SetupSpacing(...)
	if exists('b:setup_spacing') && !a:0
		return
	endif
	let b:setup_spacing = 1
	if a:0 && a:1 < 2
		for [t, default] in items({ 'tabbed': [ 4, 0 ], 'spaced': [ 2, 1 ] })
			if !exists('g:setup_spacing_default_{t}')
				let g:setup_spacing_default_{t} = default
			endif
		endfor
		let type = (a:1 ? 'tabbed' : 'spaced')
		if exists('g:setup_spacing_default_{type}')
			call call('SetupTabstop', g:setup_spacing_default_{type})
			call HighlightSpacingErrors()
		endif
		return
	endif
	let scores = []
	let detected = DetectSpacing()
	if len(detected)
		call add(scores, { "score": 10, "params": detected })
	endif
	if exists('g:setup_spacing_filetypes')
		let by_ft = get(g:setup_spacing_filetypes, &ft, {})
		if len(by_ft)
			if type(by_ft) == type([])
				let params = by_ft
				let notabs = 0
			else
				let params = by_ft.params
				let notabs = get(by_ft, 'notabs', 0)
			end
			let score = 5
			if notabs && len(detected) && !detected[1]
				let score += 6
			end
			call add(scores, { "score": score, "params": params })
		endif
	endif
	if exists('g:setup_spacing_paths')
		for [pattern, params] in g:setup_spacing_paths
			if -1 != match(expand('<afile>:p'), expand(pattern))
				call add(scores, { "score": 7, "params": params })
			endif
		endfor
	endif
	if exists('g:setup_spacing_default')
		call add(scores, { "score": 1, "params": g:setup_spacing_default })
	endif
	let max_score = 0
	let params = []
	for i in scores
		if i.score <= max_score
			continue
		endif
		let max_score = i.score
		let params = i.params
	endfor
	if len(params)
		call call('SetupTabstop', params)
		call HighlightSpacingErrors()
	endif
endfun
