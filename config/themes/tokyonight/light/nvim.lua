-- tokyonight light (day)
require('tokyonight').setup {
  transparent = true, -- let ghostty's background-opacity show through
  styles = {
    comments = { italic = false },
    sidebars = 'transparent',
    floats = 'transparent',
  },
}
vim.o.background = 'light'
vim.cmd.colorscheme 'tokyonight-day'
