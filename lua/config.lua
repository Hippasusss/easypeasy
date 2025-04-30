local M = {}

--- Default configuration options for EasyPeasy
-- @table default_options
-- @field characterMap table List of characters to use for key mappings
-- @field treesitterSearchFilter table List of treesitter node types to search for
-- @field fadedKeyColor string Hex color for faded keys
-- @field primarySelectorKeyColor string Hex color for primary selector keys
-- @field secondarySelectorKeyColor string Hex color for secondary selector keys
-- @field searchMatchColor string Hex color for search matches
local default_options = {
    characterMap = {
        'a', 's', 'd', 'g', 'h','k', 'l', 'q', 'w', 'e',
        'r', 't', 'y', 'u', 'i', 'o','p', 'z', 'x', 'c',
        'v', 'b', 'n', 'm','f', 'j', ';'
    },
    treesitterSearchFilter = {
        "if_statement",
        "for_statement",
        "while_statement",
        "for_loop",
        "while_loop",
        "if_expression",
        "switch_statement",
        "switch",
        "if",
        "for",
        "while",
        "function_definition",
        "method_definition",
        "function_declaration",
        "function_call",
        "arrow_function",
        "function",
        "method",
        "lambda",
        "anonymous_function",
        "field_declaration",
        "variable_declaration",
        "field",
        "assignment_statement",
        "expression_statement",
        "template_declaration",
        "return_statement",
        "declaration",
    },
    fadedKeyColor = '#808080',
    primarySelectorKeyColor = '#D6281C',
    secondarySelectorKeyColor = '#fc8b98',
    searchMatchColor = '#99F78B',
    tsSelectionMode = 'v'
}


M.options = {}

function M.setOptions(opts)
    M.options = vim.tbl_deep_extend("force", default_options, opts or {})

    vim.api.nvim_set_hl(0, 'EasyPeasyMain', {
        fg = M.options.primarySelectorKeyColor,
        special = M.options.primarySelectorKeyColor,
        default = false,
        bold = true,
    })
    vim.api.nvim_set_hl(0, 'EasyPeasySecondary', {
        fg = M.options.secondarySelectorKeyColor,
        special = M.options.secondarySelectorKeyColor,
        default = false,
        bold = true,
    })
    vim.api.nvim_set_hl(0, 'EasyPeasySearch', {
        fg = M.options.searchMatchColor,
        special = M.options.searchMatchColor,
        default = false,
        bold = true,
    })
    return M.options
end


return M

