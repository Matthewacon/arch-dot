---@type ChadrcConfig
local M = {}

M.ui = {
 theme = 'tokyonight',
 -- Show nvchad startup dialog
 nvdash = {
  load_on_startup = true
 }
}

-- Load custom plugins
M.plugins = "custom.plugins"

-- Load custom mappings
M.mappings = require "custom.mappings"

-- Load all autocmds
require "custom.autocmds"

-- Load all editor options
require "custom.vimopts"

--[[
 TODO:
  - CoC setup for C/C++
]]

--[[
 TODO: Explore reusing nvchad.ui.cheatsheet to produce project-specific
 cheatsheets on first open with `.nvimrc.lua`
]]

return M
