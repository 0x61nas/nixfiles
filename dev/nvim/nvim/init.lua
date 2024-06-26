-- Global Settings And Remaps
require('settings')
require('keybinds')
require('autocommands')
if vim.g.neovide then
  require('neovide')
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
        lazypath
    })
end

vim.opt.rtp:prepend(lazypath)

return require('lazy').setup('plugins')
