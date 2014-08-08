local mixins = {}

-- Define our Moveable mixin
mixins.movable = {}

mixins.movable.name =  'Moveable'

function mixins.movable.tryMove(self, x, y, map)
    local tile = map:getTile(x, y)
    -- Check if we can walk on the tile
    --and if so simply walk onto it
    if tile:isWalkable() then
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

-- Player template
mixins.PlayerTemplate = {
    character= '@',
    foreground= 'white',
    background= 'black',
    mixins= {mixins.movable};
}

return mixins