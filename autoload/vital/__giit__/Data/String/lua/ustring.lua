local M = {_TYPE = "module", _NAME = "ustring"}
local utf8
local strwidth
local strlen

if utf8 == nil then
  ok, utf8 = pcall(require, 'lua-utf8')
  if not ok then
    local escape_quotes = function(x) return string.gsub(x, '"', '\\"') end
    M.width = function(x)
      return vim.eval(string.format('strwidth("%s")', escape_quotes(x)))
    end
    M.len = function(x)
      return vim.eval(string.format('strchars("%s")', escape_quotes(x)))
    end
    utf8 = nil
  end
end

if utf8 then
  local ambi_is_double = vim.eval('&ambiwidth') == 'double'
  M.width = function(x) return utf8.width(x, ambi_is_double, 1) end
  M.len = utf8.len
end

return M
