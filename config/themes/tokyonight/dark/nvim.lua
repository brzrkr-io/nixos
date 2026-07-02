-- tokyonight dark
require('tokyonight').setup {
  styles = {
    comments = { italic = false },
  },
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'tokyonight-night'
