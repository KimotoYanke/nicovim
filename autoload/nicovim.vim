let g:NicoVimIpcServer='/tmp/mpvsocket'

function! s:echo_is_not_installed(software)
  echo a:software . ' is not installed'
endfunction

function! nicovim#play(url)
  if executable('mpv')
    let s:ytdlOptions='cookies=' . g:NicoVimCookies
    let s:cmd = join(['mpv', '--no-video', 
          \ '--input-ipc-server='. g:NicoVimIpcServer, 
          \ '--ytdl-raw-options="'. s:ytdlOptions .'"', 
          \ a:url], " ")
    echo s:cmd
    let s:job = vimproc#popen3(s:cmd)
  else
    call s:echo_is_not_installed('MPV')
  endif
endfunction

function! nicovim#pause()
    let s:cmd='{ "command": ["set_property", "pause", true] }'
    call nicovim#command_to_mpv(s:cmd)
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
