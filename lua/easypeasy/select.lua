local M = {}

function M.getWindowInfo(win_id)
    win_id = win_id or vim.api.nvim_get_current_win()
    local windowInfo =
    {
        win = win_id,
        buf = vim.api.nvim_win_get_buf(win_id),
        first_line = vim.fn.line('w0', win_id),
        last_line = vim.fn.line('w$', win_id),
        cursor_pos = vim.api.nvim_win_get_cursor(win_id),
    }
    return windowInfo
end

function M.createJumpLocations(locations, windowInfo)
    return {
        locations = locations,
        windowInfo = windowInfo or M.getWindowInfo(),
    }
end

function M.trimLocationsToWindow(jumpLocationInfo)
    local filtered = {}
    for _, location in ipairs(jumpLocationInfo.locations) do
        if (location[1] >= jumpLocationInfo.windowInfo.first_line) and (location[1] <= jumpLocationInfo.windowInfo.last_line) then
            table.insert(filtered, location)
        end
    end
    jumpLocationInfo.locations = filtered
    return jumpLocationInfo
end

function M.findAllVisibleLineStarts(win_id)
    local windowInfo = M.getWindowInfo(win_id)
    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    local matches = {}
    for linenumber, line in ipairs(lines) do
        if line:match("^%s*$") == nil then
            table.insert(matches, {
                linenumber + windowInfo.first_line - 1,
                1,
                win = windowInfo.win,
                buf = windowInfo.buf
            })
        end
    end
    return matches
end

function M.findKeyLocationsInViewPort(key, win_id)
    local windowInfo = M.getWindowInfo(win_id)
    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    local matches = {}

    for linenumber, line in ipairs(lines) do
        for charColNum = 1, #line do
            local lineKey = line:sub(charColNum,charColNum)
            if lineKey == key then
                table.insert(matches,
                    {
                        linenumber + windowInfo.first_line - 1,
                        charColNum,
                        win = windowInfo.win,
                        buf = windowInfo.buf
                    })
            end
        end
    end
    return matches
end

return M
