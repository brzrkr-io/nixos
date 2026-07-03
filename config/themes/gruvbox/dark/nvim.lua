-- gruvbox dark hard
require('gruvbox').setup {
  contrast = 'hard',
  transparent_mode = true, -- let ghostty's background-opacity show through
  italic = { strings = false, comments = false },
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'gruvbox'
