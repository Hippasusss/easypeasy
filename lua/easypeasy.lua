local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")
local helper = require("helper")
local treeSitterSearch = require("treeSitterSearch")

local M = {}

local function executeSearch(getLocationsFn, postProcessFn)
    highlight.toggle_grey_text()
    local success, replacementLocations = pcall(getLocationsFn)
    local ok, err = pcall(function()
        if success and replacementLocations then
            local bufferJumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
            bufferJumplocations = select.trimLocationsToWindow(bufferJumplocations)
            local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(bufferJumplocations)

            if replacementLocationsWithCharacters then
                local location = jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
                if postProcessFn then
                    postProcessFn(location)
                end
            end
        else
            vim.api.nvim_echo({{success and 'Exited' or 'Error: '..tostring(replacementLocations), 'WarningMsg'}}, true, {})
        end
    end)
    highlight.toggle_grey_text()
end

function M.searchSingleCharacter()
    executeSearch(function()
        local key = input.askForKey("Search For Key: ")
        return select.findKeyLocationsInViewPort(key)
    end)
end

function M.searchMultipleCharacters()
    executeSearch(highlight.InteractiveSearch)
end

function M.searchLines()
    executeSearch(select.findAllVisibleLineStarts)
end

function M.selectTreeSitter()
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(treeSitterSearch.searchFor)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.visuallySelectNodeAtLocaiton({location.lineNum, location.colNum})
        end)
end

vim.keymap.set("n", "<leader>t", function() require("easypeasy").selectTreeSitter() end)

return M

