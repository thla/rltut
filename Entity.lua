local class=require 'middleclass'
local Glyph=require 'Glyph'
local Tile=require 'Tile'

local Entity = class('Entity', Glyph)

local modmixins

function Entity:initialize(properties, modmix)
    Glyph.initialize(self, properties)
    modmixins = modmix
    properties = properties or {}
    -- Instantiate properties to default if they weren't passed
    self._name = properties.name or ' '
    self._x = properties.x or 0
    self._y = properties.y or 0
    self._z = properties.z or 0
    self._map = nil
    -- Create an object which will keep track what mixins we have
    -- attached to this entity based on the name property
    self._attachedMixins = {}
    -- Create a similar object for groups
    self._attachedMixinGroups = {}
    local mixins = properties.mixins or {}
    for _,mixin in ipairs(mixins) do
        -- Copy over all properties from each mixin as long
        -- as it's not the name or the init property. We
        -- also make sure not to override a property that
        -- already exists on the entity.
        for k,v in pairs(mixin) do
            if k ~= 'init' and k ~= 'name' and self[k] == nil then
                self[k] = v
            end
        end
        -- Add the name of this mixin to our attached mixins
        self._attachedMixins[mixin.name] = true
        -- If a group name is present, add it
        if mixin.groupName then
            self._attachedMixinGroups[mixin.groupName] = true
        end
        -- Finally call the init function if there is one
        if mixin.init then
            mixin.init(self, properties)
        end
    end
end

function Entity:hasMixin(obj)
  -- Allow passing the mixin itself or the name / group name as a string
    local _type = type(obj);
    if _type == "table" then
      return self._attachedMixins[obj.name]
    else
      return self._attachedMixins[obj] or self._attachedMixinGroups[obj]
    end
end


function Entity:setName(name)
  self._name = name
end

function Entity:setX(x)
  self._x = x
end

function Entity:setY(y)
  self._y = y
end

function Entity:setZ(z)
    self._z = z
end

function Entity:getZ()
    return self._z
end

function Entity:getName()
  return self._name
end

function Entity:getX()
  return self._x
end

function Entity:getY()
  return self._y
end

function Entity:setMap(map)
  self._map = map
end

function Entity:getMap()
  return self._map
end

function Entity:setPosition(x,y,z)
    local oldX = self._x
    local oldY = self._y
    local oldZ = self._z
    -- Update position
    self._x = x
    self._y = y
    self._z = z
    -- If the entity is on a map, notify the map that the entity has moved.
    if self._map ~= nil then
        self._map:updateEntityPosition(self, oldX, oldY, oldZ)
    end
end

function Entity:tryMove(x, y, z, map)
    local map = self:getMap()
    local tile = map:getTile(x, y, self:getZ())
    local target = map:getEntityAt(x, y, self:getZ())
    -- If our z level changed, check if we are on stair
    if z < self:getZ() then
        if tile ~= Tile.stairsUpTile then
            modmixins.sendMessage(self, "You can't go up here!")
        else
            modmixins.sendMessage(self, "You ascend to level %d!", {z})
            self:setPosition(x, y, z)
        end
    elseif z > self:getZ() then
        if tile ~= Tile.stairsDownTile then
            modmixins.sendMessage(self, "You can't go down here!")
        else
            self:setPosition(x, y, z)
            modmixins.sendMessage(self, "You descend to level %d!", {z})
        end
    -- If an entity was present at the tile
    elseif target ~= nil then
        -- An entity can only attack if the entity has the Attacker mixin and
        -- either the entity or the target is the player.
        if self:hasMixin('Attacker') and
          (self:hasMixin(modmixins.PlayerActor) or
          target:hasMixin(modmixins.PlayerActor)) then
            self:attack(target)
            return true
        else
            -- If not nothing we can do, but we can't
            -- move to the tile
            return false
        end
    -- Check if we can walk on the tile
    --and if so simply walk onto it
    elseif tile:isWalkable() then
        -- Update the entity's position
        self:setPosition(x, y, z);
        return true
    elseif tile:isDiggable() then
        -- Only dig if the the entity is the player
        if self:hasMixin(modmixins.PlayerActor) then
            map:dig(x, y, z)
            return true
        end
        -- If not nothing we can do, but we can't
        -- move to the tile
        return false
    end
    return false
end

return Entity
