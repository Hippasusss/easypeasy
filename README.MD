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
            {"s", function() require("easypeasy").searchSingleCharacter() end, desc = "Search for character and then jump"},
            { "/", function() require("easypeasy").searchMultipleCharacters() end, desc = "Search for regex and then jump"},
            { "<leader>z", function() require("easypeasy").searchLiness() end, desc = "Search lines" },
            { "<leader>tt", function() require("easypeasy").selectTreeSitter() end, desc = "Search and then visualy select treesitter nodes"},
            { "<leader>ty", function() require("easypeasy").yankTreeSitter() end, desc = "Search and then yank treesitter nodes"},
            { "<leader>td", function() require("easypeasy").deleteTreeSitter() end, desc = "Search and then delete treesitter nodes"},
    },
```

## Why?

There are millions of buffer navigation searchy plugins. But I like easy motion. I made this to:
- Match easymotion's functionality
- Avoid buffer swapping (which makes your LSP have a panic attack)
- Provide a pure Lua implementation
- Add some treesitter aware funcitonality
