local rot=require 'lib/rotLove/rotLove/rotLove'
local class=require 'middleclass'
local Tile=require 'Tile'
local Entity=require 'Entity'
local entities=require 'entities'

local Map = class('Map')

function Map:initialize(tiles, player)
  self._tiles = tiles
  self._width = #tiles
  self._height = #tiles[1]
  -- create a list which will hold the entities
  self._entities = {}
  -- create the engine and scheduler
  self._scheduler = rot.Scheduler:Simple()
  self._engine = rot.Engine(self._scheduler)
  -- add the player
  self:addEntityAtRandomPosition(player);
  -- add random fungi
  for i = 1, 1000 do
    self:addEntityAtRandomPosition(Entity:new(entities.FungusTemplate));
  end

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
    until self:getTile(x, y) ~= Tile.floorTile or self:getEntityAt(x, y)
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
        if v:getX() == x and v:getY() == y then return v end
    end
    return nil
end


function Map:addEntity(entity)
    -- Make sure the entity's position is within bounds
    if entity:getX() <= 0 or entity:getX() > self._width or
        entity:getY() <= 0 or entity:getY() > self._height then
        error('Adding entity out of bounds.')
    end
    -- Update the entity's map
    entity:setMap(self)
    -- Add the entity to the list of entities
    table.insert(self._entities, entity)
    -- Check if self entity is an actor, and if so add
    -- them to the scheduler
    if entity:hasMixin('Actor') then
       self._scheduler:add(entity, true)
    end
end


function Map:addEntityAtRandomPosition(entity)
    local position = self:getRandomFloorPosition()
    entity:setX(position.x)
    entity:setY(position.y)
    self:addEntity(entity)
end

return Map
