# easypeasy.nvim

A Lua rewrite of vim-easymotion that avoids buffer swapping to maintain better LSP compatibility.

## Features

- Single character search: ✅ Working
- String search: ✅ Working
- Line search: ⏳ Not yet 
- Treesitter node motions: ⏳ Not yet 

## Installation (Lazy.nvim)

```lua
    {
        "Hippasusss/easypeasy",
            keys = {
                {"s", function() require("easypeasy").searchSingleCharacter() end},
                { "/", function() require("easypeasy").searchMultipleCharacters() end}

            },
    },
```

## Why?

There are millions of buffer navigation searchy plugins. But I like easy motion. I made this to:
- Match easymotion's functionality
- Avoid buffer swapping (which makes your LSP have a panic attack)
- Provide a pure Lua implementation

## Key Mappings

The default mapping is:
- `s` - Search for single character
- `\/` - Search for single character

## Roadmap

Planned features in order of implementation:
2. Line search
3. Treesitter node motions (something like flash.nvim)
