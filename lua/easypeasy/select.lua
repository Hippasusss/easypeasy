local M = {}

function M.getWindowInfo()
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

function M.createJumpLocations(locations)
    return {
        locations = locations,
        windowInfo = M.getWindowInfo(),
    }
end

function M.trimLocationsToWindow(jumpLocationInfo)
    for i, location in ipairs(jumpLocationInfo.locations) do
        if (location[1] < jumpLocationInfo.windowInfo.first_line) or (location[1] > jumpLocationInfo.windowInfo.last_line) then
            table.remove(jumpLocationInfo.locations, i)
        end
    end
    return jumpLocationInfo
end

function M.findAllVisibleLineStarts()
    local windowInfo = M.getWindowInfo()
    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    local matches = {}
    for linenumber, line in ipairs(lines) do
        if line:match("^%s*$") == nil then
            table.insert(matches, {
                linenumber + windowInfo.first_line - 1,
                1
            })
        end
    end
    return matches
end

function M.findKeyLocationsInViewPort(key)
    local windowInfo = M.getWindowInfo()
    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    local matches = {}

    for linenumber, line in ipairs(lines) do
        for charColNum = 1, #line do
            local lineKey = line:sub(charColNum,charColNum)
            if lineKey == key then
                table.insert(matches,
                    {
                        linenumber + windowInfo.first_line - 1,
                        charColNum
                    })
            end
        end
    end
    return matches
end

return M
