local config = require("easypeasy.config")
local M = {}

-- Get locations of Tree-sitter nodes matching specified types in the given window.
-- @param filter_types table|nil Optional list of node types to filter by.
-- @param win integer|nil Window ID (defaults to current window).
-- @return table List of node locations, each with fields: startRow, startCol, win, buf, nodeRange.
-- Locations are deduplicated by start position, keeping the node with the largest range.
function M.getTSNodeLocations(filterTypes, win)
    win = win or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)

    -- Inlined getRootNode logic
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then return {} end
    local tree = parser:parse()[1]
    local root = tree:root()
    if not root then return {} end

    local locations = {}
    local filterSet = filterTypes and #filterTypes > 0
        and vim.iter(filterTypes):fold({}, function(acc, v) acc[v] = true return acc end)

    local function traverse(node)
        if not filterSet or filterSet[node:type()] then
            local startRow, startCol, endRow, endCol = node:range()
            local location = { startRow + 1, startCol + 1, win = win, buf = buf, nodeRange = { startRow + 1, startCol, endRow + 1, endCol }, }
            local key = string.format("%d:%d", location[1], location[2])
            local existing = locations[key]

            if not existing or location.nodeRange[3] > existing.nodeRange[3] or (location.nodeRange[3] == existing.nodeRange[3] and location.nodeRange[4] > existing.nodeRange[4]) then
                locations[key] = location
            end
        end

        for child in node:iter_children() do
            traverse(child)
        end
    end

    traverse(root)
    locations = vim.tbl_values(locations)
    table.sort(locations, function(a, b)
        if a[1] ~= b[1] then return a[1] < b[1] end
        return a[2] < b[2]
    end)
    return locations
end

--- Enter visual mode for a stored tree-sitter range and optionally feed a command.
--- @param location table Jump location containing nodeRange and window data
--- @param postAction string|nil Keys to feed after the selection is made
--- @return nil
local function runTreesitterCommand(location, postAction)
    local rangeLocation = location.nodeRange
    if rangeLocation == nil then return end

    if location.win and location.win ~= vim.api.nvim_get_current_win() then
        vim.api.nvim_set_current_win(location.win)
    end

    vim.api.nvim_win_set_cursor(0, {rangeLocation[3], rangeLocation[4]})
    vim.api.nvim_command('normal! ' .. config.options.tsSelectionMode)
    vim.api.nvim_win_set_cursor(0, {rangeLocation[1], rangeLocation[2]})

    if postAction then
        vim.api.nvim_feedkeys(postAction, 'xm', false)
    end
end

--- Visually select the tree-sitter node stored in a jump location.
--- @param location table Jump location containing nodeRange and window data
--- @return nil
function M.visuallySelectNodeAtLocation(location)
    runTreesitterCommand(location, nil)
end

--- Select the tree-sitter node stored in a jump location and run a normal-mode command.
--- @param location table Jump location containing nodeRange and window data
--- @param command string Normal-mode command to execute on the selection
--- @return nil
function M.commandNodeAtStartLocation(location, command)
    runTreesitterCommand(location, command)
end


return M
