local M = {}

M.searchFor = {
    "if_statement",
    "for_statement",
    "while_statement",
    "for_loop",
    "while_loop",
    "if_expression",

    -- Functions/methods
    -- "function_definition",
    -- "method_definition",
    "function_declaration",
    "arrow_function",
    -- "function",
    "method",
    "lambda",
    "anonymous_function"
}

function M.searchTreeSitterRoot()
    local matches = {}
    local root = M.getRootNode()
    for child in root:iter_children() do
        local lineNum , colNum  = child:range()
        table.insert(matches, {lineNum + 1,  colNum + 1})
    end
    return matches
end

function M.searchTreeSitterRecurse(filter_types)
    local root = M.getRootNode()
    filter_types = filter_types or {}
    local matches = {}

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

function M.getNodeLocation(node)
    local lineStart, colStart, lineEnd, colEnd = node:range()
    lineStart = lineStart + 1
    lineEnd = lineEnd + 1
    colStart = colStart + 1
    colEnd = colEnd + 1
    return {lineStart, colStart}
end

function M.getNodeLocations(nodes)
    local locations = {}
    for _, node in ipairs(nodes)do
        table.insert(locations, M.getNodeLocation(node))
    end
    return locations
end

function M.getNodeRangeFromLocation(location)
    local root = M.getRootNode()

    local function traverse(node)
        local startLineNum, startColnum, endLineNum, endColNum = node:range()
        if startLineNum + 1 == location[1] and startColnum + 1 == location[2] then
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

    vim.api.nvim_win_set_cursor(0, {rangeLocation[3], rangeLocation[4]})
    vim.api.nvim_command('normal! V')
    vim.api.nvim_win_set_cursor(0, {rangeLocation[1], rangeLocation[2]})

    if postAction then
        vim.api.nvim_command('normal! ' .. postAction)
    end
end

function M.visuallySelectNodeAtLocation(location)
    runTreesitterCommand(location, nil)
end

function M.yankNodeAtStartLocation(location)
    runTreesitterCommand(location, 'y')
end

function M.deleteNodeAtStartLocation(location)
    runTreesitterCommand(location, 'd')
end

function M.getRootNode()
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf)
    local matches = {}
    local root
    if parser then
        local tree = parser:parse()[1]
        root = tree:root()
    end
    return root
end

return M
