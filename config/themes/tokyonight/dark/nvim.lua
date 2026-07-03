-- tokyonight dark
require('tokyonight').setup {
  transparent = true, -- let ghostty's background-opacity show through
  styles = {
    comments = { italic = false },
    sidebars = 'transparent',
    floats = 'transparent',
  },
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'tokyonight-night'
