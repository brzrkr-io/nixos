-- gruvbox light hard
require('gruvbox').setup {
  contrast = 'hard',
  italic = { strings = false, comments = false },
}
vim.o.background = 'light'
vim.cmd.colorscheme 'gruvbox'
