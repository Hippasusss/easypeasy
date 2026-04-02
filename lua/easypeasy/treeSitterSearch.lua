local config = require("easypeasy.config")
local M = {}

function M.searchTreeSitterRoot(win_id)
    win_id = win_id or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win_id)
    local matches = {}
    local root = M.getRootNode(buf)
    if not root then return matches end

    for child in root:iter_children() do
        local lineNum , colNum  = child:range()
        table.insert(matches, {
            lineNum + 1,
            colNum + 1,
            win = win_id,
            buf = buf
        })
    end
    return matches
end

function M.searchTreeSitterRecurse(filter_types, win_id)
    win_id = win_id or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win_id)
    local root = M.getRootNode(buf)
    filter_types = filter_types or {}
    local matches = {}

    if not root then return matches end

    local function traverse(node)
        local node_type = node:type()
        if #filter_types == 0 or vim.tbl_contains(filter_types, node_type) then
            table.insert(matches, node)
        end
        for child in node:iter_children() do
            traverse(child)
        end
    end

    traverse(root)
    return matches
end

function M.getNodeLocation(node, win_id, buf)
    local lineStart, colStart, _, _ = node:range()
    lineStart = lineStart + 1
    colStart = colStart + 1
    return {
        lineStart,
        colStart,
        win = win_id,
        buf = buf
    }
end

function M.getNodeLocations(nodes, win_id)
    win_id = win_id or vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win_id)
    local locations = {}
    for _, node in ipairs(nodes) do
        table.insert(locations, M.getNodeLocation(node, win_id, buf))
    end
    return locations
end

function M.getNodeRangeFromLocation(location)
    local buf = location.buf or vim.api.nvim_get_current_buf()
    local root = M.getRootNode(buf)
    if not root then return nil end

    local function traverse(node)
        local startLineNum, startColnum, endLineNum, endColNum = node:range()
        if startLineNum + 1 == location.lineNum and startColnum + 1 == location.colNum then
            return {startLineNum + 1, startColnum, endLineNum + 1, endColNum}
        else
            for child in node:iter_children() do
                local value = traverse(child)
                if value then return value end
            end
        end
    end
    return traverse(root)
end

local function runTreesitterCommand(location, postAction)
    local rangeLocation = M.getNodeRangeFromLocation(location)
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

function M.visuallySelectNodeAtLocation(location)
    runTreesitterCommand(location, nil)
end

function M.commandNodeAtStartLocation(location, command)
    runTreesitterCommand(location, command)
end

function M.getRootNode(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then return nil end
    
    local tree = parser:parse()[1]
    return tree:root()
end

return M
