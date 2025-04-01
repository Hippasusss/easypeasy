M = {}

function M.askForKey(message)
    print(message)
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    return key
end

local ns = vim.api.nvim_create_namespace('interactive_search')
local search_hl = vim.api.nvim_buf_add_highlight

function M.askForString(message)
    -- vim.fn.input()
end

return M
