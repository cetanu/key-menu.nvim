---@mod key-menu.utils Utility functions for key-menu.nvim

local M = {}

---Partially applies a function with one argument.
---@generic T, U, R
---@param func fun(a: T, b: U): R The function to partial apply.
---@param x T The first argument to bind.
---@return fun(y: U): R # A new function that takes the second argument.
function M.partial(func, x)
  return function(y)
    return func(x, y)
  end
end

---Checks if a string starts with a given prefix.
---@param prefix string The prefix to check for.
---@param s string The string to check.
---@return boolean # True if s starts with prefix.
function M.starts_with(prefix, s)
  return s:sub(1, #prefix) == prefix
end

---Checks if a string ends with a given suffix.
---@param suffix string The suffix to check for.
---@param s string The string to check.
---@return boolean # True if s ends with suffix.
function M.ends_with(suffix, s)
  return s:sub(#s - (#suffix - 1), #s) == suffix
end

---Get byte count of unicode character starting at byte i (RFC 3629).
---@param s string The string.
---@param i? number The byte index (1-based). Defaults to 1.
---@return number # The number of bytes in the character.
function M.char_byte_count(s, i)
  local c = string.byte(s, i or 1)

  if c > 0 and c <= 127 then
    return 1
  elseif c >= 194 and c <= 223 then
    return 2
  elseif c >= 224 and c <= 239 then
    return 3
  elseif c >= 240 and c <= 244 then
    return 4
  else
    return 1 -- Fallback
  end
end

---Truncates a string to fit within a visual width.
---@param s string The string to truncate.
---@param screen_cols number The maximum visual width.
---@return string # The truncated string, possibly with an ellipsis.
function M.truncate(s, screen_cols)
  if screen_cols == 0 then
    return ''
  end

  local result = ''
  local last_char_bytes = nil
  local display_width = 0
  local i = 1
  while i <= #s do
    local char_bytes = M.char_byte_count(s, i)
    local char = s:sub(i, i + char_bytes - 1)
    local char_display_width = vim.api.nvim_strwidth(char)
    if display_width + char_display_width > screen_cols then
      if #result == 0 then
        return '…'
      elseif display_width + 1 <= screen_cols then
        return result .. '…'
      else
        return result:sub(1, #result-last_char_bytes) .. '…'
      end
    end
    result = result .. char
    display_width = display_width + char_display_width
    i = i + char_bytes
    last_char_bytes = char_bytes
  end
  return result
end

---Compares two keystrokes for sorting (case-insensitive, then case-sensitive).
---@param k1 string
---@param k2 string
---@return boolean # True if k1 should come before k2.
function M.keystroke_comparator(k1, k2)
  local lk1 = string.lower(k1)
  local lk2 = string.lower(k2)
  if lk1 == lk2 then
    return k1 < k2
  else
    return lk1 < lk2
  end
end

return M
