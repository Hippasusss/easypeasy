local M = {}

M.characterMap = {
    'a', 's', 'd', 'g', 'h','k', 'l', 'q', 'w', 'e',
    'r', 't', 'y', 'u', 'i', 'o','p', 'z', 'x', 'c',
    'v', 'b', 'n', 'm','f', 'j', ';'
}

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

    local replacementString = M.generate_replacement_strings(#jumpLocationInfo.locations)
    for i, location in ipairs(jumpLocationInfo.locations) do
        local lineNum = location[1]
        local colNum = location[2]

        table.insert(replacementChars,
            {
                lineNum = lineNum,
                colNum = colNum,
                replacementString = replacementString[i]
            })
    end
    jumpLocationInfo.locations = replacementChars
    return jumpLocationInfo
end

function M.generate_replacement_strings(numMatches)
    local function SCTree(targetCount)
        local groups = {}
        local keysCount = {}

        -- Initialize keys count
        for i = 1, #M.characterMap do
            keysCount[i] = 0
        end

        -- Calculate distribution
        local remainingTargetsCount = targetCount
        local level = 0
        while remainingTargetsCount > 0 do
            local childCount = (level == 0) and 1 or (#M.characterMap - 1)

            for i = 1, #M.characterMap do
                keysCount[i] = keysCount[i] + childCount
                remainingTargetsCount = remainingTargetsCount - childCount

                if remainingTargetsCount <= 0 then
                    keysCount[i] = keysCount[i] + remainingTargetsCount
                    break
                end
            end
            level = level + 1
        end

        -- Build groups
        local targetIndex = 1
        for i = 1, #M.characterMap do
            local count = keysCount[i]
            if count > 1 then
                groups[M.characterMap[i]] = SCTree(count)
            elseif count == 1 then
                groups[M.characterMap[i]] = targetIndex
            end
            targetIndex = targetIndex + count
        end

        return groups
    end

    local groups = SCTree(numMatches)
    print(vim.inspect(groups))

    -- Flatten into replacement strings
    local replacements = {}
    local function flatten(g, prefix)
        prefix = prefix or ""
        for k, v in pairs(g) do
            if type(v) == "table" then
                flatten(v, prefix .. k)
            else
                replacements[v] = prefix .. k
            end
        end
    end
    flatten(groups)
    print(vim.inspect(replacements))

    -- Ensure sequential numbering
    local result = {}
    for i = 1, numMatches do
        result[i] = replacements[i]
    end

    return result
end

-- function M.generate_replacement_strings(numMatches)
--
--     -- Calculate character distribution
--     local numDoubleChars = math.max(0, math.floor(( numMatches - #M.characterMap) / #M.characterMap))
--     local numRegularChars = #M.characterMap - numDoubleChars - 1
--
--     local result = {}
--     for i = 1, numMatches-numDoubleChars do
--         result[i] = M.characterMap[i]
--     end
--
--     local doubleIndex = #M.characterMap
--     for i = 1, numMatches do
--         local prefixChar = M.characterMap[#M.characterMap - (math.floor(i / #M.characterMap))]
--         local secondChar = M.characterMap[i % #M.characterMap + 1]
--         result[numRegularChars + i] =  prefixChar .. secondChar
--     end
--
--     return result
-- end
return M
