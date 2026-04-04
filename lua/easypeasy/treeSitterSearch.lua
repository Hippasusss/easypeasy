local config = require("easypeasy.config")
local M = {}

--- Parse a buffer and return its root tree-sitter node.
--- @param buf integer|nil Buffer handle, defaults to current buffer
--- @return TSNode|nil root Root node for the first parsed tree
local function getRootNode(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then return nil end
    local tree = parser:parse()[1]
    return tree:root()
end

function M.getTSNodeLocations(filter_types, win)
    win = win or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local root = getRootNode(buf)
    if not root then return {} end

    local locations = {}
    local filter_set = filter_types and #filter_types > 0
        and vim.iter(filter_types):fold({}, function(acc, v) acc[v] = true return acc end)

    local function traverse(node)
        if not filter_set or filter_set[node:type()] then
            local s_row, s_col, e_row, e_col = node:range()
            table.insert(locations, {
                s_row + 1,
                s_col + 1,
                win = win,
                buf = buf,
                nodeRange = { s_row + 1, s_col, e_row + 1, e_col },
            })
        end

        for child in node:iter_children() do
            traverse(child)
        end
    end

    traverse(root)
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
