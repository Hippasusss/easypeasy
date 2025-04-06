local M = {}

M.original_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
M.fadedKeyColor = '#808080'
M.primarySelectorKeyColor = '#D6281C'
M.secondarySelectorKeyColor = '#B35D27'
M.searchMatchColor = '#99F78B'

vim.api.nvim_set_hl(0, 'EasyPeasyMain', {
    fg = M.primarySelectorKeyColor,
    special = M.primarySelectorKeyColor,
    default = false,
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySecondary', {
    fg = M.secondarySelectorKeyColor,
    special = M.secondarySelectorKeyColor,
    default = false,
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySearch', {
    fg = M.searchMatchColor,
    special = M.searchMatchColor,
    default = false,
    bold = true,
})

local originalHL = {}

local EXCLUDE_GROUPS = {
    ['EasyPeasyMain'] = true,
    ['EasyPeasySecondary'] = true,
    ['EasyPeasySearch'] = true
}

local colorNameSpace = vim.api.nvim_create_namespace('easypeasy')

function M.highlightJumpLocations(jumpLocationInfo)
    local buf = jumpLocationInfo.buffer or 0

    for _, location in pairs(jumpLocationInfo.locations) do
        local absLinenum = location.lineNum
        local charNumber = location.colNum
        local replacementString = location.replacementString
        local firstChar = replacementString:sub(1, 1)
        local restChars = replacementString:sub(2)

        vim.api.nvim_buf_set_extmark(
            buf,
            colorNameSpace,
            absLinenum - 1,
            charNumber - 1,
            {
                hl_group = 'EasyPeasyMain',
                end_col = charNumber-1,
                virt_text = {{firstChar, 'EasyPeasyMain'}},
                virt_text_pos = 'overlay',
                priority = 1000,
            }
        )

        if #restChars > 0 then
            vim.api.nvim_buf_set_extmark(
                buf,
                colorNameSpace,
                absLinenum - 1,
                charNumber,
                {
                    hl_group = 'EasyPeasySecondary',
                    end_col = charNumber,
                    virt_text = {{restChars, 'EasyPeasySecondary'}},
                    virt_text_pos = 'overlay',
                    priority = 1000,
                }
            )
        end
    end
    M.forceDraw()
    return jumpLocationInfo
end


function M.toggle_grey_text()
    if next(originalHL) == nil then
        for _, name in ipairs(vim.fn.getcompletion('', 'highlight')) do
            if not EXCLUDE_GROUPS[name] then
                local hl = vim.api.nvim_get_hl(0, { name = name })
                if hl and not hl.link then
                    originalHL[name] = vim.deepcopy(hl)
                    vim.api.nvim_set_hl(0, name, {
                        fg = M.fadedKeyColor,
                        bg = hl.bg,
                    })

                end
            end
        end
        vim.api.nvim_set_hl(0, 'Cursor', {
            fg = 'NONE',
            bg = 'NONE',
            blend = 100
        })
        vim.api.nvim_set_hl(0, 'CursorLine', {
            fg = 'NONE',
            bg = 'NONE',
            blend = 100
        })
    else
        for name, attrs in pairs(originalHL) do
            vim.api.nvim_set_hl(0, name, attrs)
        end
        originalHL = {}
    end
    M.clearHighlights()
    M.forceDraw()
end

function M.forceDraw(immediate)
    immediate = immediate or 0
    if immediate then
        vim.cmd("redraw")
    else
        vim.schedule(vim.cmd.redraw)
    end
end

function M.clearHighlights(buf)
    buf = buf or 0
    vim.api.nvim_buf_clear_namespace(buf, colorNameSpace, 0, -1)
end

function M.InteractiveSearch()
    local buf = vim.api.nvim_get_current_buf()
    local query = ''
    local matches = {}

    local function updateMatches()
        M.clearHighlights(buf)
        matches = {}

        if #query == 0 then return end

        local regex_query = query:lower() == query and '\\c' .. query or query
        local ok, regex = pcall(vim.regex, regex_query)
        if not ok or not regex then return end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for lineNum, line in ipairs(lines) do
            local startIdx = 0
            while true do
                local substr = line:sub(startIdx + 1)
                local matchStartCol, matchEndCol = regex:match_str(substr)
                if not matchStartCol then break end

                matchStartCol = matchStartCol + startIdx
                matchEndCol = matchEndCol + startIdx

                vim.api.nvim_buf_add_highlight(
                    buf, colorNameSpace, 'EasyPeasySearch',
                    lineNum - 1,
                    matchStartCol,
                    matchEndCol
                )

                table.insert(matches, {lineNum, {matchStartCol + 1}})
                startIdx = matchEndCol
                if startIdx >= #line then break end
            end
        end
    end

    local function jumpIfNoMatchesInWindow()
        if #matches == 0 then return end

        local firstVisible = vim.fn.line('w0')
        local lastVisible = vim.fn.line('w$')

        for _, match in ipairs(matches) do
            if match[1] >= firstVisible and match[1] <= lastVisible then
                return
            end
        end

        vim.api.nvim_win_set_cursor(0, {matches[1][1], matches[1][2][1] - 1})
    end

    local function handleTab(down)
        if #matches == 0 then return end

        local edgeVisibleLine = down and vim.fn.line('w$') or vim.fn.line('w0')
        local compare = down and function(a,b) return a>b end or function(a,b) return a<b end
        local nextMatch = nil

        for i = down and 1 or #matches, down and #matches or 1, down and 1 or -1 do
            if compare(matches[i][1], edgeVisibleLine) then
                nextMatch = matches[i];
                print (vim.inspect(nextMatch[1]))
                break
            end
        end

        if not nextMatch or nextMatch[1] == vim.fn.line('.') then
            nextMatch = down and matches[1] or matches[#matches]
        end

        if nextMatch then
            vim.api.nvim_win_set_cursor(0, {nextMatch[1], nextMatch[2][1] - 1})
        end
    end


    M.clearHighlights(buf)

    local function redrawPrompt()
        vim.api.nvim_echo({{'Search: '..query, 'EasyPeasySearch'}}, true, {})
        M.forceDraw(true)
    end

    while true do
        redrawPrompt()

        local ok, char = pcall(vim.fn.getchar)
        if not ok then break end

        local charStr = type(char) == 'number' and vim.fn.nr2char(char) or char
        local normalized = vim.fn.keytrans(tostring(charStr))

        if normalized == '<CR>' then
            break
        elseif normalized == '<Esc>' then
            vim.api.nvim_echo({{'Search cancelled', 'WarningMsg'}}, true, {})
            M.clearHighlights(buf)
            return nil
        elseif normalized == '<Tab>' then
            handleTab(true)
        elseif normalized == '<S-Tab>' then
            handleTab(false)
        elseif normalized == '<BS>' then
            query = query:sub(1, -2)
            updateMatches()
            jumpIfNoMatchesInWindow()
        else
            query = query .. vim.fn.nr2char(char)
            updateMatches()
            jumpIfNoMatchesInWindow()
        end
    end

    M.clearHighlights(buf)
    return matches
end

return M
