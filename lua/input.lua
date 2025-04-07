M = {}

function M.askForKey(message)
    vim.api.nvim_echo({{message, 'EasyPeasySearch'}}, false, {})
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    return key
end

local ns = vim.api.nvim_create_namespace('interactive_search')
local search_hl = vim.api.nvim_buf_add_highlight


return M
