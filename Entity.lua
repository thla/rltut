local class=require 'middleclass'
local Glyph=require 'Glyph'

local Entity = class('Entity', Glyph)

function Entity:initialize(properties)
    Glyph.initialize(self, properties)
    properties = properties or {}
    -- Instantiate properties to default if they weren't passed
    self._name = properties.name or ' '
    self._x = properties.x or 0
    self._y = properties.y or 0
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
            mixin.init(properties)
        end
    end
end

function Entity:hasMixin(obj)
  -- Allow passing the mixin itself or the name / group name as a string
    local _type = type(var);
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

return Entity
