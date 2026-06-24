-- Lazy package manager
-- https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    "Mofiqul/dracula.nvim",
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
    "mfussenegger/nvim-lsp-compl"
})

-- LSP
require'lspconfig'.powershell_es.setup{
    bundle_path = 'c:/PowerShellEditorServices',
    shell = 'pwsh.exe',
    --on_attach=require'lsp_compl'.attach
}

require'lspconfig'.csharp_ls.setup{}

-- Lua vim configurations
local o = vim.o
o.expandtab = true -- expand tab input with spaces characters
o.smartindent = true -- syntax aware indentations for newline inserts
o.tabstop = 4 -- num of space characters per tab
o.shiftwidth = 4 -- spaces per indentation level

-- Old vim configurations
vim.cmd([[
    colo dracula

    set encoding=utf-8
    set splitright
    set number relativenumber

    """ Syntax and searchinng
    syntax on
    set hlsearch
    set showmatch
    set ignorecase
    set incsearch

    """ Text wrapping and width
    set wrap
    set textwidth=80
    set colorcolumn=81

    """ Remove annoying Q macro key
    nnoremap Q q
    nnoremap q <Nop>
]])
