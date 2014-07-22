local glyph = {}
glyph.__index = glyph -- failed table lookups on the instances should fallback to the class table, to get methods

-- syntax equivalent to "glyph.new = function..."
function glyph.new(chr, fg, bg)
  local self = setmetatable({}, glyph)
  self.chr = chr or ' '
  self.fg = fg or 'white'
  self.bg = bg or 'black'
  return self
end

function glyph.getChar(self)
  return self.chr
end

function glyph.getBackground(self)
  return self.bg
end

function glyph.getForeground(self)
  return self.fg
end

return glyph