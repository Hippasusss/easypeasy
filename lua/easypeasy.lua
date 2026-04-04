local highlight = require("easypeasy.highlight")
local select = require("easypeasy.select")
local replace = require("easypeasy.replace")
local jump = require("easypeasy.jump")
local input = require("easypeasy.input")
local treeSitterSearch = require("easypeasy.treeSitterSearch")
local config = require("easypeasy.config")

local M = {}

--- Gather matches across all visible windows
--- @param matchFn function Function that returns matches for a specific window
--- @return table List of all matches
local function gatherMatchesAcrossWindows(matchFn)
    local allMatches = {}
    local windows = {}
    if config.options.multiWindowSupport then
        windows = vim.api.nvim_tabpage_list_wins(0)
    else
        windows = {vim.api.nvim_get_current_win()}
    end
    for _, win in ipairs(windows) do
        local win_matches = matchFn(win)
        for _, match in ipairs(win_matches or {}) do
            table.insert(allMatches, match)
        end
    end
    return allMatches
end

--- Execute a search operation with optional post-processing
--- @param getLocationsFn function Function that returns locations to search
--- @param postProcessFn function|nil Optional function to process selected location
--- @param restore_cursor boolean|nil Whether to restore cursor position (default: false)
local function executeSearch(getLocationsFn, postProcessFn, restore_cursor)
    highlight.toggle_grey_text()

    restore_cursor = restore_cursor or false
    local scrolloff = vim.opt.scrolloff
    if restore_cursor then vim.opt.scrolloff = 0 end
    local original_pos = vim.api.nvim_win_get_cursor(0)
    local original_win = vim.api.nvim_get_current_win()

    local success, replacementLocations = pcall(getLocationsFn)

    local ok, err = pcall(
        function()
        if success and replacementLocations then
            local bufferJumplocations = select.createJumpLocations(replacementLocations)
            local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(bufferJumplocations)

            if replacementLocationsWithCharacters then
                local key = highlight.highlightJumpLocations(replacementLocationsWithCharacters)
                local location = jump.jumpToKey(key)
                if postProcessFn then postProcessFn(location) end
            end
        else
            if not success then
                vim.api.nvim_echo({{'Error: '..tostring(replacementLocations), 'WarningMsg'}}, true, {})
            end
        end
    end)

    -- return the cursor if requested or if the user escapes mid search
    if (restore_cursor and original_pos) or (replacementLocations == nil) then
        vim.opt.scrolloff = scrolloff
        pcall(vim.api.nvim_set_current_win, original_win)
        pcall(vim.api.nvim_win_set_cursor, original_win, original_pos)
    end
    highlight.toggle_grey_text()
    if not ok then return err end
end

--- Search for a single character in viewport
--- @return nil
function M.searchSingleCharacter()
    executeSearch(
        function()
            local key = input.askForKey("Search For Key: ")
            if not key then return nil end
            return gatherMatchesAcrossWindows(
                function(win)
                    return select.findKeyLocationsInViewPort(key, win)
                end)
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
    executeSearch(
        function()
            return gatherMatchesAcrossWindows(select.findAllVisibleLineStarts)
        end)
end

--- Shared logic for Tree-sitter searches
--- @param postProcess function Action to perform on selected location
--- @param restore_cursor boolean|nil Whether to return cursor to original position
local function treeSitterSearchCommon(postProcess, restore_cursor)
    executeSearch(
        function()
            return gatherMatchesAcrossWindows(
                function(win)
                    local nodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter, win)
                    return treeSitterSearch.getNodeLocations(nodes, win)
                end)
        end,
        postProcess,
        restore_cursor)
end

--- Execute CodeCompanion command on selected text
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: false)
--- @return nil
function M.codeCompanionTreeSitter(returnCursor)
    if vim.fn.exists(':CodeCompanion') == 0 then
        vim.notify('CodeCompanion is not installed. Please install it first.', vim.log.levels.WARN)
        return
    end

    treeSitterSearchCommon(
        function(location)
            treeSitterSearch.visuallySelectNodeAtLocation(location)
            local keys = vim.api.nvim_replace_termcodes(":CodeCompanion ''<Left>", true, false, true)
            vim.api.nvim_feedkeys(keys, 'n', false)
        end, returnCursor or false)
end

--- Select Tree-sitter node matching search criteria
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: false)
--- @return nil
function M.selectTreeSitter(returnCursor)
    treeSitterSearchCommon(
        function(location)
            treeSitterSearch.visuallySelectNodeAtLocation(location)
        end, returnCursor or false)
end

--- Execute command on Tree-sitter node matching search criteria
--- @param command string The command to execute
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: true)
--- @return nil
function M.commandTreeSitter(command, returnCursor)
    treeSitterSearchCommon(
        function(location)
            treeSitterSearch.commandNodeAtStartLocation(location, command)
        end, returnCursor or true)
end

--- Apply user configuration and initialize highlight groups.
--- @param opts table|nil User configuration overrides
--- @return nil
function M.setup(opts)
    config.setAllOptions(opts)
end
return M
