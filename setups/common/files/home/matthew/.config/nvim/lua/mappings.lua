require "nvchad.mappings"

--[[
 NOTE: Plugins that ship with nvchad by default, such as nvim-treesitter, have
 to be configured in "custom.plugins"
]]

local map = vim.keymap.set
local unmap = vim.keymap.del

-- Delete keybinds to interact with line numbers
unmap("n", "<leader>n")
unmap("n", "<leader>rn")

-- Start command by pressing `;` in normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })

-- Remove highlighted matches
map(
 { "i", "n", "t" },
 "<C-l>",
 "<CMD>noh<CR>",
 { desc = "Clear highlighted matches" }
)

-- Trim trailing whitespace in normal / insert mode
map(
 { "i", "n" },
 "<C-t>",
 function()
  local save = vim.fn.winsaveview()
  vim.cmd([[keeppatterns %s/ \+$//e]])
  vim.fn.winrestview(save)
 end,
 { desc = "Trim trailing whitespace" }
)

-- Seek to end / beginning of line with CTRL+ALT+[ARROW] in all modes
map(
 { "i", "n", "v", "t" },
 "<C-M-Left>",
 "<Home>",
 { desc = "Seek to beginning of line with arrow keys" }
)
map(
 { "i", "n", "v", "t" },
 "<C-M-Right>",
 "<End>",
 { desc = "Seek to end of line with arrow keys" }
)

-- Delete word to next whitespace or special character
map(
 "i",
 "<C-d>",
 "<C-[>diwi",
 { desc = "Delete word" }
)
map(
 "n",
 "<C-d>",
 "<C-[>daw",
 { desc = "Delete word" }
)

-- Navigating buffers
local buffer_mappings = {
 left = {
  "<C-Left>",
  "<C-w><Left>",
  { desc = "Move to left buffer" },
 },
 right = {
  "<C-Right>",
  "<C-w><Right>",
  { desc = "Move to right buffer" },
 },
 up = {
  "<C-Up>",
  "<C-w><Up>",
  { desc = "Move to above buffer" },
 },
 down = {
  "<C-Down>",
  "<C-w><Down>",
  { desc = "Move to below buffer" },
 },
}

-- Map normal and terminal mode mappings
for _, v in pairs(buffer_mappings) do
 map({ "n", "t" }, unpack(v))
end

-- Map insert mode mappings
local insert_mode_buffer_mappings = {
 left = {
  "<C-Left>",
  "<C-\\><C-n><C-w><Left>i",
  { desc = "Move to left buffer" }
 },
 right = {
  "<C-Right>",
  "<C-\\><C-n><C-w><Right>i",
  { desc = "Move to right buffer" },
 },
 up = {
  "<C-Up>",
  "<C-\\><C-n><C-w><Up>i",
  { desc = "Move to above buffer" },
 },
 down = {
  "<C-Down>",
  "<C-\\><C-n><C-w><Down>i",
  { desc = "Move to below buffer" },
 },
}
for _, v in pairs(insert_mode_buffer_mappings) do
 map("i", unpack(v))
end

-- Resize buffers
local resize_character_count = 5
local resize_buffers = {
 left = {
  "<M-Left>",
  "<CMD>vertical resize +" .. resize_character_count .. "<CR>",
  { desc = "Increase horizontal buffer width by " .. resize_character_count .. " characters" },
 },
 right = {
  "<M-Right>",
  "<CMD>vertical resize -" .. resize_character_count .. "<CR>",
  { desc = "Decrease horizontal buffer width by " .. resize_character_count .. " characters" },
 },
 up = {
  "<M-Up>",
  "<CMD>resize -" .. resize_character_count .. "<CR>",
  { desc = "Decrease vertical buffer width by " .. resize_character_count .. " characters" },
 },
 down = {
  "<M-Down>",
  "<CMD>resize +" .. resize_character_count .. "<CR>",
  { desc = "Increase vertical buffer width by " .. resize_character_count .. " characters" },
 },
}
for _,v in pairs(resize_buffers) do
 map({ "i", "n" }, unpack(v))
end

-- vim-fugitive mappings
local fugitive = {
 log = {
  "<S-B>",
  "<CMD>Git log %<CR>",
  { desc = "Fugitive view commits for file open in current buffer" },
 },
 blame = {
  "<C-b>",
  "<CMD>Git blame<CR>",
  { desc =  "Fugitive view git blame for file open in current buffer" },
 },
}

-- Map fugitive bindings for normal mode only
for _,v in pairs(fugitive) do
 map("n", unpack(v))
end

-- Map escape to close fugitive buffer, if open
map(
 "n",
 "<ESC>",
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
 { desc = "Fugitive Close vim-fugitive buffer" }
)

-- todo-comments mappings
map(
 "n",
 "<S-T>",
 "<CMD>TodoTelescope<CR>",
 { desc = "Open telescope dialog with all comment keywords" }
)
