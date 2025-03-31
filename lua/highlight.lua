local M = {}

M.original_hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
M.fadedKeyColor = '#808080'
M.primarySelectorKeyColor = '#D6281C'
M.secondarySelectorKeyColor = '#b35d27'
vim.api.nvim_set_hl(0, 'EasyPeasyMain', {
    fg = M.primarySelectorKeyColor,
    bold = true,
})
vim.api.nvim_set_hl(0, 'EasyPeasySecondary', {
    fg = M.secondarySelectorKeyColor,
    bold = true,
})

local original_hl = {}

local EXCLUDE_GROUPS = {
    ['EasyPeasyMain'] = true,
    ['EasyPeasySecondary'] = true
}

local ns = vim.api.nvim_create_namespace('easypeasy')

------- FUNC

function M.highlightLocations(jumpLocationInfo)
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

return M
