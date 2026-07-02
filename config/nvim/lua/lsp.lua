-- Native 0.11 LSP: nvim-lspconfig only supplies server defaults;
-- vim.lsp.config()/vim.lsp.enable() do the wiring. Servers come from PATH (NixOS).

-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
  float = { border = "rounded", source = true },
})

-- Per-server settings (merged over nvim-lspconfig defaults)
vim.lsp.config("nil_ls", {
  settings = {
    ["nil"] = {
      formatting = { command = { "nixpkgs-fmt" } },
    },
  },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable({
  "gopls",
  "rust_analyzer",
  "pyright",
  "ts_ls",
  "nil_ls",
  "lua_ls",
  "bashls",
  "terraformls",
  "yamlls",
})

-- Native autocompletion (no nvim-cmp / blink.cmp)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})
