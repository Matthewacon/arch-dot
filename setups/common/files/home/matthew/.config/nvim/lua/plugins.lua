local plugins = {
 -- Load NvChad
 {
  "NvChad/NvChad",
  lazy = false,
  -- branch = "v2.5",
  commit = "0496016e188e294ba09dde41914b83800a9fa9ca",
  import = "nvchad.plugins",
  config = function()
   require "options"
  end,
 },
 -- Add todo-comments for easy highlighting and navigation of comment keywords
 {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = false,
  opts = function()
   return {
    -- keywords recognized as todo comments
    keywords = {
     FIX = {
      icon = "󰁨 ",
      color = "#E27171",
      alt = { "FIXME", "FIXIT", "ISSUE" },
     },
     BUG = { icon = " ", color = "#DC2626" },
     TODO = { icon = " ", color = "#C6A9D9" },
     HACK = { icon = " ", color = "#FBBF24" },
     WARN = { icon = " ", color = "#FBBF24", alt = { "WARNING", "XXX" } },
     PERF = { icon = " ", color = "#81D8D0", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
     NOTE = { icon = " ", color = "#8660A9", alt = { "INFO" } },
     TEST = { icon = "󰺧 ", color = "#10B981", alt = { "TESTING", "PASSED", "FAILED" } },
     DEBUG = { icon = " ", color = "#ADC0C4" },
    },
    gui_style = {
     fg = "BOLD",
     bg = "NONE",
    },
    highlight = {
     before = "",
     after = "",
     keyword = "fg",
     comments_only = true,
     pattern = [[.*<(KEYWORDS)\s*:]],
    },
    search = {
     command = "rg",
     args = {
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
     },
     -- regex that will be used to match keywords.
     -- don't replace the (KEYWORDS) placeholder
     pattern = [[\b(KEYWORDS):]], -- ripgrep regex
     -- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
    },
   }
  end
 },
 -- Add support for auto formatting files
 {
  "stevearc/conform.nvim",
  -- event = 'BufWritePre', -- uncomment for format on save
  config = function()
   require "configs.conform"
  end,
 },
 {
  "neovim/nvim-lspconfig",
  config = function()
   require("nvchad.configs.lspconfig").defaults()
   require "configs.lspconfig"
  end,
 },
 -- Configure mason LSP server support
 {
  "williamboman/mason.nvim",
  opts = {
   ensure_installed = {
    "lua-language-server",
    "python-lsp-server",
    "typescript-language-server",
    "html-lsp",
    "prettier",
    "stylua"
   },
  },
 },
 -- Configure telescope to show hidden files
 {
  "telescope.nvim",
  lazy = true,
  opts = function()
   local config = {
    -- Include hidden files in file finder
    pickers = {
     find_files = {
      hidden = true,
      follow = true
     }
    },
    defaults = {
     -- Ignore specific file path
     file_ignore_patterns = {
      ".git/branches/*",
      ".git/info/*",
      ".git/logs/*",
      ".git/objects/*",
      ".git/refs/*",
      ".git/hooks/.*%.sample",
      ".git/packed%-refs",
      ".git/index",
      ".git/shallow",
     },
     -- Exit nvim-telescope panes when `ESC` is pressed in insert mode
     mappings = {
      i = {
       ['<ESC>'] = require("telescope.actions").close
      }
     }
    }
   }

   -- Merge custom config with nvchad defaults
   local nvchad_defaults = require("nvchad.configs.telescope")
   return vim.tbl_deep_extend("force", nvchad_defaults, config)
  end
 },
 -- Configure nvim-tree to show hidden and `.gitignore`'d files
 {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  opts = function()
   local config = {
    filters = {
     dotfiles = false,
    },
    git = {
     enable = true,
     ignore = false,
    },
   }

   local nvchad_defaults = require "nvchad.configs.nvimtree"
   return vim.tbl_deep_extend("force", nvchad_defaults, config)
  end,
  config = function(_, opts)
   dofile(vim.g.base46_cache .. "nvimtree")
   require("nvim-tree").setup(opts)
  end,
 },
 -- Configure nvim treesitter language support
 {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  opts = {
   ensure_installed = "all",
   auto_install = true,
   highlight = {
    enable = true,
    additional_vim_regex_highlighting = true
   },
   incremental_selection = true
  }
 },
 -- Add vim-fugitive for git blame panes
 {
  "tpope/vim-fugitive",
  lazy = false,
  config = function()
   return {}
  end
 },
 -- Add trouble.nvim to view all issues in a buffer inside a telescope pane
 --[[TODO:
  - Move keybinds to `lua/mappings.lua`
  - Configure telescope panes
  - Change `<leader>x...` mappings to not overlap with buffer delete
 ]]
 {
  "folke/trouble.nvim",
  opts = {}, -- for default options, refer to the configuration section for custom setup.
  cmd = "Trouble",
  keys = {
   {
    "<leader>xx",
    "<cmd>Trouble diagnostics toggle<cr>",
    desc = "Telescope (Trouble) Diagnostics",
   },
   {
    "<leader>xX",
    "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
    desc = "Telescope (Trouble) Buffer diagnostics",
   },
   {
    "<leader>cs",
    "<cmd>Trouble symbols toggle focus=false<cr>",
    desc = "Telescope (Trouble) Symbols",
   },
   {
    "<leader>cl",
    "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
    desc = "Telescope (Trouble) LSP definitions / references / ...",
   },
   {
    "<leader>xL",
    "<cmd>Trouble loclist toggle<cr>",
    desc = "Telescope (Trouble) Location list",
   },
   {
    "<leader>xQ",
    "<cmd>Trouble qflist toggle<cr>",
    desc = "Telescope (Trouble) Quickfix list",
   },
  },
 }
}

-- Initialize all plugins
require("lazy").setup(plugins, require("configs.lazy"))
