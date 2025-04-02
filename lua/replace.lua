local M = {}

M.characterMap = {
    'a', 's', 'd', 'g', 'h','k', 'l', 'q', 'w', 'e',
    'r', 't', 'y', 'u', 'i', 'o','p', 'z', 'x', 'c',
    'v', 'b', 'n', 'm','f', 'j', ';'
}

function M.calculateReplacementCharacters(jumpLocationInfo)
    if jumpLocationInfo == nil then return nil end

    local firstLine = jumpLocationInfo.windowInfo.first_line
    local cursorPosLine = jumpLocationInfo.windowInfo.cursor_pos[1] - firstLine --make relative to viewport
    local cursorPosCol = jumpLocationInfo.windowInfo.cursor_pos[2]
    local replacementChars = {}

    table.sort(jumpLocationInfo.locations, function(a, b)
        local distA = math.abs(a[1] - cursorPosLine)
        local distB = math.abs(b[1] - cursorPosLine)
        return distA < distB
    end)

    local counter = 0
    for i, location in ipairs(jumpLocationInfo.locations) do
        local relLineNum = location[1]
        local absLineNum = firstLine + relLineNum - 1
        local charColNums = location[2]

        for j, colNum in ipairs(charColNums) do
            local replacementString = M.generate_replacement_string(counter, jumpLocationInfo.numMatches)
            table.insert(replacementChars,
                {
                    lineNum = absLineNum,
                    colNum = colNum,
                    replacementString = replacementString
                })
            counter = counter + 1
        end
    end
    jumpLocationInfo.locations = replacementChars
    return jumpLocationInfo
end

function M.generate_replacement_string(counter, numMatches)
    local chars = M.characterMap
    local numChars = #chars

    -- Calculate character distribution
    local numPrefixChars = math.min(math.floor(numMatches / numChars), numChars - 1)
    local numRegularChars = numChars - numPrefixChars

    -- Build character tables
    local prefixChars = {}
    local regularChars = {}

    for i = 1, numRegularChars do
        regularChars[i] = chars[i]
    end

    for i = 1, numPrefixChars do
        prefixChars[i] = chars[numRegularChars + i]
    end

    -- Calculate positions
    local iter = math.floor(counter / numRegularChars)
    local char_idx = (counter % numRegularChars) + 1

    -- Construct return string
    local result = regularChars[char_idx]
    if iter > 0 and iter <= #prefixChars then
        result = prefixChars[iter] .. result
    end
    return result
end
return M
