local plugins = {
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
   local nvchad_defaults = require("plugins.configs.telescope")
   return vim.tbl_deep_extend("force", nvchad_defaults, config)
  end
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
 -- Disable auto insert mode for nvterm
 {
  "nvterm",
  opts = {
   behavior = {
    auto_insert = false
   }
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
 -- Add todo-comments for easy highlighting and navigation of comment keywords
 -- TODO: Remove weird bg behind keyword text; fix highlight colour for TODO to match theme
 {
  "folke/todo-comments.nvim",
  after = "base46",
  lazy = false,
  opts = {
   highlight = {
    before = "",
    after = "",
    keyword = "fg"
   },
  }
 }
}

return plugins
