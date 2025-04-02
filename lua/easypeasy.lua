local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")
local helper = require("helper")

local M = {}

function M.searchSingleCharacter()
    local key = input.askForKey("Search For Key: ")
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    local jumpLocationInfo= select.findKeyLocationsInViewPort(key)
    if #jumpLocationInfo.locations > 0 then
        jump.jumpToKey(highlight.highlightJumpLocations(replace.calculateReplacementCharacters(jumpLocationInfo)))
    else
	vim.api.nvim_echo({{'No Matches!', 'WarningMsg'}}, true, {})
    end
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

--FIXME: fix error on esacpe
--FIXME: fix enter without match needs another enter press
--TODO: Tab to next page of searches
--TODO: Automatically page down/up if no matches on current page
function M.searchMultipleCharacters()
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    local replacementLocations = highlight.InteractiveSearch()
    local bufferJumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
    local relativeJumplocations = select.makeAbsoluteLocationsRelative(bufferJumplocations)
    print("================================")
    print(vim.inspect(relativeJumplocations))
    local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(relativeJumplocations)
    if replacementLocationsWithCharacters then
        jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
    end
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchLines()
end

function M.searchTreesitter()
end


-- vim.keymap.set('n', '<leader>0', function() vim.cmd("luafile " .. vim.fn.expand("%:p")) end)
vim.keymap.set('n', 's', M.searchSingleCharacter)
vim.keymap.set('n', '<space>', M.searchMultipleCharacters)
vim.keymap.set('n', '<leader>2', highlight.clearHighlights)
print("loaded easy peasy")
-- holymoly

return M

