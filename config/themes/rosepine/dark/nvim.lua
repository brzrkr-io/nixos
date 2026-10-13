-- Rose Pine main
require('rose-pine').setup {
  variant = 'main',
  styles = { transparency = true, italic = false },
}
vim.o.background = 'dark'
vim.cmd.colorscheme 'rose-pine'
