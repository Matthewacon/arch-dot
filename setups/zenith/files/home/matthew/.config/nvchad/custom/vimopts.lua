-- Set tab with to 1 space globally
vim.opt.tabstop = 1
-- Set autoindent width to 1 space globally
vim.opt.shiftwidth = 1
-- Always expand tabs
vim.opt.expandtab = true
-- Enable smart indent so indent detection works
vim.opt.smartindent = true
-- Disable auto indent
vim.opt.autoindent = false
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
vim.opt.foldmethod = "syntax"
-- Enable usage of `.nvimrc.lua` files for directory-specific configurations, see next option for security implications
vim.opt.exrc = true
-- Disable shell and write commands in `.nvimrc` files
vim.opt.secure = true

return {}
