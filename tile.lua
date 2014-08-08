local class=require 'middleclass'
local Glyph=require 'Glyph'

local Tile = class('Tile', Glyph)

function Tile:initialize(properties)
  Glyph.initialize(self, properties)
  properties = properties or {}
  self._isWalkable = properties.isWalkable or false
  self._isDiggable = properties.isDiggable or false
end

function Tile:isWalkable()
  return self._isWalkable
end

function Tile:isDiggable()
  return self._isDiggable
end

Tile.static.nullTile = Tile:new()
Tile.static.floorTile = Tile:new({
    character = '.',
    isWalkable = true
    })
Tile.static.wallTile = Tile:new({
    character = '#',
    foreground = 'goldenrod',
    isDiggable = true
    })

return Tile
