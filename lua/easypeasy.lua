local highlight = require("easypeasy.highlight")
local select = require("easypeasy.select")
local replace = require("easypeasy.replace")
local jump = require("easypeasy.jump")
local input = require("easypeasy.input")
local treeSitterSearch = require("easypeasy.treeSitterSearch")
local config = require("easypeasy.config")

local M = {}

--- Execute a search operation with optional post-processing
--- @param getLocationsFn function Function that returns locations to search
--- @param postProcessFn function|nil Optional function to process selected location
--- @param restore_cursor boolean|nil Whether to restore cursor position (default: false)
local function executeSearch(getLocationsFn, postProcessFn, restore_cursor)
    highlight.toggle_grey_text()

    restore_cursor = false or restore_cursor
    local scrolloff = vim.opt.scrolloff
    if restore_cursor then vim.opt.scrolloff = 0 end
    local original_pos = vim.api.nvim_win_get_cursor(0)

    local success, replacementLocations = pcall(getLocationsFn)

    local ok, err = pcall(function()
        if success and replacementLocations then
            local bufferJumplocations = select.createJumpLocations(replacementLocations)
            bufferJumplocations = select.trimLocationsToWindow(bufferJumplocations)
            local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(bufferJumplocations)

            if replacementLocationsWithCharacters then
                local key = highlight.highlightJumpLocations(replacementLocationsWithCharacters)
                local location = jump.jumpToKey(key)
                if postProcessFn then postProcessFn(location) end
            end
        else
            vim.api.nvim_echo({{success and 'Exited' or 'Error: '..tostring(replacementLocations), 'WarningMsg'}}, true, {})
        end
    end)

    -- return the cursor if requested or if the user escapes mid search
    if (restore_cursor and original_pos) or (replacementLocations == nil) then
        print("here")
        vim.opt.scrolloff = scrolloff
        pcall(vim.api.nvim_win_set_cursor, 0, original_pos)
    end
    highlight.toggle_grey_text()
    if not ok then return err end
end

--- Search for a single character in viewport
--- @return nil
function M.searchSingleCharacter()
    executeSearch(function()
        local key = input.askForKey("Search For Key: ")
        print(vim.inspect(key))
        return select.findKeyLocationsInViewPort(key)
    end)
end

--- Search for multiple characters interactively
--- @return nil
function M.searchMultipleCharacters()
    executeSearch(highlight.InteractiveSearch)
end

--- Search for all visible line starts
--- @return nil
function M.searchLines()
    executeSearch(select.findAllVisibleLineStarts)
end

--- Select Tree-sitter node matching search criteria
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: false)
--- @return nil
function M.selectTreeSitter(returnCursor)
    returnCursor = returnCursor or false
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.visuallySelectNodeAtLocation({location.lineNum, location.colNum})
        end, returnCursor)
end

--- Execute command on Tree-sitter node matching search criteria
--- @param command string The command to execute
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: true)
--- @return nil
function M.commandTreeSitter(command, returnCursor)
    returnCursor = returnCursor or true
    executeSearch(function()
        local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter)
        return treeSitterSearch.getNodeLocations(replacementNodes)
    end, function(location)
            treeSitterSearch.commandNodeAtStartLocation({location.lineNum, location.colNum}, command)
        end, returnCursor)
end

function M.setup(opts)
    config.setAllOptions(opts)
end
return M
