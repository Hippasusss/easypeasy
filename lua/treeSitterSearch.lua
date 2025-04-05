local M = {}

function M.searchTreeSitter()
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf)
    local matches = {}
    if parser then
        local tree = parser:parse()[1]
        local root = tree:root()
        for child in root:iter_children() do
            local lineNum , colNum  = child:range()
            table.insert(matches, {lineNum + 1, { colNum + 1}})
        end
    end
    return matches
end

return M
