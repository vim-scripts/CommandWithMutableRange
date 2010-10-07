" CommandWithMutableRange.vim: Execute commands which may add or remove lines
" for each line in the range. 
"
" DEPENDENCIES:
"   - ingomarks.vim autoload script. 
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.00.001	29-Sep-2010	Moved functions from plugin to separate autoload
"				script.
"				file creation

function! s:SetMarks( reservedMarks, currentLine, endLine )
    let l:marks = [ [a:currentLine, a:reservedMarks[0]], [a:currentLine + 1, a:reservedMarks[1]], [a:endLine, a:reservedMarks[2]] ]
    for [l:lineNumber, l:mark] in l:marks
	if setpos("'" . l:mark, [0, l:lineNumber, 1, 0]) != 0
	    throw 'CommandWithMutableRange: Panic: Couldn''t set mark!'
	endif
    endfor
    return l:marks
endfunction

function! s:IsValid( markLineNum )
    return (a:markLineNum > 0)
endfunction
function! s:EvaluateMarks( marks )
    call map(a:marks, '[v:val[0], getpos("''". v:val[1])[1]]')
"****D echomsg string(a:marks)
    let [l:currentLineBefore, l:currentLineAfter] = a:marks[0]
    let [l:nextLineBefore, l:nextLineAfter] = a:marks[1]
    let [l:endLineBefore, l:endLineAfter] = a:marks[2]
    if s:IsValid(l:currentLineAfter)
	let l:currentLineDelta = l:currentLineAfter - l:currentLineBefore
    endif
    if s:IsValid(l:nextLineAfter)
	let l:nextLineDelta = l:nextLineAfter - l:nextLineBefore
    endif
    if s:IsValid(l:endLineAfter)
	let l:endLineDelta = l:endLineAfter - l:endLineBefore
    endif

    " We're done when we knew beforehand that this is the last line to process. 
    if l:nextLineBefore > l:endLineBefore
	return [l:nextLineBefore, l:endLineBefore, '0)']
    endif

    if s:IsValid(l:nextLineAfter)
	if (s:IsValid(l:currentLineAfter) && l:nextLineAfter > l:currentLineAfter)
	    " a) Simplest case: The marks on the current and next lines have been
	    " left intact, and the next line is still behind the current line. 
	    if ! s:IsValid(l:endLineAfter) || l:endLineAfter <= l:nextLineAfter
		" Somehow, the end mark got (re-)moved. Reconstruct. 
		let l:endLineAfter = l:endLineBefore + l:nextLineDelta
	    endif
	    return [l:nextLineAfter, l:endLineAfter, 'a)']
	elseif ! s:IsValid(l:currentLineAfter) && s:IsValid(l:endLineAfter)
	    " The mark on the current line has been removed, but the mark on the
	    " next line does still exist. 
	    let l:todoDistanceBefore = l:endLineBefore - l:nextLineBefore + 1
	    let l:todoDistanceAfter = l:endLineAfter - l:nextLineAfter + 1
	    let l:todoDistanceDelta = l:todoDistanceAfter - l:todoDistanceBefore
	    if l:todoDistanceDelta == 0
		" If the distance between next and end line was maintained, we
		" continue with the next line, if there is still something to
		" process. 
		if l:todoDistanceAfter > 0
		    return [l:nextLineAfter, l:endLineAfter, 'b)' ]
		else
		    " We're already on or beyond the end line, signal end of
		    " processing. 
		    return [l:endLineAfter + 1, l:endLineAfter, 'b0)' ]
		endif
	    elseif l:todoDistanceDelta < 0
		" If the distance decreased, the next line has already been
		" consumed and we continue with the following line. 
		return [l:nextLineAfter + 1, l:endLineAfter, 'c)' ]
	    else
		throw 'CommandWithMutableRange: Cannot continue with iteration; deletions and additions occurred around the next line.'
	    endif
	elseif s:IsValid(l:endLineAfter)
	    " d) The mark on the next line moved onto or even before the mark on
	    " the current line. Just continue with the next line. 
	    return [l:currentLineAfter + 1, l:endLineAfter, 'd)']
	else
	    throw 'CommandWithMutableRange: Cannot continue with iteration; end marker got removed.'
	endif
    else
	if s:IsValid(l:currentLineAfter)
	    " e) The mark on the next line has been removed, but we can simply
	    " go to the next line based on the intact current line marker. 
	    if s:IsValid(l:endLineAfter)
		return [ l:currentLineAfter + 1, l:endLineAfter, 'e)' ]
	    else
		" The mark of the end line also got removed. There are no more
		" lines to process; we're done. 
		return [ l:currentLineAfter + 1, l:currentLineAfter, 'e0)' ]
	    endif
	elseif s:IsValid(l:endLineAfter)
	    " f) The marks on the current and next line(s) have been removed. If
	    " the end line moved up at least two lines, continue processing on
	    " the same line as before. 
	    if l:endLineDelta <= -2
		return [ l:currentLineBefore, l:endLineAfter, 'f)' ]
	    else
		throw 'CommandWithMutableRange: Cannot continue with iteration; deletions and additions occurred around the current and next line.'
	    endif
	else
	    " g) All three marks have been removed; we stop processing. 
	    return [ l:currentLineBefore + 1, l:currentLineBefore, 'g)' ]
	endif
    endif

    throw 'CommandWithMutableRange: Unhandled scenario.'
endfunction
function! CommandWithMutableRange#CommandWithMutableRange( commandType, startLine, endLine, commandString )
"****D echomsg '****' a:startLine . ' ' . a:endLine 
    " Disable folding during the iteration over the lines. The '0' normal mode
    " command would open a closed fold, anyway. (Unfortunately, there's no ex
    " command to jump to a first column of a line (that leaves folding intact).)
    let l:save_foldenable = &foldenable
    let l:reservedMarksRecord = {}
    try
	setlocal nofoldenable
	let l:reservedMarksRecord = ingomarks#ReserveMarks(3, g:CommandWithMutableRange_marks)

	let l:line = a:startLine
	let l:endLine = a:endLine
	while l:line <= l:endLine
	    let l:marks = s:SetMarks(keys(l:reservedMarksRecord), l:line, l:endLine)

	    execute l:line
	    normal! 0
	    try
"****D echomsg '****' l:line . ' ' . getline(l:line)
		execute a:commandType . ' ' . a:commandString
	    catch /^Vim\%((\a\+)\)\=:E/
		echohl ErrorMsg
		" v:exception contains what is normally in v:errmsg, but with extra
		" exception source info prepended, which we cut away. 
		let v:errmsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
		echomsg v:errmsg
		echohl None
	    endtry
	    let [l:line, l:endLine, l:debug] = s:EvaluateMarks(l:marks)
"****D echomsg '****' l:debug . ' => ' . l:line . ' ' . l:endLine
	endwhile
    catch /^ingomarks:/
	echohl ErrorMsg
	let v:errmsg = substitute(v:exception, '^ingomarks:\s*', '', '')
	echomsg v:errmsg
	echohl None
    catch /^CommandWithMutableRange:/
	echohl ErrorMsg
	let v:errmsg = substitute(v:exception, '^CommandWithMutableRange:\s*', '', '')
	echomsg v:errmsg
	echohl None
    finally
	call ingomarks#UnreserveMarks(l:reservedMarksRecord)
	let &foldenable = l:save_foldenable
    endtry
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
