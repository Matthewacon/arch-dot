local autocmd = vim.api.nvim_create_autocmd

-- Disable line numbers in all terminal buffers
autocmd(
 {
  "TermOpen",
  "TermEnter",
 },
 {
  command = [[setlocal nonumber norelativenumber]]
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

return {}
