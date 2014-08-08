local rot=require 'lib/rotLove/rotLove/rotLove'
local class=require 'middleclass'
local Tile=require 'Tile'

local Map = class('Map')

function Map:initialize(tiles)
  self._tiles = tiles
  self._width = #tiles
  self._height = #tiles[1]
  -- create a list which will hold the entities
  self._entities = {}
  -- create the engine and scheduler
  self._scheduler = rot.Scheduler.Simple()
  self._engine = rot.Engine(self._scheduler)
end

function Map:getEngine()
  return self._engine
end

function Map:getEntities()
  return self._entities
end

function Map:getWidth()
  return self._width
end

function Map:getHeight()
  return self._height
end

function Map:dig(x, y)
  -- If the tile is diggable, update it to a floor
  if self:getTile(x, y):isDiggable() then
    self._tiles[x][y] = Tile.floorTile
  end
end

function Map:getRandomFloorPosition()
    -- Randomly generate a tile which is a floor
    local x, y

    repeat
        x = math.random(1, self._width)
        y = math.random(1, self._height)
    until self:getTile(x, y) ~= Tile.floorTile
    return {x= x, y= y}
end


function Map:getTile(x, y)
    -- Make sure we are inside the bounds. If we aren't, return null Tile.
    if x < 1 or x > self._width or y < 1 or y > self._height then
        return Tile.nullTile
    else
        return self._tiles[x][y] or Tile.nullTile
    end
end

function Map:getEntityAt(x, y)
    -- Iterate through all entities searching for one with
    -- matching position
    for _,v in ipairs(self._entities) do
        if v.getX() == x and v.getY() == y then return v end
    end
    return nil
end

return Map
