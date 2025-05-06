M = {}

function M.askForKey(message)
    vim.api.nvim_echo({{message, 'EasyPeasySearch'}}, false, {})
    local char = vim.fn.getchar()
    local key = type(char) ==  'number' and vim.fn.nr2char(char) or char
    return key
end

return M
