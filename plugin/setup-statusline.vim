" %-5.(%{AwkFields#GetVar()}%)'

let s:tabstops='(%{repeat(&l:et?"·":"»",&l:sw)}%{&l:sts==&l:ts?"":repeat(&l:et?"¬":"·",&l:sts)}%{&l:sw==&l:ts?"":repeat(&l:et?"|":"¬",&l:ts)})'
let s:ff='%{&l:ff=="unix"?"":" [".&l:ff."]"}'
let s:ff.='%{&l:eol?"":" [noeol]"}'
let s:enc='strlen(&l:fenc)?&l:fenc:&l:enc'
let s:ff.='%{('.s:enc.')=="utf-8"?"":" [".('.s:enc.')."]"}'
let s:km='%{strlen(&l:kmp)?" [".&l:kmp."]":""}'
let s:typ='%{(expand("%:e")==&l:ft)?"":" <".&l:ft.">"}'
let s:extra='%{(exists("g:stl_extra")&&len(g:stl_extra))?":".join(map(copy(g:stl_extra),"v:val=~\"^!\"?eval(strpart(v:val,1)):v:val"),","):""}'
let s:cole = exists('&cole') ? '%{(!&l:cole)?"":"[cole:".&l:cole."]"}' : ''
let s:current = '%{bufnr("%") == actual_curbuf ? "" : "--"}'
let &stl=s:current.'%<%f'.s:typ.s:extra.' %h%m%r'.s:ff.s:km.'%='.s:cole.s:tabstops.(&ruler?' ':'').(&ruler ? '(%l,%c%V) %P' : '').'/%{line("$")}'

com! ResetStatusLine run plugin/setup-statusline.vim
