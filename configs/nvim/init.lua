local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local config_dir = vim.fs.dirname(vim.uv.fs_realpath(source) or source)
local dotfiles = vim.env.DOTFILES

if not dotfiles or dotfiles == '' then
  dotfiles = vim.fs.dirname(vim.fs.dirname(config_dir))
end

local kickstart_dir = vim.fs.joinpath(dotfiles, 'submodules', 'kickstart.nvim')
local kickstart_init = vim.fs.joinpath(kickstart_dir, 'init.lua')

if not vim.uv.fs_stat(kickstart_init) then
  error(('kickstart.nvim is missing at %s; run git submodule update --init --recursive'):format(kickstart_dir))
end

vim.opt.runtimepath:prepend(kickstart_dir)
vim.opt.runtimepath:prepend(config_dir)
dofile(kickstart_init)

require 'custom.plugins'

-- Restore the built-in Space behavior after kickstart uses it as the leader key.
vim.keymap.set({ 'n', 'x', 'o' }, '<Space>', 'l', { desc = 'Move cursor right', nowait = true, silent = true })
