local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")

local M = {}

--TODO: fix no match
--TODO: 
function M.searchSingleCharacter()
    local key = input.askForKey("Search For Key: ")
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    jump.jumpToKey(highlight.highlightJumpLocations(replace.calculateReplacementCharacters(select.findKeyLocationsInViewPort(key))))
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchMultipleCharacters()
    highlight.toggle_grey_text()
    highlight.clearHighlights()
    local replacementLocations = highlight.InteractiveSearch()
    local window = select.getWindowinfo()
    local jumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
    local ok, replacementLocations = pcall(replace.calculateReplacementCharacters, jumplocations)
    if ok then
        jump.jumpToKey(highlight.highlightJumpLocations(replacementLocations))
    end
    highlight.clearHighlights()
    highlight.toggle_grey_text()
end

function M.searchLines()
end

function M.searchTreesitter()
end
function DebugBackspace()
  print("Press backspace (then Escape to exit)")
  while true do
    local char = vim.fn.getchar()
    if type(char) == 'number' then
      print(string.format("Received numeric code: %d (hex: 0x%x)", char, char))
    else
      print("Received string: "..vim.inspect(char))
    end
    if char == 27 then break end  -- Escape exits
  end
end

-- Create command to test it
vim.api.nvim_create_user_command('DebugKeys', DebugBackspace, {})

vim.keymap.set('n', '<leader>0', function() vim.cmd("luafile " .. vim.fn.expand("%:p")) end)
vim.keymap.set('n', 's', M.searchSingleCharacter)
vim.keymap.set('n', '<space>', M.searchMultipleCharacters)
vim.keymap.set('n', '<leader>2', highlight.clearHighlights)
print("loaded easy peasy")
-- holymoly

return M

