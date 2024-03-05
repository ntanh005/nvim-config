local M = {}

function M.setup()
  local on_attach = function(client, bufnr)
    require("jdtls.setup").add_commands()
    require("jdtls").setup_dap()
    require("lsp-status").register_progress()
    require("compe").setup {
      enabled = true,
      autocomplete = true,
      debug = false,
      min_length = 1,
      preselect = "enable",
      throttle_time = 80,
      source_timeout = 200,
      incomplete_delay = 400,
      max_abbr_width = 100,
      max_kind_width = 100,
      max_menu_width = 100,
      documentation = true,

      source = {
        path = true,
        buffer = true,
        calc = true,
        vsnip = false,
        nvim_lsp = true,
        nvim_lua = true,
        spell = true,
        tags = true,
        snippets_nvim = false,
        treesitter = true,
      },
    }

    require("lspkind").init()
    require("lspsaga").init_lsp_saga()

    -- Kommentary
    vim.api.nvim_set_keymap("n", "<leader>/", "<plug>kommentary_line_default", {})
    vim.api.nvim_set_keymap("v", "<leader>/", "<plug>kommentary_visual_default", {})

    require("formatter").setup {
      filetype = {
        java = {
          function()
            return {
              exe = "java",
              args = {
                "-jar",
                os.getenv "HOME" .. "/.local/jars/google-java-format.jar",
                vim.api.nvim_buf_get_name(0),
              },
              stdin = true,
            }
          end,
        },
      },
    }

    vim.api.nvim_exec(
      [[
        augroup FormatAutogroup
          autocmd!
          autocmd BufWritePost *.java FormatWrite
        augroup end
      ]],
      true
    )

    local function buf_set_keymap(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local function buf_set_option(...)
      vim.api.nvim_buf_set_option(bufnr, ...)
    end

    buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings.
    local opts = { noremap = true, silent = true }
    buf_set_keymap("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    buf_set_keymap("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
    buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
    buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    buf_set_keymap("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
    buf_set_keymap("n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
    buf_set_keymap("n", "<leader>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
    buf_set_keymap("n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    buf_set_keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    buf_set_keymap("n", "gr", '<cmd>lua vim.lsp.buf.references() && vim.cmd("copen")<CR>', opts)
    buf_set_keymap("n", "<leader>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
    buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
    buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
    buf_set_keymap("n", "<leader>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
    -- Java specific
    buf_set_keymap("n", "<leader>di", "<Cmd>lua require'jdtls'.organize_imports()<CR>", opts)
    buf_set_keymap("n", "<leader>dt", "<Cmd>lua require'jdtls'.test_class()<CR>", opts)
    buf_set_keymap("n", "<leader>dn", "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", opts)
    buf_set_keymap("v", "<leader>de", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
    buf_set_keymap("n", "<leader>de", "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
    buf_set_keymap("v", "<leader>dm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)

    buf_set_keymap("n", "<leader>cf", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

    vim.api.nvim_exec(
      [[
          hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
          augroup lsp_document_highlight
            autocmd!
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
          augroup END
      ]],
      false
    )
  end

  local root_markers = { "gradlew", "pom.xml" }
  local root_dir = require("jdtls.setup").find_root(root_markers)
  local home = os.getenv "HOME"

  local capabilities = {
    workspace = {
      configuration = true,
    },
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  }

  local workspace_folder = home .. "/.workspace" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
  local config = {
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = capabilities,
    on_attach = on_attach,
  }

  config.settings = {
    ["java.format.settings.url"] = home .. "/.config/nvim/language-servers/java-google-formatter.xml",
    ["java.format.settings.profile"] = "GoogleStyle",
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
      },
      configuration = {
        -- runtimes = {
        --   {
        --     name = "JavaSE-11",
        --     path = home .. "/.sdkman/candidates/java/11.0.10-open/",
        --   },
        --   {
        --     name = "JavaSE-14",
        --     path = home .. "/.sdkman/candidates/java/14.0.2-open/",
        --   },
        --   {
        --     name = "JavaSE-15",
        --     path = home .. "/.sdkman/candidates/java/15.0.1-open/",
        --   },
        -- },
      },
    },
  }

  local path_to_mason_packages = home .. "/.local/share/nvim/mason/packages"
  local path_to_jdtls = path_to_mason_packages .. "/jdtls"
  local path_to_jdebug = path_to_mason_packages .. "/java-debug-adapter"
  local path_to_jtest = path_to_mason_packages .. "/java-test"

  local os
  if vim.fn.has "macunix" then
    os = "mac"
  elseif vim.fn.has "win32" then
    os = "win"
  else
    os = "linux"
  end
  local path_to_config = path_to_jdtls .. "/config_" .. os
  print("path to config: " .. path_to_config)

  local lombok_path = path_to_jdtls .. "/lombok.jar"

  -- 💀
  local path_to_jar = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar")
  print("local path" .. path_to_jar)
  local bundles = {
    vim.fn.glob(path_to_jdebug .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
  }

  vim.list_extend(bundles, vim.split(vim.fn.glob(path_to_jtest .. "/extension/server/*.jar", true), "\n"))

  config.cmd = {
    --
    -- 				-- 💀
    "java", -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "-javaagent:" .. lombok_path,
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",

    -- 💀
    "-jar",
    path_to_jar,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
    -- Must point to the                                                     Change this to
    -- eclipse.jdt.ls installation                                           the actual version

    -- 💀
    "-configuration",
    path_to_config,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
    -- Must point to the                      Change to one of `linux`, `win` or `mac`
    -- eclipse.jdt.ls installation            Depending on your system.

    -- 💀
    -- See `data directory configuration` section in the README
    "-data",
    workspace_folder,
  }
  config.on_attach = on_attach
  config.on_init = function(client, _)
    client.notify("workspace/didChangeConfiguration", { settings = config.settings })
  end

  -- local jar_patterns = {
  --     '/dev/microsoft/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
  --     '/dev/dgileadi/vscode-java-decompiler/server/*.jar',
  --     '/dev/microsoft/vscode-java-test/server/*.jar',
  -- }

  -- local bundles = {}
  -- for _, jar_pattern in ipairs(jar_patterns) do
  --   for _, bundle in ipairs(vim.split(vim.fn.glob(home .. jar_pattern), '\n')) do
  --     if not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar') then
  --       table.insert(bundles, bundle)
  --     end
  --   end
  -- end

  local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
  config.init_options = {
    -- bundles = bundles;
    extendedClientCapabilities = extendedClientCapabilities,
  }

  -- UI
  local finders = require "telescope.finders"
  local sorters = require "telescope.sorters"
  local actions = require "telescope.actions"
  local pickers = require "telescope.pickers"
  require("jdtls.ui").pick_one_async = function(items, prompt, label_fn, cb)
    local opts = {}
    pickers
      .new(opts, {
        prompt_title = prompt,
        finder = finders.new_table {
          results = items,
          entry_maker = function(entry)
            return {
              value = entry,
              display = label_fn(entry),
              ordinal = label_fn(entry),
            }
          end,
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr)
          actions.goto_file_selection_edit:replace(function()
            local selection = actions.get_selected_entry(prompt_bufnr)
            actions.close(prompt_bufnr)

            cb(selection.value)
          end)

          return true
        end,
      })
      :find()
  end

  -- Server
  require("jdtls").start_or_attach(config)

  -- NOTE: Java specific keymaps with which key
  vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)"
  vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_set_runtime JdtSetRuntime lua require('jdtls').set_runtime(<f-args>)"
  vim.cmd "command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()"
  vim.cmd "command! -buffer JdtJol lua require('jdtls').jol()"
  vim.cmd "command! -buffer JdtBytecode lua require('jdtls').javap()"
  vim.cmd "command! -buffer JdtJshell lua require('jdtls').jshell()"

  local status_ok, which_key = pcall(require, "which-key")
  if not status_ok then
    return
  end

  local opts = {
    mode = "n", -- NORMAL mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
  }

  local vopts = {
    mode = "v", -- VISUAL mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
  }

  local mappings = {
    J = {
      name = "Java",
      o = { "<Cmd>lua require'jdtls'.organize_imports()<CR>", "Organize Imports" },
      v = { "<Cmd>lua require('jdtls').extract_variable()<CR>", "Extract Variable" },
      c = { "<Cmd>lua require('jdtls').extract_constant()<CR>", "Extract Constant" },
      t = { "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", "Test Method" },
      T = { "<Cmd>lua require'jdtls'.test_class()<CR>", "Test Class" },
      u = { "<Cmd>JdtUpdateConfig<CR>", "Update Config" },
    },
  }

  local vmappings = {
    J = {
      name = "Java",
      v = { "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", "Extract Variable" },
      c = { "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", "Extract Constant" },
      m = { "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", "Extract Method" },
    },
  }

  which_key.register(mappings, opts)
  which_key.register(vmappings, vopts)

  require("core.utils").load_mappings("lspconfig")
  -- If you want you can add here Old School Mappings. Me I setup Telescope, LSP and Lspsaga mapping somewhere else and I just reuse them

  -- vim.keymap.set("gI", vim.lsp.buf.implementation,{ desc = "[G]oto [I]mplementation" })
  -- vim.keymap.set("<leader>D", vim.lsp.buf.type_definition,{ desc = "Type [D]efinition" })
  -- vim.keymap.set("<leader>hh", vim.lsp.buf.signature_help,{ desc = "Signature [H][H]elp Documentation" })

  -- vim.keymap.set("gD", vim.lsp.buf.declaration,{ desc = "[G]oto [D]eclaration" })
  -- vim.keymap.set("<leader>wa", vim.lsp.buf.add_workspace_folder,{ desc = "[W]orkspace [A]dd Folder" })
  -- vim.keymap.set("<leader>wr", vim.lsp.buf.remove_workspace_folder,{ desc = "[W]orkspace [R]emove Folder" })
  -- vim.keymap.set("<leader>wl", function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, "[W]orkspace [L]ist Folders")

  -- Create a command `:Format` local to the LSP buffer
  -- vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
  --   vim.lsp.buf.format()
  -- end, { desc = "Format current buffer with LSP" })

  -- vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "[G]oto [R]eferences - Java", expr = true, silent = true })
  -- vim.keymap.set("n","gr", require("telescope.builtin").lsp_references,{ desc = "[G]oto [R]eferences" })
  -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "" })
  -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "" })
  -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "" })
  -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = "" })
  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = "" })
  -- vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { desc = "" })
  -- vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { desc = "" })
  -- vim.keymap.set('n', '<leader>wl', print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', { desc = "" })
  -- vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, { desc = "" })
  -- vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "" })
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references() && vim.cmd("copen")<CR>', { desc = "" })
  -- vim.keymap.set('n', '<leader>e', vim.lsp.diagnostic.show_line_diagnostics, { desc = "" })
  -- vim.keymap.set('n', '[d', vim.lsp.diagnostic.goto_prev, { desc = "" })
  -- vim.keymap.set('n', ']d', vim.lsp.diagnostic.goto_next, { desc = "" })
  -- vim.keymap.set('n', '<leader>q', vim.lsp.diagnostic.set_loclist, { desc = "" })

  -- -- Java specific
  -- vim.keymap.set("n", "<leader>di", "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = "" })
  -- vim.keymap.set("n", "<leader>dt", "<Cmd>lua require'jdtls'.test_class()<CR>", { desc = "" })
  -- vim.keymap.set("n", "<leader>dn", "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", { desc = "" })
  -- vim.keymap.set("v", "<leader>de", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = "" })
  -- vim.keymap.set("n", "<leader>de", "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = "" })
  -- vim.keymap.set("v", "<leader>dm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = "" })
  --
  -- vim.keymap.set("n", "<leader>cf", "<cmd>lua vim.lsp.buf.formatting()<CR>", { desc = "" })
end

return M
