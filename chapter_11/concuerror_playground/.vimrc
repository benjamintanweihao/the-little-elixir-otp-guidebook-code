" make sure the following 2 lines are included in ~/.vimrc
" set exrc
" set secure

map <leader>t :!mix test<CR>
map <leader>c :!mix compile && mix dialyzer<CR>
