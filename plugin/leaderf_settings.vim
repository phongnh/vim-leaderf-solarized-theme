if empty(globpath(&rtp, 'plugin/leaderf.vim'))
    echohl WarningMsg | echomsg 'LeaderF is not found.' | echohl none
    finish
endif

if exists('g:loaded_leaderf_settings_vim')
    finish
endif

if get(g:, 'Lf_SolarizedTheme', 0)
    let g:Lf_StlColorscheme = 'solarized'

    function! s:InitSolarizedColorscheme() abort
        call leaderf#colorscheme#solarized#init()
        let g:Lf_PopupPalette = leaderf#colorscheme#solarized#popup_init()
    endfunction

    call s:InitSolarizedColorscheme()

    augroup VimLeaderfSolarizedTheme
        autocmd!
        autocmd ColorschemePre * call <SID>InitSolarizedColorscheme()
    augroup END
endif

" Powerline Separator
if get(g:, 'Lf_Powerline', 0)
    let s:powerline_separator_styles = {
                \ 'default': { 'left': "\ue0b0", 'right': "\ue0b2" },
                \ 'curvy':   { 'left': "\ue0b4", 'right': "\ue0b6" },
                \ 'angly1':  { 'left': "\ue0b8", 'right': "\ue0ba" },
                \ 'angly2':  { 'left': "\ue0bc", 'right': "\ue0be" },
                \ 'angly3':  { 'left': "\ue0b8", 'right': "\ue0be" },
                \ 'angly4':  { 'left': "\ue0bc", 'right': "\ue0ba" },
                \ 'custom':  { 'left': "\ue0d2", 'right': "\ue0d4" },
                \ }

    function! s:Rand() abort
        return str2nr(matchstr(reltimestr(reltime()), '\v\.@<=\d+')[1:])
    endfunction

    function! s:GetSeparator(style) abort
        let l:style = a:style
        if l:style ==? 'random'
            let l:style = keys(s:powerline_separator_styles)[s:Rand() % len(s:powerline_separator_styles)]
        endif

        return get(s:powerline_separator_styles, l:style, s:powerline_separator_styles['default'])
    endfunction

    let g:Lf_StlSeparator = s:GetSeparator(get(g:, 'Lf_Powerline_Style', 'default'))
else
    let g:Lf_StlSeparator = { 'left': '', 'right': '' }
endif

let g:Lf_WindowHeight  = 0.30
let g:Lf_MruMaxFiles   = 200
let g:Lf_CursorBlink   = 1
let g:Lf_PreviewResult = { 'BufTag': 0, 'Function': 0 }

" Popup Settings
if get(g:, 'Lf_Popup', 0) && ((exists('*popup_create') && has('patch-8.1.1615')) || (exists('*nvim_win_set_config') && has('nvim-0.4.2')))
    let g:Lf_PopupShowStatusline  = 0
    let g:Lf_PreviewInPopup       = 1
    let g:Lf_PopupPreviewPosition = 'bottom'
    let g:Lf_WindowPosition       = 'popup'
endif

let g:Lf_UseCache       = 0  " rg/fd is enough fast, we don't need cache
let g:Lf_NeedCacheTime  = 10 " 10 seconds
let g:Lf_UseMemoryCache = 0

let g:Lf_NoChdir              = 1
let g:Lf_WorkingDirectoryMode = 'c'

let g:Lf_RgConfig = [
            \ '-H',
            \ '--no-heading',
            \ '--line-number',
            \ '--column',
            \ '--hidden',
            \ '--smart-case'
            \ ]

if get(g:, 'Lf_GrepIngoreVCS', 0)
    call add(g:Lf_RgConfig, '--no-ignore-vcs')
endif

let g:Lf_Ctags         = get(g:, 'Lf_Ctags', 'ctags')
let g:Lf_CtagsFuncOpts = {
            \ 'ruby': '--ruby-kinds=fFS',
            \ }

let g:Lf_GtagsAutoGenerate = 0
let g:Lf_GtagsAutoUpdate   = 0
let g:Lf_GtagsGutentags    = 0

