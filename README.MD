# easypeasy.nvim

A Lua rewrite of vim-easymotion that maintains LSP compatibility by avoiding buffer swapping, with added treesitter functionality.

## Features

- Single character search
- String search 
- Line search 
- Treesitter-aware motions
- Customizable key mappings
- Configurable appearance

## Installation (Lazy.nvim)

```lua
{
    "Hippasusss/easypeasy",
    keys = {
        {"s", function() require("easypeasy").searchSingleCharacter() end, mode = {"n","v"}},
        { "/", function() require("easypeasy").searchMultipleCharacters() end},
        { "<leader>z", function() require("easypeasy").searchLines() end, mode = {"n","v"}},
        { "<leader>tt", function() require("easypeasy").selectTreeSitter() end, mode = {"n"}},
        { "<leader>ty", function() require("easypeasy").commandTreeSitter('y') end, mode = {"n"}},
        { "<leader>td", function() require("easypeasy").commandTreeSitter('d') end, mode = {"n"}},
        { "<leader>tw", function() require("easypeasy").commandTreeSitter('gc', false) end, mode = {"n"}},
    },
    opts = {} -- optional configuration
}
```

## Configuration

Default configuration options (all optional):

```lua
opts = {
    -- Character set for jump labels
    characterMap = {
        'a', 's', 'd', 'g', 'h','k', 'l', 'q', 'w', 'e',
        'r', 't', 'y', 'u', 'i', 'o','p', 'z', 'x', 'c',
        'v', 'b', 'n', 'm','f', 'j', ';'
    },

    -- Treesitter nodes to target
    treesitterSearchFilter = {
        "if_statement", "for_statement", "while_statement",
        "for_loop", "while_loop", "if_expression",
        "switch_statement", "switch", "if", "for", "while",
        "function_definition", "method_definition",
        "function_declaration", "function_call",
        "arrow_function", "function", "method",
        "lambda", "anonymous_function",
        "field_declaration", "variable_declaration",
        "field", "assignment_statement"
    },

    -- Color customization
    fadedKeyColor = '#808080',
    primarySelectorKeyColor = '#D6281C',
    secondarySelectorKeyColor = '#d9d752',
    searchMatchColor = '#99F78B',

    -- Selection
    tsSelectionMode = 'v' --'V' for visual line
}
```

## Motivation

Existing buffer navigation plugins often:
- Don't have the same one/minimal key workflow of easymotion
- Break LSP functionality with buffer swapping
- Lack treesitter integration
- Aren't written in pure Lua

easypeasy.nvim solves these issues while maintaining vim-easymotion's core functionality.
