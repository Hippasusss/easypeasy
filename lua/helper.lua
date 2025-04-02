
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

vim.api.nvim_create_user_command('DebugKeys', DebugBackspace, {})
