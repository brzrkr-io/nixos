-- gruvbox dark hard
require('gruvbox').setup {
  contrast = 'hard',
  italic = { strings = false, comments = false },
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'gruvbox'
