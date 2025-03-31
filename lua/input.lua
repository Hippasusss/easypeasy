M = {}

function M.askForKey(message)
    print(message)
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    return key
end

return M
