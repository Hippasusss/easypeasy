print ("loaded easy peasy")
local M = {}


function M.setup()
end

local characterMap = {
    'a', 's', 'd', 'g', 'h','k', 'l', 'q', 'w', 'e',
    'r', 't', 'y', 'u', 'i', 'o','p', 'z', 'x', 'c',
    'v', 'b', 'n', 'm','f', 'j', ';'
    -- Other common symbols
}

local ns = vim.api.nvim_create_namespace('easypeasy')

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
        windowInfo = windowInfo,
        numMatches = 0
    }

    for linenumber, line in ipairs(lines) do
        local charColNums = {}
        for charColNum = 1, #line do
            local lineKey = line:sub(charColNum,charColNum)
            if lineKey == key then
                table.insert(charColNums, charColNum)
                jumpLocationInfo.numMatches = jumpLocationInfo.numMatches + 1
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

    table.sort(jumpLocationInfo.locations, function(a, b)
        local distA = math.abs(a[1] - cursorPosLine)
        local distB = math.abs(b[1] - cursorPosLine)
        return distA < distB
    end)

    local counter = 1
    for i, location in ipairs(jumpLocationInfo.locations) do
        local relLineNum = location[1]
        local absLineNum = firstLine + relLineNum - 1
        local charColNums = location[2]

        for j, colNum in ipairs(charColNums) do
            local replacementString = M.generate_replacement_string(counter, jumpLocationInfo.numMatches)
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

function M.generate_replacement_string(counter, numMatches)
    local chars = characterMap
    local numChars = #chars

    -- Calculate character distribution
    local numPrefixChars = math.min(math.floor(numMatches / numChars), numChars - 1)
    local numRegularChars = numChars - numPrefixChars

    -- Build character tables
    local prefixChars = {}
    local regularChars = {}

    for i = 1, numRegularChars do
        regularChars[i] = chars[i]
    end

    for i = 1, numPrefixChars do
        prefixChars[i] = chars[numRegularChars + i]
    end

    -- Calculate positions
    local iter = math.floor(counter / numRegularChars)
    local char_idx = (counter % numRegularChars) + 1

    -- Construct return string
    local result = regularChars[char_idx]
    if iter > 0 and iter <= #prefixChars then
        result = prefixChars[iter] .. result
    end

    return result
end

vim.api.nvim_set_hl(0, 'EasyPeasyMain', {
    fg = '#D6281C',
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySecondary', {
    fg = '#b35d27',
    bold = true,
})

function M.highlightLocations(jumpLocationInfo)
    local buf = jumpLocationInfo.buffer or 0

    for _, location in pairs(jumpLocationInfo.locations) do
        local abs_linenum = location.lineNum
        local charNumber = location.colNum
        local replacementString = location.replacementString

        --TODO: colour the secondary characters 
        vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            abs_linenum - 1,
            charNumber - 1,
            {
                hl_group = 'EasyPeasy',
                end_col = charNumber,
                virt_text = {{replacementString, 'EasyPeasy'}},
                virt_text_pos = 'overlay',
                priority = 1000,
            }
        )
    end
    vim.schedule(function()
        vim.cmd("mode")
        vim.cmd("redraw!")
    end)
    return jumpLocationInfo
end


function M.sortCharactersInOrderOfPrecidence(jumpLocationInfo)

end

-- also reduces match (then recurses) and calls to update highlighting
function M.jumpToKey(jumpLocationInfo)
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    local finalCursorLocation = jumpLocationInfo.windowInfo.cursor_pos
    local filteredLocations = {}

    for _, location in ipairs(jumpLocationInfo.locations) do
        if string.sub(location.replacementString, 1, 1) == key then
            if (string.len(location.replacementString) == 1) then
                vim.api.nvim_win_set_cursor(0, {location.lineNum, location.colNum - 1})
                return
            else
                location.replacementString = string.sub(location.replacementString, 2)
                table.insert(filteredLocations, location)
            end
        end
    end
    jumpLocationInfo.locations = filteredLocations
    jumpLocationInfo.numMatches = #filteredLocations

    if #filteredLocations == 1 and string.len(filteredLocations[1].replacementString) == 0 then
        vim.api.nvim_win_set_cursor(0, {filteredLocations[1].lineNum, filteredLocations[1].colNum - 1})
    elseif #filteredLocations > 0 then
        M.clearHighlights()
        M.highlightLocations(jumpLocationInfo)
        M.jumpToKey(jumpLocationInfo)
        return
    end

end

function M.runSingleChar()
    -- TODO: don't do this it's grossw
    M.jumpToKey(M.highlightLocations(M.calculateReplacementCharacters(M.findKeyLocationsInViewPort(M.askForKey()))))
    M.clearHighlights()
end

vim.keymap.set('n', '<leader>0', function() vim.cmd("luafile " .. vim.fn.expand("%:p")) end)
vim.keymap.set('n', '<leader>1', M.runSingleChar)
vim.keymap.set('n', '<leader>2', M.clearHighlights)
return M

