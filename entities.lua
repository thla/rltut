local game=require 'game'
local Entity=require 'Entity'
local Tile=require 'Tile'
local mixins = {}

-- Define our Moveable mixin
mixins.movable = {
    name = 'Moveable',
    tryMove = function(self, x, y, z, map)
        local map = self:getMap()
        local tile = map:getTile(x, y, self:getZ())
        local target = map:getEntityAt(x, y, self:getZ())
        -- If our z level changed, check if we are on stair
        if z < self:getZ() then
            if tile ~= Tile.stairsUpTile then
                mixins.sendMessage(self, "You can't go up here!")
            else
            	mixins.sendMessage(self, "You ascend to level %d!", {z})
                self:setPosition(x, y, z)
            end
        elseif z > self:getZ() then
            if tile ~= Tile.stairsDownTile then
                mixins.sendMessage(self, "You can't go down here!")
            else
                self:setPosition(x, y, z)
                mixins.sendMessage(self, "You descend to level %d!", {z})
            end  
        -- If an entity was present at the tile
        elseif target ~= nil then
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
            self:setPosition(x, y, z);
            return true
        elseif tile:isDiggable() then
            -- Check if the tile is diggable, and
            -- if so try to dig it
            map:dig(x, y, z)
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
         -- Clear the message queue
        self:clearMessages()
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
            if math.random() <= 0.004 then
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
                                                self:getY() + yOffset,
                                                self:getZ() ) then
                        local entity = Entity:new(mixins.FungusTemplate)
                        entity:setPosition(self:getX() + xOffset,
                        		self:getY() + yOffset, self:getZ())
                        self:getMap():addEntity(entity)
                        self._growthsRemaining = self._growthsRemaining - 1
                        
                        -- Send a message nearby!
                        mixins.sendMessageNearby(self:getMap(),
                            entity:getX(), entity:getY(), entity:getZ(), 
                            'The fungus is spreading!')
                        
                    end
                end
            end
        end
    end
}


mixins.Destructible = {
    name = 'Destructible',
    init = function(self, template)
        self._maxHp = template.maxHp or 10
        -- We allow taking in health from the template incase we want
        -- the entity to start with a different amount of HP than the
        -- max specified.
        self._hp = template.hp or self._maxHp
        self._defenseValue = template.defenseValue or 0
   end,
    getHp = function(self)
        return self._hp
    end,
    getMaxHp = function(self)
        return self._maxHp
    end,
    getDefenseValue = function(self)
        return self._defenseValue
    end,
    takeDamage = function(self, attacker, damage)
        self._hp = self._hp - damage
        -- If have 0 or less HP, then remove ourseles from the map
        if self._hp <= 0 then
            mixins.sendMessage(attacker, 'You kill the %s!', {self:getName()});
            mixins.sendMessage(self, 'You die!');
            self._map:removeEntity(self)
        end
    end
}

mixins.Attacker = {
    name = 'Attacker',
    groupName = 'Attacker',
    init = function(self, template) 
        self._attackValue = template.attackValue or 1
    end,
    getAttackValue = function(self) 
        return self._attackValue
    end,
    attack = function(self, target)
        -- If the target is destructible, calculate the damage
        -- based on attack and defense value
        if target:hasMixin('Destructible') then
        	local attack = self.getAttackValue(self)
        	local defense = target.getDefenseValue(self)
        	local max = math.max(0, attack - defense)
          local damage = math.random(1,max)
        	
        	mixins.sendMessage(self, 'You strike the %s for %i damage!', 
        		{target:getName(), damage})
        	mixins.sendMessage(target, 'The %s strikes you for %i damage!',  
        		{self:getName(), damage})
        	
            target:takeDamage(self, damage)
        end
    end
}      

mixins.MessageRecipient = {
    name = 'MessageRecipient',
    init = function(self, template) 
        self._messages = {}
    end,
    receiveMessage = function(self, message) 
        table.insert(self._messages, message)
    end,
    getMessages = function(self) 
        return self._messages
    end,
    clearMessages = function(self) 
        self._messages = {}
    end
}

mixins.sendMessage = function(recipient, message, args) 
    -- Make sure the recipient can receive the message 
    -- before doing any work.
    if recipient:hasMixin(mixins.MessageRecipient) then
        -- If args were passed, then we format the message, else
        -- no formatting is necessary
        if args ~= nil then
        	message = message:format(unpack(args))
        end
        recipient:receiveMessage(message)
    end
end

mixins.sendMessageNearby = function(map, centerX, centerY, centerZ, message, args) 
    -- If args were passed, then we format the message, else
    -- no formatting is necessary
    if args ~= nil then
        message = message:format(unpack(args))
    end
    -- Get the nearby entities
    entities = map:getEntitiesWithinRadius(centerX, centerY,centerZ, 5)
    -- Iterate through nearby entities, sending the message if
    -- they can receive it.
    for i = 1, #entities do
        if entities[i]:hasMixin(mixins.MessageRecipient) then
            entities[i]:receiveMessage(message)
        end
    end
end

-- Player template
mixins.PlayerTemplate = {
    character= '@',
    foreground= 'white',
	maxHp= 40,
    attackValue= 10,
    mixins= { mixins.movable, 
    		mixins.PlayerActor, 
    		mixins.Attacker, 
    		mixins.Destructible,
    		mixins.MessageRecipient}
}

mixins.FungusTemplate = {
	name = 'fungus',
    character ='P',
    foreground = 'green',
    maxHp=10,
    mixins = {mixins.FungusActor, mixins.Destructible}
}

return mixins
