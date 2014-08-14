local game=require 'game'
local Entity=require 'Entity'
local mixins = {}

-- Define our Moveable mixin
mixins.movable = {
    name = 'Moveable',
    tryMove = function(self, x, y, map)
        local tile = map:getTile(x, y)
        local target = map:getEntityAt(x, y)
        -- If an entity was present at the tile
        if target ~= nil then
            -- If we are an attacker, try to attack
            -- the target
            if self:hasMixin('Attacker') then
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
            self._x = x
            self._y = y
            return true
        elseif tile:isDiggable() then
            -- Check if the tile is diggable, and
            -- if so try to dig it
            map:dig(x, y)
            return true
        end
        return false
    end
}

-- Main player's actor mixin
mixins.PlayerActor = {
    name = 'PlayerActor',
    groupName = 'Actor',
    act = function(self)
        -- Re-render the screen
        game.refresh()
        -- Lock the engine and wait asynchronously
        -- for the player to press a key.
        self._map:getEngine():lock()
    end
}


mixins.FungusActor = {
    name = 'FungusActor',
    groupName = 'Actor',
    init = function(self)
        self._growthsRemaining = 5
    end,
    act = function(self)
        if self._growthsRemaining > 0 then
            if math.random() <= 0.02 then
                -- Generate the coordinates of a random adjacent square by
                -- generating an offset between [-1, 0, 1] for both the x and
                -- y directions. To do this, we generate a number from 0-2 and then
                -- subtract 1.
                local xOffset = math.random(-1,1)
                local yOffset = math.random(-1,1)
                -- Make sure we aren't trying to spawn on the same tile as us
                if xOffset ~= 0 or yOffset ~= 0 then
                    -- Check if we can actually spawn at that location, and if so
                    -- then we grow!
                    if self:getMap():isEmptyFloor(self:getX() + xOffset,
                                                self:getY() + yOffset) then
                        local entity = Entity:new(mixins.FungusTemplate)
                        entity:setX(self:getX() + xOffset)
                        entity:setY(self:getY() + yOffset)
                        self:getMap():addEntity(entity)
                        self._growthsRemaining = self._growthsRemaining - 1
                    end
                end
             end
        end
    end
}


mixins.Destructible = {
    name = 'Destructible',
    init = function(self)
        self._hp = 1
    end,
    takeDamage = function(self, attacker, damage)
        self._hp = self._hp - damage
        -- If have 0 or less HP, then remove ourseles from the map
        if self._hp <= 0 then
            self._map:removeEntity(self)
        end
    end
}

mixins.SimpleAttacker = {
    name = 'SimpleAttacker',
    groupName = 'Attacker',
    attack = function(self, target)
        -- Only remove the entity if they were attackable
        if target:hasMixin('Destructible') then
            target:takeDamage(self, 1)
        end
    end
}

-- Player template
mixins.PlayerTemplate = {
    character= '@',
    foreground= 'white',
    background= 'black',
    mixins= { mixins.movable, mixins.PlayerActor, mixins.SimpleAttacker, mixins.Destructible}
}

mixins.FungusTemplate = {
    character ='F',
    foreground = 'green',
    mixins = {mixins.FungusActor, mixins.Destructible}
}

return mixins
