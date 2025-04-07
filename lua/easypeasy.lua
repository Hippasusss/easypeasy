local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")
local helper = require("helper")
local treeSitterSearch = require("treeSitterSearch")

local M = {}

local function executeSearch(getLocationsFn, postProcessFn, restore_cursor)
    highlight.toggle_grey_text()

    restore_cursor = false or restore_cursor
    local scrolloff = vim.opt.scrolloff
    if restore_cursor then
        vim.opt.scrolloff = 0
    end
    local original_pos = restore_cursor and vim.api.nvim_win_get_cursor(0) or nil

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
    if restore_cursor and original_pos then
        pcall(vim.api.nvim_win_set_cursor, 0, original_pos)
        vim.opt.scrolloff = scrolloff
    end
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

function M.selectTreeSitter(returnCursor)
    returnCursor = returnCursor or false
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(treeSitterSearch.searchFor)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.visuallySelectNodeAtLocation({location.lineNum, location.colNum})
        end, returnCursor)
end

function M.yankTreeSitter(returnCursor)
    returnCursor = returnCursor or true
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(treeSitterSearch.searchFor)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.yankNodeAtStartLocation({location.lineNum, location.colNum})
        end, returnCursor)
end

function M.deleteTreeSitter(returnCursor)
    returnCursor = returnCursor or true
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(treeSitterSearch.searchFor)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.deleteNodeAtStartLocation({location.lineNum, location.colNum})
        end, returnCursor)
end

function M.commandTreeSitter(command, returnCursor)
    returnCursor = returnCursor or true
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(treeSitterSearch.searchFor)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.deleteNodeAtStartLocation({location.lineNum, location.colNum})
        end, returnCursor)
end
return M

