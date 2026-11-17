local M = {}

function M.hex(str, alpha)
  local clean = str:gsub("#", "")
  local r = tonumber(clean:sub(1, 2), 16) / 255
  local g = tonumber(clean:sub(3, 4), 16) / 255
  local b = tonumber(clean:sub(5, 6), 16) / 255
  return { r, g, b, alpha or 1 }
end

function M.withAlpha(c, alpha)
  return { c[1], c[2], c[3], alpha }
end

return M
