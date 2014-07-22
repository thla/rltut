local GLYPH=require 'glyph'
local tile = {}

tile.__index = tile -- failed table lookups on the instances should fallback to the class table, to get methods

-- syntax equivalent to "tile.new = function..."
function tile.new(glyph)
  local self = setmetatable({}, tile)
  self.glyph = glyph
  return self
end

function tile.getGlyph(self)
  return self.glyph
end

tile.nullTile = tile.new(GLYPH.new())
tile.floorTile = tile.new(GLYPH.new('.'))
tile.wallTile = tile.new(GLYPH.new('#', 'goldenrod'))

return tile