local config = require("easypeasy.config")
local M = {}


local originalHL = {}
local EXCLUDE_GROUPS = {
    ['EasyPeasyMain'] = true,
    ['EasyPeasySecondary'] = true,
    ['EasyPeasySearch'] = true
}
local colorNameSpace = vim.api.nvim_create_namespace('easypeasy')

function M.highlightJumpLocations(jumpLocationInfo)
    if #jumpLocationInfo.locations == 0 then return end

    for _, location in pairs(jumpLocationInfo.locations) do
        local buf = location.buf or jumpLocationInfo.buffer or 0
        local absLinenum = location.lineNum
        local charNumber = location.colNum
        local replacementString = location.replacementString
        local firstChar = replacementString:sub(1, 1)
        local restChars = replacementString:sub(2, 2)

        vim.api.nvim_buf_set_extmark(
            buf,
            colorNameSpace,
            absLinenum - 1,
            charNumber - 1,
            {
                hl_group = 'EasyPeasyMain',
                end_col = charNumber - 1,
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
                        fg = config.options.fadedKeyColor,
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
    if buf then
        vim.api.nvim_buf_clear_namespace(buf, colorNameSpace, 0, -1)
    else
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(b) then
                vim.api.nvim_buf_clear_namespace(b, colorNameSpace, 0, -1)
            end
        end
    end
end

function M.InteractiveSearch()
    local query = ''
    local matches = {}

    local function updateMatches()
        M.clearHighlights()
        matches = {}

        if #query == 0 then return end

        local regex_query = query:lower() == query and '\\c' .. query or query
        local ok, regex = pcall(vim.regex, regex_query)
        if not ok or not regex then return end

        local wins = {vim.api.nvim_get_current_win()}
        if config.options.multiWindowSupport then
            wins = vim.api.nvim_tabpage_list_wins(0)
        end

        for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for lineNum, line in ipairs(lines) do
                local startIdx = 0
                while true do
                    local substr = line:sub(startIdx + 1)
                    local matchStartCol, matchEndCol = regex:match_str(substr)
                    if not matchStartCol then break end

                    matchStartCol = matchStartCol + startIdx
                    matchEndCol = matchEndCol + startIdx


                    vim.hl.range(
                        buf, colorNameSpace, 'EasyPeasySearch',
                        {lineNum - 1, matchStartCol},
                        {lineNum - 1, matchEndCol}
                    )

                    table.insert(matches, {
                        lineNum,
                        matchStartCol + 1,
                        win = win,
                        buf = buf
                    })
                    startIdx = matchEndCol
                    if startIdx >= #line then break end
                end
            end
        end
    end

    local function jumpIfNoMatchesInWindow()
        if #matches == 0 then return end

        local current_win = vim.api.nvim_get_current_win()
        local firstVisible = vim.fn.line('w0', current_win)
        local lastVisible = vim.fn.line('w$', current_win)

        for _, match in ipairs(matches) do
            if match.win == current_win and match[1] >= firstVisible and match[1] <= lastVisible then
                return
            end
        end

        if matches[1].win ~= current_win then
            vim.api.nvim_set_current_win(matches[1].win)
        end
        vim.api.nvim_win_set_cursor(0, {matches[1][1], matches[1][2] - 1})
    end

    local function handleTab(down)
        if #matches == 0 then return end

        local current_win = vim.api.nvim_get_current_win()
        local w0 = vim.fn.line('w0', current_win)
        local ws = vim.fn.line('w$', current_win)

        local currentIndex = nil
        local cursor = vim.api.nvim_win_get_cursor(current_win)
        for i, m in ipairs(matches) do
            if m.win == current_win and m[1] == cursor[1] and m[2] == cursor[2] + 1 then
                currentIndex = i
                break
            end
        end

        local nextMatch = nil
        if not currentIndex then
            nextMatch = down and matches[1] or matches[#matches]
        else
            local step = down and 1 or -1
            local i = currentIndex + step

            while true do
                if i < 1 then i = #matches end
                if i > #matches then i = 1 end

                local m = matches[i]
                local is_visible = (m.win == current_win and m[1] >= w0 and m[1] <= ws)

                if not is_visible then
                    nextMatch = m
                    break
                end

                if i == currentIndex then
                    local nextIdx = down and (currentIndex % #matches + 1) or ((currentIndex - 2 + #matches) % #matches + 1)
                    nextMatch = matches[nextIdx]
                    break
                end
                i = i + step
            end
        end

        if nextMatch then
            if nextMatch.win ~= current_win then
                vim.api.nvim_set_current_win(nextMatch.win)
            end
            vim.api.nvim_win_set_cursor(0, {nextMatch[1], nextMatch[2] - 1})
        end
    end

    M.clearHighlights()

    local function redrawPrompt()
        vim.api.nvim_echo({{'Search: '..query, 'EasyPeasySearch'}}, false, {})
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
            M.clearHighlights()
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
            query = query .. charStr
            updateMatches()
            jumpIfNoMatchesInWindow()
        end
    end

    M.clearHighlights()
    return matches
end

return M
