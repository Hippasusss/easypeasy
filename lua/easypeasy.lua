local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")

local M = {}

function M.searchSingleCharacter()
    local key = input.askForKey("Search For Key: ")
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    jump.jumpToKey(highlight.highlightLocations(replace.calculateReplacementCharacters(select.findKeyLocationsInViewPort(key))))
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchMultipleCharacters()
    input.askForString("Search")
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    -- jump.jumpToKey(highlight.highlightLocations(replace.calculateReplacementCharacters()))
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchLines()
end

function M.searchTreesitter()
end

vim.keymap.set('n', '<leader>0', function() vim.cmd("luafile " .. vim.fn.expand("%:p")) end)
vim.keymap.set('n', 's', M.searchSingleCharacter)
vim.keymap.set('n', '/', M.searchMultipleCharacters)
vim.keymap.set('n', '<leader>2', highlight.clearHighlights)
print("loaded easy peasy")

return M

