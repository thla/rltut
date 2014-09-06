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
  -- create a table which will hold the entities
  self._entities = {}
  -- create the engine and scheduler
  self._scheduler = rot.Scheduler:Simple()
  self._engine = rot.Engine(self._scheduler)
  -- add the player
  self:addEntityAtRandomPosition(player, 1);
  -- Add random enemies to each floor.
  local templates = {entities.FungusTemplate, entities.BatTemplate, entities.NewtTemplate}
  for z = 1, self._depth do
	  for i = 1, 15 do
      -- Randomly select a template
      local template = templates[math.random(1,3)]
      -- Place the entity
      self:addEntityAtRandomPosition(Entity:new(template, entities), z)
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
    -- Get the entity based on position key
    return self._entities[x .. ',' .. y .. ',' .. z]
end


function Map:addEntity(entity)
    -- Update the entity's map
    entity:setMap(self)
    -- Update the map with the entity's position
    self:updateEntityPosition(entity)
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
    -- Remove the entity from the map
    local key = entity:getX() .. ',' .. entity:getY() .. ',' .. entity:getZ()
    if self._entities[key] == entity then
        self._entities[key] = nil
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
    for _,v in pairs(self._entities) do
      if (v:getX() >= leftX and
          v:getX() <= rightX and
          v:getY() >= topY and
          v:getY() <= bottomY and
          v:getZ() == centerZ) then
          table.insert(results, v)
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

function Map:updateEntityPosition (entity, oldX, oldY, oldZ)
    -- Delete the old key if it is the same entity and we have old positions.
    if oldX ~= nil then
        local oldKey = oldX .. ',' .. oldY .. ',' .. oldZ
        if self._entities[oldKey] == entity then
            self._entities[oldKey] = nil
        end
    end
    -- Make sure the entity's position is within bounds
    if entity:getX() < 1 or entity:getX() > self._width or
        entity:getY() < 1 or entity:getY() > self._height or
        entity:getZ() < 1 or entity:getZ() > self._depth then
        error("Entity's position is out of bounds.")
    end
    -- Sanity check to make sure there is no entity at the new position.
    local key = entity:getX() .. ',' .. entity:getY() .. ',' .. entity:getZ();
    if self._entities[key] then
        error('Tried to add an entity at an occupied position.')
    end
    -- Add the entity to the table of entities
    self._entities[key] = entity;
end

return Map
