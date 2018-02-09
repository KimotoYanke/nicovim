let g:NicoVimIpcServer='/tmp/mpvsocket'
let s:playing=''
let s:status=''

let s:async_vimproc = {
      \   'response': '',
      \   'original_updatetime': 0
      \ }

function! nicovim#display_infomation()
  echo s:async_vimproc
  echo 'play:' . s:playing
  echo 'status:' . s:status
endfunction

augroup async_vimproc
  autocmd!
augroup END

function! s:async(exec, callback)
  let s:async_vimproc.original_updatetime = &updatetime
  set updatetime=50
  let s:async_vimproc.vimproc = vimproc#pgroup_open(a:exec)
  let s:async_vimproc.callback = a:callback
  autocmd async_vimproc CursorHold,CursorHoldI * call s:callback()
  sleep 50m
  call s:callback()
endfunction


function! s:callback()
  if s:async_vimproc.vimproc.stdout.eof  || (match(s:async_vimproc.response, 'end-file') != -1)
    autocmd! async_vimproc
    let &updatetime = s:async_vimproc.original_updatetime
    call s:async_vimproc.callback(s:async_vimproc.response)
    unlet s:async_vimproc.vimproc
    unlet s:async_vimproc.callback
    let s:async_vimproc.response = ''
  else
    let s:async_vimproc.response .= s:async_vimproc.vimproc.stdout.read()
  endif
endfunction

function! s:echo_is_not_installed(software)
  echo a:software . ' is not installed'
endfunction

function! s:mpv_finished_callback(responce)
  let s:playing = 'finished'
  let s:status = 'finished'
endfunction

function! nicovim#start(url)
  if !executable('mpv')
    call s:echo_is_not_installed('MPV')
  elseif !executable('socat')
    call s:echo_is_not_installed('socat')
  else
    let s:ytdlOptions='cookies=' . g:NicoVimCookies
    let s:cmd = join(['mpv', '--no-video', 
          \ '--input-ipc-server='. g:NicoVimIpcServer, 
          \ '--ytdl-raw-options="'. s:ytdlOptions .'"', 
          \ a:url], " ")
    let s:observerCmd = join(['socat', g:NicoVimIpcServer, 'stdout'], ' ')
    call vimproc#popen3(s:cmd)
    sleep 500m
    call s:async(s:observerCmd, function('s:mpv_finished_callback'))
    let s:playing = a:url
    let s:status = 'play'
    echo s:playing
  endif
endfunction

function! nicovim#play(...)
  if a:0 > 0 && a:1 !=# s:playing
    call nicovim#start(a:1)
  else
    call nicovim#unpause()
  endif
endfunction

function! nicovim#unpause()
  if s:status !=# 'play'
    let s:cmd='{ "command": ["set_property", "pause", false] }'
    let s:status = 'play'
    call nicovim#command_to_mpv(s:cmd)
  endif
endfunction

function! nicovim#pause()
  if s:status !=# 'pause'
    let s:cmd='{ "command": ["set_property", "pause", true] }'
    let s:status = 'pause'
    call nicovim#command_to_mpv(s:cmd)
  else
    echo 'Not playing:(' . s:status . ')'
  endif
endfunction

function! nicovim#command_to_mpv(cmd)
  if !executable('socat')
    call s:echo_is_not_installed('socat')
    finish
  elseif !filereadable(g:NicoVimIpcServer)
    echo g:NicoVimIpcServer . ' is not found'
    finish
  else
    let s:cmd = join(['echo', "'" . a:cmd . "'", '|', 'socat', '-', g:NicoVimIpcServer], ' ')
    let s:job = vimproc#system(s:cmd)
  endif
endfunction
