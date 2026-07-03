-- gruvbox light hard
require('gruvbox').setup {
  contrast = 'hard',
  transparent_mode = true, -- let ghostty's background-opacity show through
  italic = { strings = false, comments = false },
}
vim.o.background = 'light'
vim.cmd.colorscheme 'gruvbox'