let g:Lf_GtagsGutentags = ''
let g:Lf_Gtagslabel     = 'default'

let g:Lf_CommandMap = {
            \ '<F5>':  ['<F5>', '<C-z>'],
            \ '<Esc>': ['<Esc>', '<C-g>'],
            \ }

" These options are passed to external tools (rg, fd and pt, ...)
let g:Lf_ShowHidden  = 0

let g:Lf_WildIgnore = {
            \ 'dir': ['.svn', '.git', '.hg', 'node_modules', '.gems', 'gems'],
            \ 'file': ['*.sw?', '~$*', '*.bak', '*.exe', '*.o', '*.so', '*.py[co]']
            \ }

function! s:LeaderfRoot() abort
    let current = get(g:, 'Lf_WorkingDirectoryMode', 'c')
    try
        let g:Lf_WorkingDirectoryMode = 'Ac'
        :LeaderfFile
    finally
        let g:Lf_WorkingDirectoryMode = current
    endtry
endfunction

command! -bar LeaderfRoot call <SID>LeaderfRoot()

let s:Lf_AvailableCommands = filter(['rg', 'fd'], 'executable(v:val)')

if empty(s:Lf_AvailableCommands)
    finish
endif

let g:Lf_FindTool    = get(g:, 'Lf_FindTool', 'rg')
let g:Lf_FollowLinks = get(g:, 'Lf_FollowLinks', 0)
let s:Lf_FollowLinks = g:Lf_FollowLinks

let s:Lf_FindCommands = {
            \ 'rg': 'rg "%s" --files --color never --no-ignore-vcs --ignore-dot --ignore-parent --hidden',
            \ 'fd': 'fd "%s" --type file --color never --no-ignore-vcs --hidden',
            \ }

function! s:BuildFindCommand() abort
    let l:cmd = s:Lf_FindCommands[s:Lf_CurrentCommand]
    if s:Lf_FollowLinks
        let l:cmd .= ' --follow'
    endif
    return l:cmd
endfunction

function! s:DetectCurrentCommand() abort
    let idx = index(s:Lf_AvailableCommands, g:Lf_FindTool)
    let s:Lf_CurrentCommand = get(s:Lf_AvailableCommands, idx > -1 ? idx : 0)
endfunction

function! s:BuildExternalCommand() abort
    let g:Lf_ExternalCommand = s:BuildFindCommand()
endfunction

function! s:PrintCurrentCommandInfo() abort
    echo 'LeaderF is using command `' . g:Lf_ExternalCommand . '`!'
endfunction

command! PrintLeaderfCurrentCommandInfo call <SID>PrintCurrentCommandInfo()

function! s:ChangeExternalCommand(bang, command) abort
    " Reset to default command
    if a:bang
        call s:DetectCurrentCommand()
    elseif strlen(a:command)
        if index(s:Lf_AvailableCommands, a:command) == -1
            return
        endif
        let s:Lf_CurrentCommand = a:command
    else
        let idx = index(s:Lf_AvailableCommands, s:Lf_CurrentCommand)
        let s:Lf_CurrentCommand = get(s:Lf_AvailableCommands, idx + 1, s:Lf_AvailableCommands[0])
    endif
    call s:BuildExternalCommand()
    call s:PrintCurrentCommandInfo()
endfunction

function! s:ListAvailableCommands(...) abort
    return s:Lf_AvailableCommands
endfunction

command! -nargs=? -bang -complete=customlist,<SID>ListAvailableCommands ChangeLeaderfExternalCommand call <SID>ChangeExternalCommand(<bang>0, <q-args>)

function! s:ToggleFollowLinks() abort
    if s:Lf_FollowLinks == 0
        let s:Lf_FollowLinks = 1
        echo 'LeaderF follows symlinks!'
    else
        let s:Lf_FollowLinks = 0
        echo 'LeaderF does not follow symlinks!'
    endif
    call s:BuildExternalCommand()
endfunction

command! ToggleLeaderfFollowLinks call <SID>ToggleFollowLinks()

call s:DetectCurrentCommand()
call s:BuildExternalCommand()

let g:loaded_leaderf_settings_vim = 1
