" TODO Add default files ( see https://unix.stackexchange.com/a/597550/100689
" ) if in vim8

" Used for host detection
let hostname = substitute(system('hostname'), '\n', '', '')
let hostos   = substitute(system('uname -o'), '\n', '', '')
let hostkv   = substitute(system('uname -v'), '\n', '', '')

" Set up some paths that might be changed later based on the platform.  These
" are defaulted to their linux path
"let g:dotfiles   = $HOME . '/dotfiles'
let g:dotfiles   = '/home/matt/dotfiles'
"let g:env_folder = $HOME . '/.virtualenvs/default'
let g:env_folder = '/home/matt/.virtualenvs/default'

if $TRUE_HOST !=? ''
   let domain='ec'
elseif match(hostname, 'siteground') >= 0
   " Siteground is an exception because it uses vim 7.0
   let domain='siteground'
elseif match(hostname, 'khea') >= 0
   let domain='home'
else
   let domain='any'
endif
" echo 'Using domain ' . domain . ', hostname=' . hostname

" TODO Remove winbash, conflating the dotfiles just makes things complicated
let is_winbash=0
let is_win=0
if has('unix')
   if matchstr(hostkv, 'icrosoft') == 'icrosoft'
      let is_winbash=1
   endif
endif
if has('win32')||has('win32unix')||1==is_winbash
   let is_win=1
   if ''==$HOME && 0==is_winbash
      let $WINHOME_WIN     = 'c:/users/' . $USERNAME
      let g:dotfiles   = $WINHOME_WIN . '/dotfiles'
      let g:env_folder = $WINHOME_WIN . '/.virtualenvs/default'
   endif
endif


if has('nvim') && isdirectory(g:env_folder)
   if has('win32')
      let g:python_host_prog  = expand(g:env_folder . '/Scripts/python.exe')
      let g:python3_host_prog = g:python_host_prog
   else
      let g:python_host_prog  = expand(g:env_folder . '/bin/python')
      let g:python3_host_prog = g:python_host_prog . '3'
   endif

   if empty(glob(g:python_host_prog))
      echom 'Could not find g:python_host_prog = '. g:python_host_prog
      let g:python_host_prog = trim(system('which python3'))
      echom 'Setting g:python_host_prog = '. g:python_host_prog
   endif
   if empty(glob(g:python3_host_prog))
      echom 'Could not find g:python3_host_prog = '. g:python3_host_prog
      let g:python3_host_prog = trim(system('which python3'))
      echom 'Setting g:python3_host_prog = '. g:python3_host_prog
   endif
endif


