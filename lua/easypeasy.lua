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

    restore_cursor = restore_cursor or false
    local scrolloff = vim.opt.scrolloff
    if restore_cursor then vim.opt.scrolloff = 0 end
    local original_pos = vim.api.nvim_win_get_cursor(0)
    local original_win = vim.api.nvim_get_current_win()

    local success, replacementLocations = pcall(getLocationsFn)

    local ok, err = pcall(function()
        if success and replacementLocations then
            local bufferJumplocations = select.createJumpLocations(replacementLocations)
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
            local wins = {vim.api.nvim_get_current_win()}
            if config.options.multiWindowSupport then
                wins = vim.api.nvim_tabpage_list_wins(0)
            end

            local allMatches = {}
            for _, win in ipairs(wins) do
                local win_matches = select.findKeyLocationsInViewPort(key, win)
                for _, match in ipairs(win_matches) do
                    table.insert(allMatches, match)
                end
            end
            return allMatches
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
            local wins = {vim.api.nvim_get_current_win()}
            if config.options.multiWindowSupport then
                wins = vim.api.nvim_tabpage_list_wins(0)
            end

            local allMatches = {}
            for _, win in ipairs(wins) do
                local win_matches = select.findAllVisibleLineStarts(win)
                for _, match in ipairs(win_matches) do
                    table.insert(allMatches, match)
                end
            end
            return allMatches
        end)
end

--- Execute CodeCompanion command on selected text
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: false)
--- @return nil
function M.codeCompanionTreeSitter(returnCursor)
    returnCursor = returnCursor or false
    if vim.fn.exists(':CodeCompanion') == 0 then
        vim.notify('CodeCompanion is not installed. Please install it first.', vim.log.levels.WARN)
        return
    end
    executeSearch(
        function()
            local wins = {vim.api.nvim_get_current_win()}
            if config.options.multiWindowSupport then
                wins = vim.api.nvim_tabpage_list_wins(0)
            end

            local allMatches = {}
            for _, win in ipairs(wins) do
                local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter, win)
                local win_matches = treeSitterSearch.getNodeLocations(replacementNodes, win)
                for _, match in ipairs(win_matches) do
                    table.insert(allMatches, match)
                end
            end
            return allMatches
        end,
        function(location)
            treeSitterSearch.visuallySelectNodeAtLocation(location)
            local keys = vim.api.nvim_replace_termcodes(":CodeCompanion ''<Left>", true, false, true)
            vim.api.nvim_feedkeys(keys, 'n', false)
        end,
        returnCursor)
end

--- Select Tree-sitter node matching search criteria
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: false)
--- @return nil
function M.selectTreeSitter(returnCursor)
    returnCursor = returnCursor or false
    executeSearch(
        function()
            local wins = {vim.api.nvim_get_current_win()}
            if config.options.multiWindowSupport then
                wins = vim.api.nvim_tabpage_list_wins(0)
            end

            local allMatches = {}
            for _, win in ipairs(wins) do
                local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter, win)
                local win_matches = treeSitterSearch.getNodeLocations(replacementNodes, win)
                for _, match in ipairs(win_matches) do
                    table.insert(allMatches, match)
                end
            end
            return allMatches
        end,
        function(location)
            treeSitterSearch.visuallySelectNodeAtLocation(location)
        end,
        returnCursor)
end

--- Execute command on Tree-sitter node matching search criteria
--- @param command string The command to execute
--- @param returnCursor boolean|nil Whether to return cursor to original position (default: true)
--- @return nil
function M.commandTreeSitter(command, returnCursor)
    returnCursor = returnCursor or true
    executeSearch(
        function()
            local wins = {vim.api.nvim_get_current_win()}
            if config.options.multiWindowSupport then
                wins = vim.api.nvim_tabpage_list_wins(0)
            end

            local allMatches = {}
            for _, win in ipairs(wins) do
                local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(config.options.treesitterSearchFilter, win)
                local win_matches = treeSitterSearch.getNodeLocations(replacementNodes, win)
                for _, match in ipairs(win_matches) do
                    table.insert(allMatches, match)
                end
            end
            return allMatches
        end,
        function(location)
            treeSitterSearch.commandNodeAtStartLocation(location, command)
        end,
        returnCursor)
end

function M.setup(opts)
    config.setAllOptions(opts)
end
return M
