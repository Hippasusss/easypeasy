local M = {}

--- Prompt for a single keypress and return it as a string.
--- @param message string Prompt text shown in the command area
--- @return string key Pressed key as text
function M.askForKey(message)
    vim.api.nvim_echo({{message, 'EasyPeasySearch'}}, false, {})
    local char = vim.fn.getchar()
    local key = type(char) ==  'number' and vim.fn.nr2char(char) or char
    return key
end

return M
