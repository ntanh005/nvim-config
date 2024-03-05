print "lua.custom.init.lua"

vim.api.nvim_exec(
  [[
augroup jdtls_lsp
    autocmd!
    autocmd FileType java lua require'custom.configs.jdtls_setup'.setup()
augroup end
      ]],
  true
)
