" Set to show line numbers
set number
  
" Enable syntax highlighting
syntax on

" :W sudo saves the file
command W w !sudo tee % > /dev/null

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8