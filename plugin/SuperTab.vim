" Author: Gergely Kontra <kgergely@mcl.hu>
" Version: 0.2afix
" Description:
"   Use your tab key to do all your completion in insert mode!
"   The script remembers the last completion type, and applies that.
"   Eg.: You want to enter /usr/local/lib/povray3/
"   You type (in insert mode):
"   /u<C-x><C-f>/l<Tab><Tab><Tab>/p<Tab>/i<Tab>
"   You can also manipulate the completion type used by changing g:complType
"   variable.
"   Type <leader>ac to begin experimental auto-completion

if !exists('complType') "Integration with other copmletion functions...
  let complType="\<C-p>"
  im <C-X> <C-r>=CtrlXPP()<CR>
  fu! CtrlXPP()
    ec''|ec '-- ^X++ mode (/^E/^Y/^L/^]/^F/^I/^K/^D/^V/^N/^P/n/p)'
    let complType=nr2char(getchar())
    if stridx(
	  \"\<C-E>\<C-Y>\<C-L>\<C-]>\<C-F>\<C-I>\<C-K>\<C-D>\<C-V>\<C-N>\<C-P>np",
	  \complType)!=-1
      if stridx("\<C-E>\<C-Y>",complType)!=-1 " no memory, just scroll...
	retu "\<C-x>".complType
      elsei stridx('np',complType)!=-1
	let g:complType=nr2char(char2nr(complType)-96)  " char2nr('n')-char2nr("\<C-n")
      el
	let g:complType="\<C-x>".complType
      en
      iun <Tab>
      if g:complType=="\<C-p>" && g:complType=='p'
	im <Tab> <C-p>
      el
	im <Tab> <C-n>
      en
      return g:complType
    el
      echohl "Unknown mode"
      return complType
    en
  endf

  " From the doc |insert.txt| improved
  im <Tab> <C-p>
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
    el
      return g:complType
    en
  endfunction
en

let s:complLine=0
let s:complCol=0
let s:complLen=0
let acceptChar="\<Tab>"
let nextMatchChar="\<C-p>" "Can be <C-p> or <C-n>

fu! Ntimes(char, count)
  let i = a:count
  let r=''
  wh i>0
    let r=r.a:char
    let i=i-1
  endw
  return r
endf

fu! WordComp(char)
  let line=line('.')
  let origcol=col('.')

  if line==s:complLine && (origcol==s:complCol+1)
    "Cleanup (or accept) previous completion
    let rights=Ntimes("\<Right>",s:complLen)

    match none
    if a:char==g:acceptChar && s:complLen
      retu rights
    en
    let dels=Ntimes("\<Del>",s:complLen-(a:char=="\<Del>")) "char is returned once
  el
    let s:complLen=0
    let dels=''
  en

  if a:char!=g:nextMatchChar
    let nextchar=getline('.')[col('.')+s:complLen-1]
    if nextchar=~'\w' || a:char!~'\w' || a:char=="\<Del>" "Not wordend or not keyword char
      let s:complLen=0
      if s:complLen && a:char=="\<Del>"
	retu dels
      el
	retu dels.a:char
      en
    en
    let end=0
    exe 'norm! i'.dels.a:char.g:complType."\<Esc>"
    exe 'im '.g:nextMatchChar.' <C-r>=WordComp(nextMatchChar)<CR>'
  el
    "exe 'norm! i'.dels.g:complType.g:complType."\<Esc>"
    let end=1
    exe 'iun' g:nextMatchChar
    let s:complLen=0
    retu dels.g:complType.g:complType
  en
  let end=end+col('.')
  let i=end-origcol-1
  let res=''
  if i==-1
    let res="\<Right>"
  el
    wh i>0
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
  en
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
    en

  elseif strpart(a:mapchx,0,1) == '<'
    " save single map <something>
    if maparg(a:mapchx,a:mapmode) != ""
      let b:restoremap= a:mapmode."map ".a:mapchx." ".maparg(a:mapchx,a:mapmode)."|".b:restoremap
      exe a:mapmode."unmap ".a:mapchx
    en
  el
    " save multiple maps
    let i= 1
    wh i <= strlen(a:mapchx)
      let amap=a:maplead.strpart(a:mapchx,i-1,1)
      if maparg(amap,a:mapmode) != ""
	let b:restoremap= a:mapmode."map ".amap." ".maparg(amap,a:mapmode)."|".b:restoremap
	exe a:mapmode."unmap ".amap
      en
      let i= i + 1
    endwhile
  en
endfunction

fu! <SID>StartAutocomplete()
  let b:restoremap=''
  let i=32
  wh i<255
    sil cal <SID>SaveMap('i','','<Char-'.i.'>')
    exe 'im <Char-'.i."> <C-r>=WordComp(nr2char(".i."))<CR>"
    let i=i+1
  endw
  " TODO: Do it with acceptChar
  exe 'im '.'<Tab>'.' <C-r>=WordComp(acceptChar)<CR>'
  exe 'im '.g:nextMatchChar.' <C-r>=WordComp(nextMatchChar)<CR>'
  im <Esc> <C-r>=WordComp("\<lt>Esc>")<CR>
  im <Del> <C-r>=WordComp("\<lt>Del>")<CR>
  im <BS> <C-r>=WordComp(nr2char(8))<CR>
  nun <Leader>ac
  nm <Leader>ac :cal <SID>StopAutocomplete()<CR>
  am 20.899 &Edit.Stop\ autocomplete <Leader>ac
  ec ''| echon '[Autocomplete started]'
endf

fu! <SID>StopAutocomplete()
  let i=32
  wh i<255
    exe 'iun <Char-'.i.'>'
    let i=i+1
  endw
  if b:restoremap != ""
    exe b:restoremap
  en
  unl! b:restoremap
  nm <Leader>ac :cal <SID>StartAutocomplete()<CR>
  am 20.899 &Edit.Start\ autocomplete <Leader>ac
  ec ''| echon'[Autocomplete stopped]'
endf

fu! <SID>Init()
  redi @a
  hi Search
  redi END
  exe 'hi Compl '.substitute(strpart(@a,matchend(@a,'xxx ')),"\n",' ','g')
  nm <Leader>ac :sil cal <SID>StartAutocomplete()<Bar>ec ''<Bar>ec '[Autocomplete started]'<CR>
  am &Edit.Start\ autocomplete <Leader>ac
endf
sil cal <SID>Init()
