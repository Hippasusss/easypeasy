local config = require("easypeasy.config")
local M = {}

--- Build the prefix allocation tree used to generate jump labels.
--- @param targets integer Number of labels needed in this subtree
--- @return table
local function buildReplacementTree(targets) -- TODO: looks bogging. make this more readable
    local counts    = {}
    local remaining = targets
    for i = 1, #config.options.characterMap do counts[i] = 0 end
    for level = 0, math.huge do
        local childCount = (level == 0) and 1 or (#config.options.characterMap - 1)
        local step       = level == 0 and 1 or -1
        local start      = level == 0 and 1 or #config.options.characterMap
        for i = start, start + (#config.options.characterMap - 1) * step, step do
            local alloc = math.min(childCount, remaining)
            counts[i]   = counts[i] + alloc
            remaining   = remaining - alloc
            if remaining <= 0 then break end
        end
        if remaining <= 0 then break end
    end
    local groups = {}
    local index  = 1
    for i, char in ipairs(config.options.characterMap) do
        local count   = counts[i]
        groups[char]  = count > 1 and buildReplacementTree(count) or index
        index         = index + count
    end
    return groups
end

--- Flatten the replacement tree into ordered label strings.
--- @param tree table Replacement allocation tree
--- @param output table Accumulator for generated labels
--- @param prefix string|nil Prefix accumulated so far
--- @return table
local function flattenReplacementTree(tree, output, prefix)
    prefix = prefix or ""
    for _, char in ipairs(config.options.characterMap) do
        local val = tree[char]
        if val then
            if type(val) == "table" then
                flattenReplacementTree(val, output, prefix .. char)
            else
                output[#output + 1] = prefix .. char
            end
        end
    end
    return output
end

--- Attach replacement label strings to each jump target.
--- @param jumpLocationInfo table Jump targets and current window context
--- @return table|nil jumpLocationInfo Updated jump data with replacement strings
function M.calculateReplacementCharacters(jumpLocationInfo)
    if jumpLocationInfo == nil then return nil end

    local cursorPosLine = jumpLocationInfo.windowInfo.cursor_pos[1]
    local cursorPosCol  = jumpLocationInfo.windowInfo.cursor_pos[2]

    table.sort(jumpLocationInfo.locations, function(a, b)
        local distLineA = math.abs(a[1] - cursorPosLine)
        local distLineB = math.abs(b[1] - cursorPosLine)
        local distColA  = math.abs(a[2] - cursorPosCol)
        local distColB  = math.abs(b[2] - cursorPosCol)
        if a[1] == b[1] then
            return distColA < distColB
        else
            return distLineA < distLineB
        end
    end)

    local replacementStrings = flattenReplacementTree(buildReplacementTree(#jumpLocationInfo.locations), {})

    local replacementChars = {}
    for i, location in ipairs(jumpLocationInfo.locations) do
        local loc              = vim.deepcopy(location)
        loc.lineNum            = location[1]
        loc.colNum             = location[2]
        loc.replacementString  = replacementStrings[i]
        table.insert(replacementChars, loc)
    end

    jumpLocationInfo.locations = replacementChars
    return jumpLocationInfo
end

return M
