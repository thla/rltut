local class=require 'middleclass'
local Glyph=require 'Glyph'

local Tile = class('Tile', Glyph)

function Tile:initialize(properties)
  Glyph.initialize(self, properties)
  properties = properties or {}
  self._walkable = properties.isWalkable or false
  self._diggable = properties.isDiggable or false
  if properties.blocksLight == nil then self._blocksLight = true else self._blocksLight = properties.blocksLight end
end

function Tile:isWalkable()
  return self._walkable
end

function Tile:isDiggable()
  return self._diggable
end

function Tile:isBlockingLight()
  return self._blocksLight
end

function Tile.static.getNeighborPositions(x, y)
    local tiles = {};
    -- Generate all possible offsets
    for dX = -1, 1 do
        for dY = -1, 1 do
            -- Make sure it isn't the same tile
            if dX ~= 0 or dY ~= 0 then
                table.insert(tiles, {x= x + dX, y= y + dY})
            end
        end
    end
    return shuffled(tiles);
end

function shuffled(tab)
	local n, order, res = #tab, {}, {}

	for i=1,n do order[i] = { rnd = math.random(), idx = i } end
	table.sort(order, function(a,b) return a.rnd < b.rnd end)
	for i=1,n do res[i] = tab[order[i].idx] end
	return res
end

Tile.static.nullTile = Tile:new()

Tile.static.floorTile = Tile:new({
    character = '.',
    isWalkable = true,
    blocksLight = false
    })

Tile.static.wallTile = Tile:new({
    character = '#',
    foreground = 'goldenrod',
    isDiggable = true
    })

Tile.static.stairsUpTile = Tile:new({
    character = '<',
    foreground = 'white',
    isWalkable = true,
    blocksLight = false
    })

Tile.static.stairsDownTile = Tile:new({
    character = '>',
    foreground = 'white',
    isWalkable = true,
    blocksLight = false
})

return Tile
