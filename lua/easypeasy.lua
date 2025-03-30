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
    local firstLine = jumpLocationInfo.windowInfo.first_line
    local cursorPosLine = jumpLocationInfo.windowInfo.cursor_pos[1] - firstLine --make relative to viewport
    local cursorPosCol = jumpLocationInfo.windowInfo.cursor_pos[2]
    local replacementChars = {}
    -- print("")
    -- print(vim.inspect(jumpLocationInfo.locations))

    -- sort line numbers closest to the cursor first
    table.sort(jumpLocationInfo.locations, function(a, b)
        local distA = math.abs(a[1] - cursorPosLine)
        local distB = math.abs(b[1] - cursorPosLine)
        return distA < distB
    end)

    -- sort characters on the line main line
    -- for _, charArray in pairs(jumpLocationInfo.charColNums)do
    -- end
    --
    -- print("cursorPosLine" .. cursorPosLine)
    -- print("cursorPoscCol" .. cursorPosCol)
    -- print(vim.inspect(jumpLocationInfo.locations))

    local counter = 1
    for i, location in ipairs(jumpLocationInfo.locations) do
        local relLineNum = location[1]
        local absLineNum = firstLine + relLineNum - 1
        local charColNums = location[2]
        for j, colNum in ipairs(charColNums) do
            local cmIndex = math.fmod(counter -1 , #characterMap) + 1
            local replacementString = characterMap[cmIndex]
            print(replacementString)
            print(cmIndex)
            local numPrefixes = math.floor(counter / #characterMap)
            if numPrefixes > 0 then
                for k = 1, numPrefixes do
                    replacementString = doublCharactermap[k] .. replacementString
                end
            end
            table.insert(replacementChars,
            {
                lineNum = absLineNum,
                colNum = colNum,
                replacementString = replacementString
            })
            counter = counter + 1
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
        local replacementString = location.replacementString
        -- print (replacementString)

        vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            abs_linenum - 1,
            charNumber - 1,
            {
                hl_group = 'Search',
                end_col = charNumber,  -- Highlight end column
                virt_text = {{replacementString, 'Search'}},  -- Replacement char
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

vim.keymap.set('n', '<leader>0', function() vim.cmd("luafile " .. vim.fn.expand("%:p")) end)
vim.keymap.set('n', '<leader>1', M.runSingleChar)
vim.keymap.set('n', '<leader>2', M.clearHighlights)
--z
return M

