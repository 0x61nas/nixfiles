return {
  'neovim/nvim-lspconfig',
  lazy = false,
  keys = {
    { 'gD',         vim.lsp.buf.declaration,     { noremap = true, silent = true }, desc = "Go To Declaration",    mode = 'n' },
    { 'gd',         vim.lsp.buf.definition,      { noremap = true, silent = true }, desc = "Go To Definition",     mode = 'n' },
    { 'gi',         vim.lsp.buf.implementation,  { noremap = true, silent = true }, desc = "Go To Implementation", mode = 'n' },
    { "K",          vim.lsp.buf.hover,           { silent = true },                 desc = "Show Info",            mode = "n" },
    { "<leader>k",  vim.lsp.buf.signature_help,  { silent = true, noremap = true }, desc = "Show Signature",       mode = "n" },
    { "<leader>r",  vim.lsp.buf.rename,          { silent = true, noremap = true }, desc = "Rename symbol",       mode = "n" },
    { "<leader>F",  vim.lsp.buf.format,          { silent = true, noremap = true }, desc = "Format",               mode = "n" },
    { '<Leader>gr', vim.lsp.buf.references,      { noremap = true, silent = true }, desc = "Go To References",     mode = 'n' },
    { '<Leader>D',  vim.lsp.buf.type_definition, { noremap = true, silent = true }, desc = "Show Type Definition", mode = 'n' },
  },
  config = function()
    -- Setup language servers.
    local lspconfig = require('lspconfig')
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Rust
    -- lspconfig.rust_analyzer.setup {
    --   -- Server-specific settings. See `:help lspconfig-setup`
    --   capabilities = capabilities,
    --   -- on_attach = on_attach,
    --   autostart = true,
    --   settings = {
    --     ["rust-analyzer"] = {
    --       cargo = {
    --         allFeatures = true,
    --       },
    --       imports = {
    --         group = {
    --           enable = false,
    --         },
    --       },
    --       completion = {
    --         postfix = {
    --           enable = false,
    --         },
    --       },
    --     },
    --   },
    -- }

    -- nix
    lspconfig.nil_ls.setup {
      -- on_attach = on_attach,
      capabilities = capabilities,
      autostart = true,
      settings = {
        ["nil"] = {
          formatting = {
            command = { "nixpkgs-fmt" },
          }
        }
      }
    }

    -- lua
    lspconfig.lua_ls.setup {
      -- on_attach = on_attach,
      capabilities = capabilities,
      autostart = true,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" }
          }
        }
      }
    }

    -- C/C++
    lspconfig.clangd.setup {
      -- on_attach = on_attach,
      capabilities = capabilities,
      autostart = true,
    }

    -- Bash LSP
    local configs = require 'lspconfig.configs'
    if not configs.bash_lsp and vim.fn.executable('bash-language-server') == 1 then
      configs.bash_lsp = {
        capabilities = capabilities,
        autostart = true,
        default_config = {
          cmd = { 'bash-language-server', 'start' },
          filetypes = { 'sh' },
          root_dir = require('lspconfig').util.find_git_ancestor,
          init_options = {
            settings = {
              args = {}
            }
          }
        }
      }
    end
    if configs.bash_lsp then
      lspconfig.bash_lsp.setup {}
    end
  end
}
