---@type ChadrcConfig
local M = {}

M.ui = {
 theme = 'tokyonight',
 transparency = false,
 -- Show nvchad startup dialog
 nvdash = {
  load_on_startup = true
 }
}

--[[Set up all autocmds]]
local autocmd = vim.api.nvim_create_autocmd

-- Disable line numbers in all terminal buffers
autocmd(
 {
  "TermOpen",
  "TermEnter",
 },
 {
  callback = function()
   vim.cmd([[setlocal nonumber norelativenumber]])
  end
 }
)

-- TODO: Set foldmethod=syntax for git and fugitive buffers only

-- TODO: Automatically highlight trailing whitespace in buffers
--local counter = 0
--autocmd(
-- {
--  "BufWinEnter",
--  "WinEnter",
--  "InsertEnter",
--  "InsertLeave",
--  "BufAdd",
--  "BufNew",
--  "BufNewFile",
--  "WinNew",
--  "BufEnter",
-- },
-- {
--  pattern = "<buffer>",
--  callback = function()
--   counter = counter + 1
--   vim.pretty_print("match: " .. counter .. " " .. vim.inspect(vim.bo.filetype))
--
--   -- Do not highlight trailing whitespace in terminal buffers
--   if vim.bo.filetype == "terminal" then
--    return
--   end
--
--   vim.cmd([[match Error /\s\+\%#\@<!$/]])
--   --vim.cmd([[]])
--  end
--  --command = [[match Error /\s\+\%#\@<!$/]]
-- }
--)
--
----[[
-- TODO: Clear matches for whitespace group on:
--  - CmdWinEnter
--  - CmdWinLeave
--  - All non-file buffer windows
--]]
--
----local clear_counter = 0
----autocmd(
---- "BufWinLeave",
---- {
----  pattern = "<buffer>",
----  callback = function()
----   clear_counter = clear_counter + 1
----   vim.pretty_print("clear: " .. clear_counter .. vim.inspect(vim.bo.filetype))
----   -- Do not auto clear matches in terminal buffers
----   if vim.bo.filetype == "terminal" then
----    return
----   end
----
----   vim.cmd([[call clearmatches()]])
----  end
----  --command = [[call clearmatches()]]
---- }
----)

--[[Set up all editor options]]
-- Set tab with to 1 space globally
vim.opt.tabstop = 1
-- Set autoindent width to 1 space globally
vim.opt.shiftwidth = 1
-- Always expand tabs
vim.opt.expandtab = true
vim.cmd([[
 set noautoindent
 set nosmartindent
 set nocindent
 set indentexpr=
 filetype indent off
]])
-- Always keep at least 8 lines above and below cursor
vim.opt.scrolloff = 8
-- Always keep at least 15 characters to the left and right of the cursor
vim.opt.sidescrolloff = 15
-- Highlight the 80th column in buffers as a soft 80-column text limit
vim.opt.colorcolumn = "80"
-- Highlight all matches when searching
vim.opt.showmatch = true
-- Do not seek to the beginning of the line when `gg` in normal mode
vim.opt.startofline = false
-- Disable line wrapping
vim.opt.wrap = false
-- Enable mouse usage in all modes
vim.opt.mouse = "a"
-- Enable splitdiffs for vim-fugitive
--vim.opt.foldmethod = "syntax"
-- Enable usage of `.nvimrc.lua` files for directory-specific configurations, see next option for security implications
vim.opt.exrc = true
-- Disable shell and write commands in `.nvimrc` files
vim.opt.secure = true

--[[
 Configure todo-comments colours

 NOTE:
  - Check what highlight groups affect the character under the cursor with
    `:Inspect`
  - Debug conflicting highlight groups with `:Telescope highlights`
  - All highlight groups added by todo-comments start with `Todo...`
]]
function clear_conflicting_highlights()
 -- Clear all TODO keyword highlights that are not added by todo-comments
 vim.cmd([[
  hi Todo guifg=NONE guibg=NONE
  hi @comment.todo guifg=NONE guibg=NONE
  hi @text.todo guifg=NONE guibg=NONE
  hi luaTodo guifg=NONE guibg=NONE
 ]])

 -- Clear all WARN keyword highlights that are not added by todo-comments
 vim.cmd([[
  hi @comment.warning guifg=NONE guibg=NONE
 ]])

 -- Clear all NOTE keyword highlights that are not added by todo-comments
 vim.cmd([[
  hi @comment.note guifg=NONE guibg=NONE
  hi @comment.note.comment guifg=NONE guibg=NONE
 ]])
end

-- Clear conflicting highlights on start
clear_conflicting_highlights()

-- Clear conflicting highlights when switching buffers
autocmd(
 {
  "BufEnter",
  "BufWinEnter",
  "BufLeave",
  "BufWinLeave"
 },
 {
  callback = clear_conflicting_highlights
 }
)

-- Underline all todo-comments highlight groups
function add_highlight_underlines()
 local todo_comments_highlights = {
  "FIX",
  "BUG",
  "TODO",
  "HACK",
  "WARN",
  "PERF",
  "NOTE",
  "TEST",
  "DEBUG",
 }
 for _, v in pairs(todo_comments_highlights) do
  local hl_name = "TodoFg"..v
  local existing = vim.api.nvim_get_hl_by_name(hl_name, true)
  vim.api.nvim_set_hl(
   0,
   hl_name,
   vim.tbl_deep_extend("force", existing, { underline = true })
  )
 end
end
--[[
 NOTE: need to delay some time after start for todo-comments plugin init to
 finish
]]
vim.loop.new_timer():start(250, 0, vim.schedule_wrap(add_highlight_underlines))

--[[
 TODO:
  - CoC setup for C/C++
]]

--[[
 TODO: Explore reusing nvchad.ui.cheatsheet to produce project-specific
 cheatsheets on first open with `.nvimrc.lua`
]]

return M
