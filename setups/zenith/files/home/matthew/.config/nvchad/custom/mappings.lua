--[[
 NOTE: Plugins that ship with nvchad by default, such as nvim-treesitter, have
 to be configured in "custom.plugins"
]]

local M = {}

-- Remove highlighted matches
local clear_highlights = {
 ["<C-l>"] = {
  "<CMD>noh<CR>",
  "Clear highlighted matches"
 }
}
M.clear_highlights = {
 i = clear_highlights,
 n = clear_highlights,
 t = clear_highlights,
}

-- Trim trailing whitespace in normal / insert mode
local trim_trailing_whitespace = {
 ["<C-t>"] = {
  function()
   local save = vim.fn.winsaveview()
   vim.cmd([[keeppatterns %s/ \+$//e]])
   vim.fn.winrestview(save)
  end,
  "Trim trailing whitespace"
 }
}
M.trim_trailing_whitespace = {
 i = trim_trailing_whitespace,
 n = trim_trailing_whitespace
}

-- Seek to end / beginning of line with CTRL+ALT+[ARROW] in all modes
local seek = {
 ["<C-M-Left>"] = {
  "<Home>",
  "Seek to beginning of line with arrow keys"
 },
 ["<C-M-Right>"] = {
  "<End>",
  "Seek to end of line with arrow keys"
 }
}
M.seek = {
 i = seek,
 n = seek,
 v = seek,
 t = seek
}

-- Delete word to next whitespace or special character
M.delete_word = {
 n = {
  ["<C-d>"] = {
   "<C-[>daw",
   "Delete word"
  }
 },
 i = {
  ["<C-d>"] = {
   "<C-[>diwi",
   "Delete word"
  }
 }
}

-- Navigating buffers
local buffer_nav = {
 ["<C-Left>"] = {
  "<C-w><Left>",
  "Move to left buffer"
 },
 ["<C-Right>"] = {
  "<C-w><Right>",
  "Move to right buffers"
 },
 ["<C-Up>"] = {
  "<C-w><Up>",
  "Move to above buffer"
 },
 ["<C-Down>"] = {
  "<C-w><Down>",
  "Move to below buffer"
 }
}
M.buffer_nav = {
 n = buffer_nav,
 t = buffer_nav,
 i = {
  ["<C-Left>"] = {
   "<C-\\><C-n><C-w><Left>i",
   "Move to left buffer"
  },
  ["<C-Right>"] = {
   "<C-\\><C-n><C-w><Right>i",
   "Move to right buffers"
  },
  ["<C-Up>"] = {
   "<C-\\><C-n><C-w><Up>i",
   "Move to above buffer"
  },
  ["<C-Down>"] = {
   "<C-\\><C-n><C-w><Down>i",
   "Move to below buffer"
  }
 },
}

--[[
 TODO: Move buffer tabs

 NOTE: nvchad.ui.tabufline needs to be updated to support reordering buffer
 tabs like barbar.nvim
]]
--M.buffer_move = {
-- n = {
--  [""]
-- }
--}

-- Resize buffers
local resize_character_count = 10
local resize_buffers = {
 -- Horizontal resizing
 ["<M-Right>"] = {
  "<CMD>vertical resize -" .. resize_character_count .. "<CR>",
  "Decrease horizontal buffer width by " .. resize_character_count .. " characters"
 },
 ["<M-Left>"] = {
  "<CMD>vertical resize +" .. resize_character_count .. "<CR>",
  "Increase horizontal buffer width by " .. resize_character_count .. " characters"
 },
 -- Vertical resizing
 ["<M-Up>"] = {
  "<CMD>resize -" .. resize_character_count .. "<CR>",
  "Decrease vertical buffer width by " .. resize_character_count .. " characters"
 },
 ["<M-Down>"] = {
  "<CMD>resize +" .. resize_character_count .. "<CR>",
  "Increase vertical buffer width by " .. resize_character_count .. " characters"
 }
}
M.resize_buffers = {
 i = resize_buffers,
 n = resize_buffers
}

-- vim-fugitive mappings
local fugitive = {
 ["<C-b>"] = {
  "<CMD>Git blame<CR>",
  "View git blame for file open in current buffer"
 },
 ["<S-B>"] = {
  "<CMD>Git log %<CR>",
  "View commits for file open in current buffer"
 }
}
M.fugitive = {
 -- NOTE: SHIFT+b in insert mode is a bad idea
 --i = fugitive,
 n = vim.tbl_deep_extend("force", fugitive, {
  -- Close diff, splitdiff and blame panes
  ["<ESC>"] = {
   function()
    local buf_number = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(buf_number)
    local buf_filetype = vim.bo.filetype

    -- Close buffer if it is a vim-fugitive buffer
    local fugitive_filetypes = {
     "fugitiveblame",
     "git"
    }

    --[[
     If the current buffer name starts with `fugitive://`

     TODO: If the current buffer is a splitdiff, close the adjacent pane?
    ]]
    local is_fugitive_buf = buf_name:find("^fugitive://") ~= nil

    -- If the current buffer filetype is in the table above
    for _, value in ipairs(fugitive_filetypes) do
     if buf_filetype == value then
      is_fugitive_buf = true
      break
     end
    end

    -- If it is a vim-fugitive buffer, delete it
    if is_fugitive_buf then
     vim.api.nvim_buf_delete(buf_number, {})
    end
   end,
   "Close vim-fugitive panes"
  },
 })
}

-- todo-comments mappings
local todo = {
  ["<S-T>"] = {
    "<CMD>TodoTelescope<CR>",
    "Open telescope dialog with all comment keywords"
  }
}
M.todo = {
  n = todo
}

return M
