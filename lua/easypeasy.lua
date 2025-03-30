print ("loaded easy peasy")
local M = {}

function M.setup()
end

local ns = vim.api.nvim_create_namespace('KeyJumper')

function M.getWindowContextInfo()

    local windowInfo =
    {
        win = vim.api.nvim_get_current_win(),
        buf = vim.api.nvim_get_current_buf(),
        first_line = vim.fn.line('w0', vim.api.nvim_get_current_buf()),
        last_line = vim.fn.line('w$', vim.api.nvim_get_current_buf()),
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
    return key
end

function M.findKeyInViewPort(key)
    -- Clear previous marks
    M.clearHighlights()
    local windowInfo = M.getWindowContextInfo()

    local lines = vim.api.nvim_buf_get_lines(windowInfo.buf, windowInfo.first_line - 1, windowInfo.last_line, false)
    -- Find all instances in visible area
    local jumpLocationInfo = {
        locations = {},
        windowInfo = windowInfo
    }
    print (key)

    for linenumber, line in ipairs(lines) do
        -- Process each visible line here
        local charnumbers = {}
        for charnumber = 1, #line do
            local lineKey = line:sub(charnumber,charnumber)
            if lineKey == key then
                table.insert(charnumbers, charnumber)
            end
        end
        if #charnumbers > 0 then
            table.insert(jumpLocationInfo.locations, {linenumber, charnumbers})
        end
    end
    return jumpLocationInfo
end

function M.findSelectionInViewPort(selection)
end

function M.highlightLocations(jumpLocationInfo)
    local buf = jumpLocationInfo.buffer

    for _, location in ipairs(jumpLocationInfo.locations) do
        local rel_linenumber = location[1]
        local charnumbers = location[2]
        local abs_linenumber = jumpLocationInfo.first_line + rel_linenumber - 2  -- Adjusted conversion

        -- Get the line text to verify column bounds
        local line_text = vim.api.nvim_buf_get_lines(buf, abs_linenumber, abs_linenumber + 1, false)[1] or ""
        local line_length = #line_text

        for _, col in ipairs(charnumbers) do
            -- Ensure column is within valid range (1-based)
            if col >= 1 and col <= line_length then
                vim.api.nvim_buf_set_extmark(
                    buf,
                    ns,
                    abs_linenumber,  -- 0-based line
                    col - 1,         -- 0-based column (clamped)
                    {
                        hl_group = 'Search',
                        end_col = col,
                        priority = 100
                    }
                )
            end
        end
    end
end

function M.jumpToKey(location)
end

M.highlightLocations(M.findKeyInViewPort(M.askForKey()))
--M.clearHighlights()
--z
return M

