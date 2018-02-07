syntax on

"This is for wraping left and right so that cursor left at the beginning of the line goes to end of the previous line
set whichwrap+=<,>,h,l,[,] 

"The following piece of code for moving through wrapped lines refer:[http://vim.wikia.com/wiki/Move_through_wrapped_lines]
map <silent> <Up> gk
imap <silent> <Up> <C-o>gk
map <silent> <Down> gj
imap <silent> <Down> <C-o>gj
map <silent> <home> g<home>
imap <silent> <home> <C-o>g<home>
map <silent> <End> g<End>
imap <silent> <End> <C-o>g<End>

setlocal linebreak
setlocal nolist
setlocal display+=lastline
