local highlight = require("easypeasy.highlight")
local M = {}

local function performJump(location)
    if location.win and location.win ~= vim.api.nvim_get_current_win() then
        vim.api.nvim_set_current_win(location.win)
    end
    vim.api.nvim_win_set_cursor(0, {location.lineNum, location.colNum - 1})
end

function M.jumpToKey(jumpLocationInfo)
    if #jumpLocationInfo.locations == 1 then
        performJump(jumpLocationInfo.locations[1])
        return jumpLocationInfo.locations[1]
    end

    local char = vim.fn.getchar()
    local key = type(char) == 'number' and vim.fn.nr2char(char) or char
    local filteredLocations = {}

    for _, location in ipairs(jumpLocationInfo.locations) do
        if string.sub(location.replacementString, 1, 1) == key then
            if (string.len(location.replacementString) == 1) then
                performJump(location)
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
        performJump(filteredLocations[1])
        return filteredLocations[1]
    elseif #filteredLocations > 0 then
        highlight.clearHighlights()
        highlight.highlightJumpLocations(jumpLocationInfo)
        return M.jumpToKey(jumpLocationInfo)
    end
end

return M
