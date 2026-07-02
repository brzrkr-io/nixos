-- Bootstrap lazy.nvim (plain plugin manager, inline spec list)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- configs-based API; main branch is a different setup
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "go", "gomod", "gosum", "hcl", "javascript", "json", "lua",
          "markdown", "markdown_inline", "nix", "python", "query", "regex",
          "rust", "terraform", "toml", "tsx", "typescript", "vim", "vimdoc",
          "yaml",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Server default configs only; native vim.lsp.enable does the rest (see lsp.lua)
  { "neovim/nvim-lspconfig" },

  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = {},
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous hunk")
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", gs.blame_line, "Blame line")
      end,
    },
  },

  {
    "stevearc/oil.nvim",
    lazy = false, -- so `nvim <dir>` works
    opts = {
      view_options = { show_hidden = true },
    },
  },
}, {
  -- No luarocks, no update checker noise
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { notify = false },
})
