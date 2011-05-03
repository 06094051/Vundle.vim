func! vundle#installer#install(bang, ...) abort
  let bundles = (a:1 == '') ?
        \ s:reload_bundles() :
        \ map(copy(a:000), 'vundle#config#init_bundle(v:val, {})')

  let cwd = getcwd()
  let new_bundles = []

  for bundle in bundles
    if !isdirectory(bundle.path()) | call mkdir(bundle.path(), 'p') | endif

    let g:bundle = bundle

    lcd `=bundle.path()`

    call s:doautocmd('BundleInstallPre',      'vundle#bundle')
    call s:doautocmd('BundleInstallPre',      'bundle#'.tolower(bundle.name))

    if a:bang || !(s:installed(bundle))
      call s:doautocmd('BundleInstall',       'vundle#bundle')
      call s:doautocmd('BundleInstall',       'bundle#'.tolower(bundle.name))
      call s:doautocmd('BundleInstallPost',   'vundle#bundle')
      call s:doautocmd('BundleInstallPost',   'bundle#'.tolower(bundle.name))

      call add(new_bundles, bundle)
    else
      call s:doautocmd('BundleInstalled',     'vundle#bundle')
      call s:doautocmd('BundleInstalled',     'bundle#'.tolower(bundle.name))
    endif
    lcd `=cwd`
  endfor

  let g:bundles = new_bundles
  call s:doautocmd('BundlesInstallPost',  'vundle#bundle')
endf

" TODO: verify whether autocommand already exists
" verbose autocmd User BundleInstall*
func! s:doautocmd(event, augroup_name)
  if 0 <= index(s:load_augroups(), a:augroup_name)
    exec 'doautocmd '.a:augroup_name.' User '.a:event
  endif
endf

func! vundle#installer#helptags(bundles) abort
  let bundle_dirs = map(copy(a:bundles),'v:val.rtpath()')
  let help_dirs = filter(bundle_dirs, 's:has_doc(v:val)')
  call map(copy(help_dirs), 's:helptags(v:val)')
  if !empty(help_dirs)
    call s:log('Helptags: done. '.len(help_dirs).' bundles processed')
  endif
  return help_dirs
endf

func! vundle#installer#clean(bang) abort
  let bundle_dirs = map(copy(g:vundle#bundles), 'v:val.path()') 
  let all_dirs = split(globpath(g:vundle#bundle_dir, '*'), "\n")
  let x_dirs = filter(all_dirs, '0 > index(bundle_dirs, v:val)')

  if empty(x_dirs)
    call s:log("All clean!")
    return
  end

  if (a:bang || input('Are you sure you want to remove '.len(x_dirs).' bundles? [ y/n ]:') =~? 'y')
    let cmd = (has('win32') || has('win64')) ?
    \           'rmdir /S /Q' :
    \           'rm -rf'
    exec '!'.cmd.' '.join(map(x_dirs, 'shellescape(v:val)'), ' ')
  endif
endf

func! s:reload_bundles()
  " TODO: obtain Bundles without sourcing .vimrc
  if filereadable($MYVIMRC)| silent source $MYVIMRC | endif
  if filereadable($MYGVIMRC)| silent source $MYGVIMRC | endif
  return g:vundle#bundles
endf

func! s:has_doc(rtp) abort
  return isdirectory(a:rtp.'/doc')
  \   && (!filereadable(a:rtp.'/doc/tags') || filewritable(a:rtp.'/doc/tags'))
  \   && !(empty(glob(a:rtp.'/doc/*.txt')) && empty(glob(a:rtp.'/doc/*.??x')))
endf

func! s:helptags(rtp) abort
  helptags `=a:rtp.'/doc/'`
endf

func! s:installed(bundle) abort
  return !empty(split(globpath(a:bundle.path(), '*'), "\n"))
endf

func! vundle#installer#sync(bang, bundle) abort
  if s:installed(a:bundle)
    if !(a:bang) | return 0 | endif
    let cmd = 'cd '.shellescape(a:bundle.path()).' && git pull'
  else
    let cmd = 'git clone '.a:bundle.uri.' '.shellescape(a:bundle.path())
  endif

  silent exec '!echo '.cmd | silent exec '!'.cmd

  return 1
endf

func! s:load_augroups()
  redir => v | silent verbose augroup | redir END
  let augroups = map(split(v,'[\n\r\t\ ]\+'), 'tolower(v:val)')
  return augroups
endf

" TODO: make it pause after output in console mode
func! s:log(msg)
  echo a:msg
endf
