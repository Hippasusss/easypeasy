# easypeasy.nvim

A Lua rewrite of vim-easymotion that avoids buffer swapping to maintain better LSP compatibility and adds treesitter funcitonality

## Features

- Single character search
- String search 
- Line search 
- Treesitter node motions

## Installation (Lazy.nvim)

```lua
    {
        "Hippasusss/easypeasy",
        keys = {
            {"s", function() require("easypeasy").searchSingleCharacter() end, mode = {"n","v"}},
            { "/", function() require("easypeasy").searchMultipleCharacters() end},
            { "<leader>z", function() require("easypeasy").searchLines() end, mode = {"n","v"}},
            { "<leader>tt", function() require("easypeasy").selectTreeSitter() end, mode = {"n",}},
            { "<leader>ty", function() require("easypeasy").yankTreeSitter() end, mode = {"n",}},
            { "<leader>td", function() require("easypeasy").deleteTreeSitter() end, mode = {"n",}},
            { "<leader>tw", function() require("easypeasy").commandTreeSitter('gc') end, mode = {"n"}},
        },
    },
```

## Why?

There are millions of buffer navigation searchy plugins. But I like easy motion. I made this to:
- Match easymotion's functionality
- Avoid buffer swapping (which makes your LSP have a panic attack)
- Provide a pure Lua implementation
- Add some treesitter aware funcitonality
