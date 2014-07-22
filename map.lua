local TILE=require 'tile' 
local map = {}

map.__index = map -- failed table lookups on the instances should fallback to the class table, to get methods

-- syntax equivalent to "map.new = function..."
function map.new(tiles)
  local self = setmetatable({}, map)
  self.tiles = tiles
  self.width = #tiles
  self.height = #tiles[1]
  return self
end

function map.getWidth(self)
  return self.width
end

function map.getHeight(self)
  return self.height
end

function map.getTile(self, x, y)
    -- Make sure we are inside the bounds. If we aren't, return null tile.
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return TILE.nullTile
    else
        return self.tiles[x][y] or TILE.nullTile
    end
end

return map
