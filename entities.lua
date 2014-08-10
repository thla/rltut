local game=require 'game'
local mixins = {}

-- Define our Moveable mixin
mixins.movable = {}

mixins.movable.name = 'Moveable'

function mixins.movable.tryMove(self, x, y, map)
    local tile = map:getTile(x, y)
    local target = map:getEntityAt(x, y)
    -- If an entity was present at the tile, then we
    -- can't move there
    if (target ~= nil) then
        return false;
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


-- Main player's actor mixin
mixins.PlayerActor = {
    name = 'PlayerActor',
    groupName = 'Actor',
    act = function()
        -- Re-render the screen
        -- game.refresh()
        -- Lock the engine and wait asynchronously
        -- for the player to press a key.
        -- map:getEngine():lock()
    end
}


-- Player template
mixins.PlayerTemplate = {
    character= '@',
    foreground= 'white',
    background= 'black',
    mixins= {mixins.movable, mixins.PlayerActor}
}


mixins.FungusActor = {
    name = 'FungusActor',
    groupName = 'Actor',
    act = function()
    end
}


mixins.FungusTemplate = {
    character ='F',
    foreground = 'green',
    mixins = {mixins.FungusActor}
}


return mixins
