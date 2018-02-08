let g:NicoVimIpcServer='/tmp/mpvsocket'
function! nicovim#play(url)
  if executable('mpv') 
    let s:cmd = join(['mpv', '--no-video', '--input-ipc-server='. g:NicoVimIpcServer, '--ytdl-raw-options="cookies='. g:NicoVimCookies .'"', a:url], " ")
    echo s:cmd
    let s:job = vimproc#popen3(s:cmd)
  endif
endfunction
