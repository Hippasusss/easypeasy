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

--FIXME: fix enter without match needs another enter press
function M.searchMultipleCharacters()
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    local replacementLocations = highlight.InteractiveSearch()
    if replacementLocations then
        local bufferJumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
        local relativeJumplocations = select.makeAbsoluteLocationsRelative(bufferJumplocations)
        local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(relativeJumplocations)
        if replacementLocationsWithCharacters then
            jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
        end
    else
        vim.api.nvim_echo({{'Exited', 'WarningMsg'}}, true, {})
        highlight.toggle_grey_text() -- not sure why this needs called twice
    end
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchLines()
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    local replacementLocations = select.findAllVisibleLineStarts()
    if replacementLocations then
        local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(replacementLocations)
        if replacementLocationsWithCharacters then
            jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
        end
    else
        vim.api.nvim_echo({{'Exited', 'WarningMsg'}}, true, {})
        highlight.toggle_grey_text() -- not sure why this needs called twice
    end
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

return M

