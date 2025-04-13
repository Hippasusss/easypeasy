local config = require("config")

local M = {}

function M.calculateReplacementCharacters(jumpLocationInfo)
    if jumpLocationInfo == nil then return nil end

    local firstLine = jumpLocationInfo.windowInfo.first_line
    local cursorPosLine = jumpLocationInfo.windowInfo.cursor_pos[1]
    local cursorPosCol = jumpLocationInfo.windowInfo.cursor_pos[2]
    local replacementChars = {}

    table.sort(jumpLocationInfo.locations, function(a, b)
        local distLineA = math.abs(a[1] - cursorPosLine)
        local distLineB = math.abs(b[1] - cursorPosLine)
        local distColA = math.abs(a[2] - cursorPosCol)
        local distColB = math.abs(b[2] - cursorPosCol)
        local returnVal = false
        if a[1] == b[1] then
            return distColA < distColB
        else
            return distLineA < distLineB
        end
    end)

    local replacementStrings = M.generateReplacementStrings(#jumpLocationInfo.locations)
    for i, location in ipairs(jumpLocationInfo.locations) do
        local lineNum = location[1]
        local colNum = location[2]

        table.insert(replacementChars,
            {
                lineNum = lineNum,
                colNum = colNum,
                replacementString = replacementStrings[i]
            })
    end
    jumpLocationInfo.locations = replacementChars
    return jumpLocationInfo
end

function M.generateReplacementStrings(numMatches)
    local function buildTree(targets)
        local groups, counts = {}, {}
        for i = 1, #config.options.characterMap do counts[i] = 0 end
        local remaining = targets

        for level = 0, math.huge do
            --forward for single keys, back wards for prefix keys
            local childCount = (level == 0) and 1 or (#config.options.characterMap - 1)
            local step = level == 0 and 1 or -1
            local start = level == 0 and 1 or #config.options.characterMap
            for i = start, start + (#config.options.characterMap - 1) * step, step do
                local alloc = math.min(childCount, remaining)
                counts[i] = counts[i] + alloc
                remaining = remaining - alloc
                if remaining <= 0 then break end
            end
            if remaining <= 0 then break end
        end

        local index = 1
        for i, char in ipairs(config.options.characterMap) do
            local count = counts[i]
            groups[char] = count > 1 and buildTree(count) or index
            index = index + count
        end
        return groups
    end

    local replacements = {}
    local function flatten(tree, prefix)
        prefix = prefix or ""
        for _, char in ipairs(config.options.characterMap) do
            local val = tree[char]
            if val then
                if type(val) == "table" then
                    flatten(val, prefix..char)
                else
                    replacements[#replacements+1] = prefix..char
                end
            end
        end
    end
    flatten(buildTree(numMatches))
    return {unpack(replacements, 1, numMatches)}
end

return M
