-- tokyonight light (day)
require('tokyonight').setup {
  styles = {
    comments = { italic = false },
  },
}
vim.o.background = 'light'
vim.cmd.colorscheme 'tokyonight-day'
