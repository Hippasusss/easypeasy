local M = {}

M.original_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
M.fadedKeyColor = '#808080'
M.primarySelectorKeyColor = '#D6281C'
M.secondarySelectorKeyColor = '#B35D27'
M.secondarySelectorKeyColor = '#99F78B'

vim.api.nvim_set_hl(0, 'EasyPeasyMain', {
    fg = M.primarySelectorKeyColor,
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySecondary', {
    fg = M.secondarySelectorKeyColor,
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySearch', {
    fg = M.secondarySelectorKeyColor,
    bold = true,
})

local original_hl = {}

local EXCLUDE_GROUPS = {
    ['EasyPeasyMain'] = true,
    ['EasyPeasySecondary'] = true,
    ['EasyPeasySearch'] = true
}

local ns = vim.api.nvim_create_namespace('easypeasy')

function M.highlightJumpLocations(jumpLocationInfo)
    local buf = jumpLocationInfo.buffer or 0

    for _, location in pairs(jumpLocationInfo.locations) do
        local absLinenum = location.lineNum
        local charNumber = location.colNum
        local replacementString = location.replacementString
        local firstChar = replacementString:sub(1, 1)
        local restChars = replacementString:sub(2)

        vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            absLinenum - 1,
            charNumber - 1,
            {
                hl_group = 'EasyPeasyMain',
                end_col = charNumber,
                virt_text = {{firstChar, 'EasyPeasyMain'}},
                virt_text_pos = 'overlay',
                priority = 1000,
            }
        )

        if #restChars > 0 then
            vim.api.nvim_buf_set_extmark(
                buf,
                ns,
                absLinenum - 1,
                charNumber,
                {
                    hl_group = 'EasyPeasySecondary',
                    end_col = charNumber,
                    virt_text = {{restChars, 'EasyPeasySecondary'}},
                    virt_text_pos = 'overlay',
                    priority = 1000,
                }
            )
        end
    end
    M.forceDraw()
    return jumpLocationInfo
end


function M.toggle_grey_text()
    if next(original_hl) == nil then
        for _, name in ipairs(vim.fn.getcompletion('', 'highlight')) do
            if not EXCLUDE_GROUPS[name] then
                local hl = vim.api.nvim_get_hl(0, { name = name })
                if hl and not hl.link then
                    original_hl[name] = vim.deepcopy(hl)
                    vim.api.nvim_set_hl(0, name, {
                        fg = M.fadedKeyColor,
                        bg = hl.bg,
                    })
                end
            end
        end
    else
        for name, attrs in pairs(original_hl) do
            vim.api.nvim_set_hl(0, name, attrs)
        end
        original_hl = {}
    end
    M.forceDraw()
end

function M.forceDraw()
    vim.schedule(function()
        vim.cmd("mode")
        vim.cmd("redraw!")
    end)
end

function M.clearHighlights()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.InteractiveSearch()
    local buf = vim.api.nvim_get_current_buf()
    local query = ''
    local matches = {}

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_echo({{'Enter search pattern: ', 'Question'}}, true, {})

    while true do
        vim.cmd('redraw')

        local ok, char = pcall(vim.fn.getchar)
        if not ok then break end

        local char_str = type(char) == 'number' and vim.fn.nr2char(char) or char
        local normalized = vim.fn.keytrans(tostring(char_str))
        print(vim.inspect(normalized))

        if normalized == '<CR>' then
            break
        elseif normalized == '<Esc>'then
            vim.api.nvim_echo({{'Search cancelled', 'WarningMsg'}}, true, {})
            print("escaped")
            M.toggle_grey_text()
            return nil

        elseif normalized == '<Tab>'then
        elseif normalized == '<BS>' then
            query = query:sub(1, -2)
            print("Back")
        else
            query = query .. vim.fn.nr2char(char)
        end

        if #query > 0 then
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            matches = {}

            local ok2, regex = pcall(vim.regex, query)
            if ok2 and regex then
                local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                for lnum, line in ipairs(lines) do
                    local start_idx = 0
                    while true do
                        local substr = line:sub(start_idx + 1)
                        local s, e = regex:match_str(substr)
                        if not s then break end

                        -- absolute
                        s = s + start_idx
                        e = e + start_idx

                        vim.api.nvim_buf_add_highlight(
                            buf, ns, 'EasyPeasySearch',
                            lnum - 1,
                            s,
                            e
                        )

                        table.insert(matches, {
                            lnum,
                            {s + 1},
                        })

                        start_idx = e
                        if start_idx >= #line then break end
                    end
                end
            end
        end

        vim.api.nvim_echo({{'Search: ' .. query, 'Normal'}}, false, {})
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    return matches
end

return M
