" CommandWithMutableRange.vim: Execute commands which may add or remove lines
" for each line in the range. 
"
" DEPENDENCIES:
"   - Vim 7.0 or higher. 
"   - CommandWithMutableRange.vim autoload script. 
"
" Copyright: (C) 2009-2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.00.003	04-Oct-2010	Split off documentation into separate help file. 
"	002	29-Sep-2010	Split off reserving of marks to ingomarks.vim
"				autoload plugin to allow reuse. 
"				Moved functions from plugin to separate autoload
"				script.
"	001	10-Jan-2009	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_CommandWithMutableRange') || (v:version < 700)
    finish
endif
let g:loaded_CommandWithMutableRange = 1

"- configuration --------------------------------------------------------------
if ! exists('g:CommandWithMutableRange_marks')
    let g:CommandWithMutableRange_marks = ''
endif

"- commands -------------------------------------------------------------------
command! -range -nargs=1 ExecuteWithMutableRange	call CommandWithMutableRange#CommandWithMutableRange('', <line1>, <line2>, <q-args>)
command! -range -nargs=1 CallWithMutableRange		call CommandWithMutableRange#CommandWithMutableRange('call', <line1>, <line2>, <q-args>)
command! -range -nargs=1 -bang NormalWithMutableRange	call CommandWithMutableRange#CommandWithMutableRange('normal<bang>', <line1>, <line2>, <q-args>)

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
