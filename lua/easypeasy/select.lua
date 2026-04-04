local M = {}

--- Collect viewport and cursor information for a window.
--- @param win_id integer|nil Window handle, defaults to current window
--- @return table windowInfo Window id, buffer id, visible bounds, and cursor position
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

--- Bundle raw jump locations with window metadata.
--- @param locations table Candidate jump positions
--- @param windowInfo table|nil Precomputed window metadata
--- @return table jumpLocationInfo Combined jump context
function M.createJumpLocations(locations, windowInfo)
    return {
        locations = locations,
        windowInfo = windowInfo or M.getWindowInfo(),
    }
end


--- Find the first non-blank character position for each visible line.
--- @param win_id integer|nil Window handle, defaults to current window
--- @return table matches Jump targets for visible non-empty lines
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

--- Find all visible occurrences of a single character in the viewport.
--- @param key string Character to search for
--- @param win_id integer|nil Window handle, defaults to current window
--- @return table matches Jump targets for matching characters
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
