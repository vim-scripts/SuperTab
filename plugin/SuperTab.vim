" Author: Gergely Kontra <kgergely@mcl.hu>
" Version: 0.2alpha
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
  echo''|echo '-- ^X++ mode (/^E/^Y/^L/^]/^F/^I/^K/^D/^V/^N/^P/n/p)'
  let complType=nr2char(getchar())
  if stridx(
    \"\<C-E>\<C-Y>\<C-L>\<C-]>\<C-F>\<C-I>\<C-K>\<C-D>\<C-V>\<C-N>\<C-P>np",
    \complType)!=-1
    if complType!="n" && complType!="p"
      let g:complType="\<C-x>".complType
    else
      let g:complType=nr2char(char2nr(complType)-96)  " char2nr('n')-char2nr("\<C-n")
    endif
    if g:complType=="\<C-p>" && g:complType=='p'
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
  endif
endfunction

let s:complLine=0
let s:complCol=0
let s:complLen=0
let acceptChar="\<CR>"
let nextMatchChar="\<C-p>" "Can be <C-p> or <C-n>

fu! WordComp(char)
  let line=line('.')
  let origcol=col('.')

  if line==s:complLine && (origcol==s:complCol+1)
    "Cleanup (or accept) previous completion
    let i=s:complLen
    let rights=''
    wh i
      let rights=rights."\<Right>"
      let i=i-1
    endw

    match none
    if a:char==g:acceptChar && s:complLen
      retu rights
    endif
    let dels=substitute(rights,"\<Right>","\<Del>","g")
  else
    let s:complLen=0
    let dels=''
  endif

  if a:char!=g:nextMatchChar
    let nextchar=getline('.')[col('.')+s:complLen-1]
    if nextchar=~'\w' || a:char!~'\w' || a:char=="\<Del>" "Not wordend or not keyword char
      let s:complLen=0
      if s:complLen && a:char=="\<Del>"
	retu dels
      else
	retu dels.a:char
      endif
    endif
    let end=0
    exe 'norm! i'.dels.a:char.g:complType."\<Esc>"
    exe 'imap '.g:nextMatchChar.' <C-r>=WordComp(nextMatchChar)<CR>'
  else
    "exe 'norm! i'.dels.g:complType.g:complType."\<Esc>"
    let end=1
    exe 'iun' g:nextMatchChar
    let s:complLen=0
    retu dels.g:complType.g:complType
  endif
  let end=end+col('.')
  let i=end-origcol-1
  let res=''
  if i==-1
    let res="\<Right>"
  else
    while i>0
      let res=res."\<Left>"
      let i=i-1
    endw
    redr
    "hi clear Compl
    let s:complLine=line
    let s:complCol=origcol
    let s:complLen=end-origcol
    match none
    exe 'match Compl /\%'.line.'l\%'.(1+origcol).'c.\{'.s:complLen.'}/'
  endif
  retu res
endf

" ---------------------------------------------------------------------
"  Author: Charles E. Campbell, Jr.
" SaveMap: this function sets up a buffer-variable (b:restoremap)
"          which will be used by HMBStop to restore user maps
"          mapchx: either <something>  which is handled as one map item
"                  or a string of single letters which are multiple maps
"                  ex.  mapchx="abc" and maplead='\': \a \b and \c are saved
fu! <SID>SaveMap(mapmode,maplead,mapchx)

  if strpart(a:mapchx,0,1) == ':'
    " save single map :...something...
    let amap=strpart(a:mapchx,1)
    if maparg(amap,a:mapmode) != ""
      let b:restoremap= a:mapmode."map ".amap." ".maparg(amap,a:mapmode)."|".b:restoremap
      exe a:mapmode."unmap ".amap
    endif

  elseif strpart(a:mapchx,0,1) == '<'
    " save single map <something>
    if maparg(a:mapchx,a:mapmode) != ""
      let b:restoremap= a:mapmode."map ".a:mapchx." ".maparg(a:mapchx,a:mapmode)."|".b:restoremap
      exe a:mapmode."unmap ".a:mapchx
    endif

  else
    " save multiple maps
    let i= 1
    while i <= strlen(a:mapchx)
      let amap=a:maplead.strpart(a:mapchx,i-1,1)
      if maparg(amap,a:mapmode) != ""
	let b:restoremap= a:mapmode."map ".amap." ".maparg(amap,a:mapmode)."|".b:restoremap
	exe a:mapmode."unmap ".amap
      endif
      let i= i + 1
    endwhile
  endif
endfunction

fu! <SID>StartAutoComplete()
  let b:restoremap=''
  let i=32
  while i<127
    call <SID>SaveMap('i','','<Char-'.i.'>')
    exe 'imap <Char-'.i."> <C-r>=WordComp(nr2char(".i."))<CR>"
    let i=i+1
  endw
  exe 'imap '.g:acceptChar.' <C-r>=WordComp(acceptChar)<CR>'
  exe 'imap '.g:nextMatchChar.' <C-r>=WordComp(nextMatchChar)<CR>'
  imap <Esc> <C-r>=WordComp("\<lt>Esc>")<CR>
  imap <Del> <C-r>=WordComp("\<lt>Del>")<CR>
  imap <BS> <C-r>=WordComp(nr2char(8))<CR>
  nunmap <Leader>ac
  nmap <Leader>ac :call <SID>StopAutoComplete()<CR>
  redir @a
  hi Search
  redir END
  exe 'hi Compl '.substitute(strpart(@a,matchend(@a,'xxx ')),"\n",' ','g')
endf

fu! <SID>StopAutoComplete()
  let i=32
  while i<127
    exe 'iun <Char-'.i.'>'
    let i=i+1
  endif
  iun <Esc>
  iun <Del>
  iun <BS>
  iun <Leader>ac
  if b:restoremap != ""
    exe b:restoremap
  endif
  unlet! b:restoremap
  echo '[Autocomplete stopped]'
  nmap <Leader>ac :call <SID>StartAutoComplete()<CR>
endf

nmap <Leader>ac :silent call <SID>StartAutoComplete()<Bar>echo ''<Bar>echo '[Autocomplete started]'<CR>



