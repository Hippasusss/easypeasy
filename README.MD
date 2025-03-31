# easypeasy.nvim

A Lua rewrite of vim-easymotion that avoids buffer swapping to maintain better LSP compatibility.

## Features

- Single character search: ✅ Working
- String search: ⏳ Not yet implemented
- Line search: ⏳ Not yet implemented
- Treesitter node motions: ⏳ Not yet implemented

## Installation (Lazy.nvim)

```lua
{
    "Hippasusss/easypeasy",
    keys = {
        {"s", function() require("easypeasy").searchSingleCharacter() end, mode = "n"}
    }
}
```

## Why?

While many buffer search plugins exist, none replicate easymotion's behavior. This plugin aims to:
- Match easymotion's functionality
- Avoid buffer swapping (which can disrupt LSPs)
- Provide a pure Lua implementation

## Key Mappings

The default mapping is:
- `s` - Search for single character

## Roadmap

Planned features in order of implementation:
1. String search (like "\" in easymotion)
2. Line search
3. Treesitter node motions (something like flash.nvim)