" Configure some unconventional filetypes
augroup filetypes
   au BufNewFile,BufRead *.snippets          setlocal ft=snippet

   " EnvCan filetypes
   au BufNewFile,BufRead *.spi               setlocal ft=tcl
   au BufNewFile,BufRead *.dot               setlocal ft=zsh

   " NTC only-rules (so far)
   au BufNewFile,BufRead *.vert,*.geo,*.frag setlocal ft=glsl

   au BufNewFile,BufRead *.module            setlocal ft=php
   au BufNewFile,BufRead *.gs                setlocal ft=javascript
   au BufNewFile,BufRead *.json              setlocal ft=json
   au BufNewFile,BufRead *.json.in           setlocal ft=json
   au BufNewFile,BufRead *.kt                setlocal ft=kotlin

   " Ford
   au BufNewFile,BufRead *.fidl,*.fdepl      setlocal ft=fidl
   au BufNewFile,BufRead api/current.txt     setlocal ft=java
   au BufNewFile,BufRead */Config.in         setlocal ft=make
   au BufNewFile,BufRead */Config.in.host    setlocal ft=make

   au BufNewFile,BufRead Dockerfile*         setlocal ft=dockerfile
   au BufNewFile,BufRead */modulefiles/**    setlocal ft=tcl
   au BufNewFile,BufRead */.conan/profiles/* setlocal ft=sh
   au BufNewFile,BufRead *.fs                setlocal ft=sh
   au BufNewFile,BufRead */aosp/*.rc         setlocal ft=sh
   au BufNewFile,BufRead *.envrc             setlocal ft=sh
   au BufNewFile,BufRead .jdbrc              setlocal ft=jdb
   au BufNewFile,BufRead .clangd             setlocal ft=yaml
   au BufNewFile,BufRead *.tmpl              setlocal ft=tmpl
   au BufNewFile,BufRead *.fsb               setlocal ft=fsb syntax=python
   au BufNewFile,BufRead *.dot               setlocal ft=zsh
   au BufNewFile,BufRead *.i3                setlocal ft=i3
augroup end

augroup whitespace
   autocmd!
   autocmd FileType cs              setlocal ff=dos
   autocmd FileType yaml,json       setlocal ts=2 sw=2 sts=2 expandtab ai
   autocmd FileType markdown        setlocal spell
   autocmd FileType tex             setlocal spell
   autocmd FileType xml             setlocal ts=2 sw=2 sts=2 expandtab ai
   autocmd FileType cmake           setlocal ts=2 sw=2 sts=2 expandtab ai
   autocmd FileType make            setlocal ts=8 sw=8 sts=8 noet ai
   autocmd FileType fidl            setlocal ts=2 sw=2 sts=2 expandtab ai
   autocmd FileType aidl            setlocal ts=2 sw=2 sts=2 expandtab ai
   autocmd FileType gitcommit       setlocal ts=2 sw=2 sts=2 expandtab spell | syntax off
   autocmd FileType groovy          setlocal ts=4 sw=4 sts=4 expandtab
   autocmd FileType lua             setlocal ts=2 sw=2 sts=2 expandtab
   autocmd FileType cs,cpp,c,kotlin,java setlocal ts=4 sw=4 sts=4 expandtab
   autocmd FileType sh,ps1,dot      setlocal ts=2 sw=2 sts=2 expandtab
   autocmd FileType bzl,javascript  setlocal ts=4 sw=4 sts=4 expandtab
   autocmd FileType go              setlocal ts=2 sw=2 sts=2 expandtab
   autocmd FileType fsb             setlocal ts=2 sw=2 sts=2 expandtab
augroup END

" Set the comment string for certain filetypes to
" double slashes (used for vim-commentary):
augroup FTOptions
    autocmd!
    autocmd FileType c,cpp,cs,java,bzl,javascript,php,fidl setlocal commentstring=//\ %s
    autocmd FileType sh,jdb,cmake                          setlocal commentstring=#\ %s
    autocmd FileType tmpl                                  setlocal commentstring=##\ %s
    autocmd FileType fsb                                   setlocal commentstring=#\ %s
    autocmd FileType i3                                    setlocal commentstring=#\ %s
augroup END

augroup SHORTCUTS
   " Comment out parameter
   autocmd FileType c,cpp noremap wcc :exec 's/\(\<'.expand('<cword>') .'\>\)/\/* \1 *\//g'<CR>
augroup END

" Highlight non-ascci characters
syntax match nonascii "[^\x00-\x7F]"
highlight nonascii guibg=Red ctermbg=2

set nocompatible  " Dein also wants this

" Enable true colour support:
if !exists('g:gui_oni') && has('termguicolors')
  set termguicolors
endif

let &runtimepath.=','.expand("~/.local/bin")

if has('nvim-0.5')
   lcd /home/matt/dotfiles/stow/neovim/.config/nvim/lua
   lua require('utils')
   lua require("init")
endif


" Colour schemes
" colo hydrangea
" colo flatland
" colo argonaut
" colo ayu
" colo argonaut
" colo doorhinge
" colo nord
" colo cobalt
" colo palenight
" colo habamax
" colo bvemu
" colo darkspectrum
colo sonofobsidian

""""""""""""""""""""""" Lightline """"""""""""""""""""""""
function! LightlineFilename()
   return &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
      \ &filetype ==# 'unite' ? unite#get_status_string() :
      \ &filetype ==# 'vimshell' ? vimshell#get_status_string() :
      \ expand('%:t') !=# '' ? @% : '[No Name]'
endfunction

function! LightlineReadonly()
   return &readonly ? '' : ''
endfunction

"""""""""""""""""""""" /Lightline """"""""""""""""""""""""


" Have vim reload a file if it has changed outside
" of vim:
if !has('nvim')
   set autoread
endif


" """""""""""""""" Rainbow (foldering) """""""""""""""""""
"    let g:rainbow_conf = {
"    \   'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
"    \   'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
"    \   'operators': '_,_',
"    \   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
"    \   'separately': {
"    \      '*': {},
"    \      'tex': {
"    \         'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
"    \      },
"    \      'cpp': {
"    \         'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
"    \      },
"    \      'vim': {
"    \         'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
"    \      },
"    \      'html': {
"    \         'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
"    \      },
"    \      'css': 0,
"    \   }
"    \}
" """""""""""""""" /Rainbow (foldering) """""""""""""""""""


""""""""""""""""""""" Generate UUID """"""""""""""""""""""""
if has('unix')
   silent! py import uuid
   noremap <leader>u :s/REPLACE_UUID/\=pyeval('str(uuid.uuid4())')/g
   noremap <leader>ru :%s/REPLACE_UUID/\=pyeval('str(uuid.uuid4())')/g
endif
"""""""""""""""""""" /Generate UUID """"""""""""""""""""""""

" Make W the same as w
" https://stackoverflow.com/a/3878710/1861346
command Q q
" command W w
command Wqa wqa
" command Tabe tabe


filetype on
syntax on
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>
let fortran_free_source=1
let fortran_have_tabs=1
set number
set ignorecase
set noincsearch
set hlsearch
" if 0==is_win
"    set ff=unix,dos
" endif

" Easy save
inoremap <C-S> <Esc>:w<CR>
" map alt/apple or something-S for khea

" Clean out colour codes
function! CleanNonPrintables()
   %s/.\d\+;\d\+\(m\|;\d\+m\)//g
   %s/[^[:print:]]//g
endfunction

" Remove trailing space
nnoremap <leader>rt :silent! %s/\s\+$//e<CR>
let @r='\rt'
let @t=':try|silent! exe "norm! @r"|endtry|w|n'
" autocmd FileType php,bp,c,cpp,h,hpp,aidl,javascript,python autocmd BufWritePre <buffer> :call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))

" Ignore whitespace on vimdiff
if &diff
   " diff mode
   set diffopt+=iwhite
endif

" Faster vertical expansion
nmap <C-v> :vertical resize +5<cr>
nmap <C-h> :above resize +5<cr>

" Swap splits to vertical
noremap <C-w>th <C-W>t<c-w>H
noremap <C-w>tv <C-W>t<c-w>K

" Replace highlighted content with content of register 0
noremap <C-p> ciw<Esc>"0p

" Un-indent current line by one tab stop
imap <S-Tab> <C-o><<

" Stay in visual mode when indenting. You will never have to run gv after
" performing an indentation.
vnoremap < <gv
vnoremap > >gv

" Auto-correct spelling mistakes
" source: https://castel.dev/post/lecture-notes-1/
set spelllang=en_gb,en_us
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

" Map // to search for highlighted text. Source
" http://vim.wikia.com/wiki/Search_for_visually_selected_text
" TODO learn how to get the selected text escaped
vnoremap // y/<C-R>"<CR>

" Use ESC to except insert mode in Nvim terminal
:tnoremap <Esc> <C-\><C-n>

" " Search of IP addresses
" nnoremap /ip /\<\(\d\{1,3\}\.\d\{1,3\}\.\d\{1,3\}\.\d\{1,3\}\\|localhost\)\><CR>

" Search for merge lines
nnoremap <leader>m /^\(<\\|=\\|>\)\{7\}<CR>

" Shortcut to copy to clipboard
vnoremap <leader>y "+y
nnoremap <leader>y "+y

" Match <> brackets
set matchpairs+=<:>

" try to automatically fold xml
let xml_syntax_folding=1

" Without this, mouse wheel in vim/tmux scrolls tmux history, not vim's buffer
set mouse=a

"
" Abbreviations.  Check https://github.com/tpope/vim-abolish for how to make
" these case insensitive (if I need it)
ab flaot float
ab typoename typename
ab typoname typename
ab boid void
ab laster laser
ab jsut just
ab eticket etiket
ab breif brief
ab OPL2 OPAL2
ab unqiue unique
ab unique unique
ab AdditionaInputs AdditionalInputs
ab cosnt const
ab horizonal horizontal
ab appraoch approach
ab yeild yield
ab lsit list

" Used for vim-rhubarb, this should be in init.lua but not sure how right now
let g:github_enterprise_urls = ['https://github.ford.com']

" Directory aliases.  TODO generalize this somehow
" nnoremap <leader>2 :@"<CR>
" vmap <space> "xy:@x<CR> " https://stackoverflow.com/a/31441749/1861346
let $fsb_r=expand($PHX_FSB_ROOT)
let $fsb_s=$fsb_r . "/source/phoenix_hi/package"
let $fsb_p=$fsb_r . "/package/phoenix"

" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
  let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
  let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
  call append(line("$"), l:modeline)
endfunction
nnoremap <silent> <leader>wl :call AppendModeline()<CR>

" Echo full file path
command! Ep :echo expand('%:p')

" Open init.vim in a tab
let $init_vim=g:dotfiles . '/stow/neovim/.config/nvim/init.vim'
let $init_vim_plugins=g:dotfiles . '/stow/neovim/.config/nvim/lua/plugins/init.lua'
command! Settings :tabe $init_vim | vsp $init_vim_plugins

function! Open_fsb_dot()
   badd +0 ~/dotfiles/dotfiles-secret/ford/bin/fsb.dot
   badd +0 /f/phoenix/aosp/matt/phx-profiles/pdc/qnx_profile.dot
   tabe
   edit ~/dotfiles/dotfiles-secret/ford/bin/fsb.dot
   split /f/phoenix/aosp/matt/phx-profiles/pdc/qnx_profile.dot
endfunction

function! Open_system_la()
   badd +0 $fsb_r/output/phoenix_hi/package/bsp-os-images/src/apps/qnx_ap/target/hypervisor/host/out_8155/system.build_la
   tabe
   edit $fsb_r/output/phoenix_hi/package/bsp-os-images/src/apps/qnx_ap/target/hypervisor/host/out_8155/system.build_la
endfunction

function! Hi_vsomeip_log()
   syn match log_payload_unset 	'.*\(failed. Event payload not\).*'
   syn match log_credential_error 	'.*\(rejecting new connection\|Receiving credentials failed\|Broken pipe\).*'
   syn match log_connection_id 	'\(0x\|\)[a-fA-F0-9]\{4\}:[a-zA-Z0-9-_]\+'

   syn match log_tcp_debug "\zsTCP-DEBUG"
   syn match log_subscribe "\s\zsSUBSCRIB\w\+"
   syn match log_subscribe_pending ".*a remote subscription is already pending.*"
   syn match log_830f ".*0fe2\..*\.830f.*"


   " Warning, Constant, String, Type, Number
   " See highlight-groups

   hi def link log_830f 		Number
   hi def link log_tcp_debug 		Number
   hi def link log_payload_unset 		WarningMsg
   hi def link log_credential_error 		ErrorMsg
   hi def link log_subscribe_pending 		ErrorMsg
   hi def link log_subscribe 		Type
   hi def link log_connection_id 		Constant
endfunction

" https://stackoverflow.com/a/1270689/1861346
" :syn clear Repeat | g/^\(.*\)\n\ze\%(.*\n\)*\1$/exe 'syn match Repeat "^' . escape(getline('.'), '".\^$*[]') . '$"' | nohlsearch
function! HighlightRepeats() range
  let lineCounts = {}
  let lineNum = a:firstline
  while lineNum <= a:lastline
    let lineText = getline(lineNum)
    if lineText != ""
      let lineCounts[lineText] = (has_key(lineCounts, lineText) ? lineCounts[lineText] : 0) + 1
    endif
    let lineNum = lineNum + 1
  endwhile
  exe 'syn clear Repeat'
  for lineText in keys(lineCounts)
    if lineCounts[lineText] >= 2
      exe 'syn match Repeat "^' . escape(lineText, '".\^$*[]') . '$"'
    endif
  endfor
endfunction

command! -range=% HighlightRepeats <line1>,<line2>call HighlightRepeats()

function! Annotate_fdepl()
  exe '%s/\v(\w+ID\s*\=\s*)(\d+)/\=submatch(1) . submatch(2) . "  \/\/ 0x" . printf(''%04x'', submatch(2))'
endfunction

" Run bpfmt, really gotta handle the path better
if executable('/f/phoenix/aosp/out/host/linux-x86/bin/bpfmt')
   command! Bp :w | !/f/phoenix/aosp/out/host/linux-x86/bin/bpfmt -w %
endif

augroup FILE_FORMATTING
   " Formatters that aren't done _via_ the LSP
   autocmd FileType bp nnoremap <buffer><Leader>fu :Bp<CR>
augroup END

" vim: ts=3 sts=3 sw=3 expandtab nowrap ff=unix :
