" Author: Gergely Kontra <kgergely@mcl.hu>
" Version: 0.1
" Description:
"   Use your tab key to do all your completion in insert mode!
"   The script remembers the last completion type, and applies that.
"   Eg.: You want to enter /usr/local/lib/povray3/
"   You type (in insert mode):
"   /u<C-x><C-f>/l<Tab><Tab><Tab>/p<Tab>/i<Tab>
"   You can also manipulate the completion type used by changing g:complType
"   variable.
let complType="\<C-p>"
imap <C-X> <C-r>=<SID>MyCompl()<CR>
fu! <SID>MyCompl()
  echo''|echo '-- ^X++ mode (/^E/^Y/^L/^]/^F/^I/^K/^D/^V/^N/^P)'
  let complType=nr2char(getchar())
  if stridx(
    \"\<C-E>\<C-Y>\<C-L>\<C-]>\<C-F>\<C-I>\<C-K>\<C-D>\<C-V>\<C-N>\<C-P>",
    \complType)!=-1
    if complType!="\<C-n>" && complType!="\<C-p>"
      let g:complType="\<C-x>".complType
    else
      let g:complType=complType
    endif
    if g:complType=="\<C-p>"
      iun <Tab>
      imap <Tab> <C-p>
    else
      iun <Tab>
      imap <Tab> <C-n>
    endif
    return g:complType
  else
    echohl "Unknown mode"
    return complType
  endif
endf

" From the doc |insert.txt| improved
imap <Tab> <C-p>
" This way after hitting <Tab>, hitting it once more will go to next match
" (because in XIM mode <C-n> and <C-p> mappings are ignored)
" and wont start a brand new completion
" The side effect, that in the beginning of line <C-n> and <C-p> inserts a
" <Tab>, but I hope it may not be a problem...
inoremap <C-n> <C-R>=<SID>SuperTab()<CR>
inoremap <C-p> <C-R>=<SID>SuperTab()<CR>

function! <SID>SuperTab()
  if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"
  else
    return g:complType
endfunction
