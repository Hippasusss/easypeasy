local highlight = require("highlight")
local M = {}
function M.jumpToKey(jumpLocationInfo)
    if #jumpLocationInfo.locations == 1 then
        vim.api.nvim_win_set_cursor(0, {jumpLocationInfo.locations[1].lineNum, jumpLocationInfo.locations[1].colNum - 1})
        return jumpLocationInfo.locations[1]
    end

    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    local finalCursorLocation = jumpLocationInfo.windowInfo.cursor_pos
    local filteredLocations = {}

    for _, location in ipairs(jumpLocationInfo.locations) do
        if string.sub(location.replacementString, 1, 1) == key then
            if (string.len(location.replacementString) == 1) then
                vim.api.nvim_win_set_cursor(0, {location.lineNum, location.colNum - 1})
                return location
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
        return filteredLocations[1]
    elseif #filteredLocations > 0 then
        highlight.clearHighlights()
        highlight.highlightJumpLocations(jumpLocationInfo)
        return M.jumpToKey(jumpLocationInfo)
    end
end
return M
