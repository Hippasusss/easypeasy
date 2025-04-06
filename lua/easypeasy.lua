local highlight = require("highlight")
local select = require("select")
local replace = require("replace")
local jump = require("jump")
local input = require("input")
local helper = require("helper")
local treeSitterSearch = require("treeSitterSearch")

local M = {}
local searchFor = {
    "if_statement",
    "for_statement",
    "while_statement",
    "for_loop",
    "while_loop",
    "if_expression",

    "block_comment",
    "comment_block",
    "multiline_comment",
    "line_comment",
    "doc_comment",
    -- Functions/methods
    -- "function_definition",
    -- "method_definition",
    -- "function_declaration",
    "arrow_function",
    "function",
    "method",
    "lambda",
    "anonymous_function"
}

function M.searchSingleCharacter()
    highlight.toggle_grey_text()

    local key = input.askForKey("Search For Key: ")
    local jumpLocationInfo = select.findKeyLocationsInViewPort(key)

    if #jumpLocationInfo.locations > 0 then
        jump.jumpToKey(highlight.highlightJumpLocations(replace.calculateReplacementCharacters(jumpLocationInfo)))
    else
        vim.api.nvim_echo({{'No Matches!', 'WarningMsg'}}, true, {})
    end
    highlight.toggle_grey_text()
end

function M.searchMultipleCharacters()
    highlight.toggle_grey_text()

    local replacementLocations = highlight.InteractiveSearch()

    if replacementLocations then
        local bufferJumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
        bufferJumplocations = select.trimLocationsToWindow(bufferJumplocations)
        local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(bufferJumplocations)
        if replacementLocationsWithCharacters then
            jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
        end
    else
        vim.api.nvim_echo({{'Exited', 'WarningMsg'}}, true, {})
    end
    highlight.toggle_grey_text()
end

function M.searchLines()
    highlight.toggle_grey_text()

    local replacementLocations = select.findAllVisibleLineStarts()

    if replacementLocations then
        local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(replacementLocations)
        if replacementLocationsWithCharacters then
            jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
        end
    else
        vim.api.nvim_echo({{'Exited', 'WarningMsg'}}, true, {})
    end
    highlight.toggle_grey_text()
end

function M.selectTreeSitter()
    highlight.toggle_grey_text()

    local replacementNodes = treeSitterSearch.searchTreeSitterRecurse(searchFor)
    local replacementLocations = treeSitterSearch.getNodeLocations(replacementNodes)

    if replacementLocations then
        local bufferJumplocations = select.createJumpLocations(replacementLocations, #replacementLocations)
        bufferJumplocations = select.trimLocationsToWindow(bufferJumplocations)
        local replacementLocationsWithCharacters = replace.calculateReplacementCharacters(bufferJumplocations)
        if replacementLocationsWithCharacters then
            local location = jump.jumpToKey(highlight.highlightJumpLocations(replacementLocationsWithCharacters))
            treeSitterSearch.visuallySelectNodeAtLocaiton({location.lineNum, location.colNum})
        end
    else
        vim.api.nvim_echo({{'Exited', 'WarningMsg'}}, true, {})
    end
    highlight.toggle_grey_text()
end

vim.keymap.set("n", "<leader>t", function() require("easypeasy").selectTreeSitter() end)

return M

