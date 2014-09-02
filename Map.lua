local rot=require 'lib/rotLove/rotLove/rotLove'
local class=require 'middleclass'
local Tile=require 'Tile'
local Entity=require 'Entity'
local entities=require 'entities'

local Map = class('Map')

function Map:initialize(tiles, player)
  self._tiles = tiles
  self._depth = #tiles
  self._width = #tiles[1]
  self._height = #tiles[1][1]
  -- setup the field of visions
  self._fov = {}
  self:setupFov()
  -- create a list which will hold the entities
  self._entities = {}
  -- create the engine and scheduler
  self._scheduler = rot.Scheduler:Simple()
  self._engine = rot.Engine(self._scheduler)
  -- add the player
  self:addEntityAtRandomPosition(player, 1);
  -- add random fungi
  for z = 1, self._depth do
	  for i = 1, 25 do
		self:addEntityAtRandomPosition(Entity:new(entities.FungusTemplate), z)
	  end
  end
  -- Setup the explored array
  self._explored = {}
  self:_setupExploredArray()
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

function Map:getDepth()
  return self._depth
end

function Map:dig(x, y, z)
  -- If the tile is diggable, update it to a floor
  if self:getTile(x, y, z):isDiggable() then
    self._tiles[z][x][y] = Tile.floorTile
  end
end

function Map:getRandomFloorPosition(z)
    -- Randomly generate a tile which is a floor
    local x, y

    repeat
        x = math.random(1, self._width)
        y = math.random(1, self._height)
    until self:isEmptyFloor(x, y, z)
    return {x= x, y= y, z= z}
end


function Map:getTile(x, y, z)
    -- Make sure we are inside the bounds. If we aren't, return null Tile.
    if x < 1 or x > self._width or y < 1 or y > self._height or
        z < 1 or z > self._depth then
        return Tile.nullTile
    else
        return self._tiles[z][x][y] or Tile.nullTile
    end
end


function Map:getEntityAt(x, y, z)
    -- Iterate through all entities searching for one with
    -- matching position
    for _,v in ipairs(self._entities) do
        if v:getX() == x and v:getY() == y and  v:getZ() == z then return v end
    end
    return nil
end


function Map:addEntity(entity)
    -- Make sure the entity's position is within bounds
    if entity:getX() <= 0 or entity:getX() > self._width or
        entity:getY() <= 0 or entity:getY() > self._height or
        entity:getZ() <= 0 or entity:getZ() > self._depth then
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


function Map:addEntityAtRandomPosition(entity, z)
    local position = self:getRandomFloorPosition(z)
    entity:setX(position.x)
    entity:setY(position.y)
    entity:setZ(position.z)
    self:addEntity(entity)
end

function Map:removeEntity(entity)
    -- Find the entity in the list of entities if it is present
    for  i = 1, #(self._entities) do
        if self._entities[i] == entity then
            table.remove(self._entities, i)
            break
        end
    end
    -- If the entity is an actor, remove them from the scheduler
    if entity:hasMixin('Actor') then
        self._scheduler:remove(entity)
    end
end

function Map:isEmptyFloor(x, y, z)
    -- Check if the tile is floor and also has no entity
    return self:getTile(x, y, z) == Tile.floorTile and self:getEntityAt(x, y, z) == nil
end

function Map:getEntitiesWithinRadius(centerX, centerY, centerZ, radius)
	local results = {}
    local leftX = centerX - radius
    local rightX = centerX + radius
    local topY = centerY - radius
    local bottomY = centerY + radius
    -- Iterate through our entities, adding any which are within the bounds
    for i = 1, #self._entities do
        if (self._entities[i]:getX() >= leftX and
            self._entities[i]:getX() <= rightX and
            self._entities[i]:getY() >= topY and
            self._entities[i]:getY() <= bottomY and
            self._entities[i]:getZ() == centerZ) then
            table.insert(results, self._entities[i])
        end
    end
    return results
end

function Map:setupFov()
  for i=1,self._depth do
    table.insert(self._fov, rot.FOV.Precise:new(
        function(t, x, y)
          return not self:getTile(x, y, i):isBlockingLight()
        end
      ))
  end
end

function Map:getFov(depth)
  return self._fov[depth]
end

function Map:setExplored (x, y, z, state)
    -- Only update if the tile is within bounds
    if self:getTile(x, y, z) ~= Tile.nullTile then
        self._explored[z][x][y] = state
    end
end

function Map:isExplored (x, y, z)
    -- Only return the value if within bounds
    if self:getTile(x, y, z) ~= Tile.nullTile then
        return self._explored[z][x][y]
    else
        return false
    end
end

function Map:_setupExploredArray ()
  for z=1,self._depth do
    self._explored[z] = {}
    for x=1,self._width do
      self._explored[z][x] = {}
      for y=1,self._height do
        self._explored[z][x][y] = false
      end
    end
  end
end

return Map
