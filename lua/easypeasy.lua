print ("loaded easy peasy")
local M = {}

function M.setup()
end

local characterMap = {
    -- Home row (highest priority)
    'a', 's', 'd', 'f', 'g','h', 'j', 'k', 'l', ';',
    -- Top row (next priority)
    'q', 'w', 'e', 'r', 't', 'y','u', 'i', 'o', 'p',
    -- Bottom row (next priority)
    'z', 'x', 'c', 'v','b', 'n', 'm'
    -- Other common symbols

    -- Numbers (lowest priority)
}
local doublCharactermap = {';',',','.'}

local ns = vim.api.nvim_create_namespace('KeyJumper')

function M.getWindowContextInfo()

    local windowInfo =
    {
        win = vim.api.nvim_get_current_win(),
        buf = vim.api.nvim_get_current_buf(),
        first_line = vim.fn.line('w0', vim.api.nvim_get_current_win()),
        last_line = vim.fn.line('w$', vim.api.nvim_get_current_win()),
        cursor_pos = vim.api.nvim_win_get_cursor(0),
    }
    return windowInfo
end

function M.clearHighlights()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.askForKey()
    print("Search for jump key:")
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    print (key)
    return key
end

function M.getSelection()
    --TODO: slash selection search
end


function M.findKeyLocationsInViewPort(key)
    M.clearHighlights()
    local windowInfo = M.getWindowContextInfo()

    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    local jumpLocationInfo = {
        locations = {},
        windowInfo = windowInfo
    }

    for linenumber, line in ipairs(lines) do
        local charColNums = {}
        for charColNum = 1, #line do
            local lineKey = line:sub(charColNum,charColNum)
            if lineKey == key then
                table.insert(charColNums, charColNum)
            end
        end
        if #charColNums > 0 then
            table.insert(jumpLocationInfo.locations,
                {
                    linenumber,
                    charColNums
                })
        end
    end
    return jumpLocationInfo
end



function M.calculateReplacementCharacters(jumpLocationInfo)
    local cursorPosLine = jumpLocationInfo.windowInfo.cursor_pos[1]
    local cursorPosCol = jumpLocationInfo.windowInfo.cursor_pos[2]
    local firstLine = jumpLocationInfo.windowInfo.first_line
    local replacementChars = {}

    table.sort(jumpLocationInfo.locations, function(a, b)
        local distA = math.abs((firstLine + a[1] - 1) - cursorPosLine) + math.abs(a[2][1] - cursorPosCol)
        local distB = math.abs((firstLine + b[1] - 1) - cursorPosLine) + math.abs(b[2][1] - cursorPosCol)
        return distA < distB
    end)

    for _, location in ipairs(jumpLocationInfo.locations) do
        print(location.linenumber, location.charColNums)
    end


    for _, location in ipairs(jumpLocationInfo.locations) do
        local relLineNum = location[1]
        local absLineNum = firstLine + relLineNum - 1
        local charColNums = location[2]
        for _, colNum in ipairs(charColNums) do
            local charCode = 97
            table.insert(replacementChars,
            {
                lineNum = absLineNum,
                colNum = colNum,
                char = string.char(charCode)
            })
        end
    end
    jumpLocationInfo.locations = replacementChars
    return jumpLocationInfo
end

function M.highlightLocations(jumpLocationInfo)
    local buf = jumpLocationInfo.buffer or 0

    for _, location in pairs(jumpLocationInfo.locations) do
        local abs_linenum = location.lineNum
        local charNumber = location.colNum
        local replacementChar = location.char

        vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            abs_linenum - 1,
            charNumber - 1,
            {
                hl_group = 'Search',
                end_col = charNumber,  -- Highlight end column
                virt_text = {{replacementChar, 'Search'}},  -- Replacement char
                virt_text_pos = 'overlay',  -- Display over existing text
                priority = 1000,
            }
        )
    end
end


function M.sortCharactersInOrderOfPrecidence(jumpLocationInfo)

end

function M.jumpToKey(location)
end

function M.runSingleChar()
    M.highlightLocations(M.calculateReplacementCharacters(M.findKeyLocationsInViewPort(M.askForKey())))
end

vim.keymap.set('n', '<leader>1', M.runSingleChar)
vim.keymap.set('n', '<leader>2', M.clearHighlights)
--z
return M

