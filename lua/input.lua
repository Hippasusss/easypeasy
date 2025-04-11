M = {}

function M.askForKey(message)
    vim.api.nvim_echo({{message, 'EasyPeasySearch'}}, false, {})
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    return key
end

return M
