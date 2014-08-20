local rot=require 'lib/rotLove/rotLove/rotLove'
local class=require 'middleclass'
local Tile=require 'Tile'

local Builder = class('Map')

function Builder:initialize(width, height, depth)
	self._width = width
	self._height = height
	self._depth = depth
	self._tiles = {}
	self._regions = {}
    -- Instantiate the arrays to be multi-dimension
    for z = 1, depth do
        -- Create a new cave at each level
        self._tiles[z] = self:_generateLevel()
        -- Setup the regions array for each depth
        self._regions[z] = {}
        for x = 1, width do
            self._regions[z][x] = {}
            -- Fill with zeroes
            for y = 1, height do
                self._regions[z][x][y] = 0
            end
        end
    end
    for z = 0, self._depth do
        self:_setupRegions(z)
    end
    self:_connectAllRegions()
end

function Builder:_generateLevel()
    if arg[#arg] == "-debug" then require("mobdebug").off() end
    
    local map = {}
    -- Create the empty map
    for x = 1, self._width do
        map[x] = {}
    end
    -- Setup the map generator
    local randomgen = rot.RNG.LCG:new()
    randomgen:randomseed(os.clock())
    local generator = rot.Map.Cellular:new(self._width, self._height, nil, randomgen)
    generator:randomize(0.5)
    local totalIterations = 2
    -- Iteratively smoothen the map
    for i = 1, totalIterations do
        generator:create()
    end
    -- Smoothen it one last time and then update our map
    generator:create(function(x,y,v)
        if v == 1 then
            map[x][y] = Tile.floorTile
        else
            map[x][y] = Tile.wallTile
        end
    end)
    if arg[#arg] == "-debug" then require("mobdebug").on() end
    return map
end

function Builder:_canFillRegion(x, y, z)
    -- Make sure the tile is within bounds
    if x < 1 or y < 1 or z < 1 or x > self._width or
        y > self._height or z > self._depth then
        return false
    end
    -- Make sure the tile does not already have a region
    if self._regions[z][x][y] ~= 0 then
        return false
    end
    --if self._tiles[z][x][y] == nil then self._tiles[z][x][y] = Tile.nullTile end
    -- Make sure the tile is walkable
    return self._tiles[z][x][y]:isWalkable()
end

function Builder:_fillRegion(region, x, y, z)
    local tilesFilled = 1
    local tiles = {{x=x, y=y}}
    local tile
    local neighbors
    -- Update the region of the original tile
    self._regions[z][x][y] = region
    -- Keep looping while we still have tiles to process
    while #tiles > 0 do
        tile = table.remove(tiles)
        -- Get the neighbors of the tile
        neighbors = Tile.getNeighborPositions(tile.x, tile.y)
        -- Iterate through each neighbor, checking if we can use it to fill
        -- and if so updating the region and adding it to our processing
        -- list.
        while #neighbors > 0 do
            tile = table.remove(neighbors)
            if self:_canFillRegion(tile.x, tile.y, z) then
                self._regions[z][tile.x][tile.y] = region
                table.insert(tiles, tile)
                tilesFilled = tilesFilled + 1
            end
        end
    end
    return tilesFilled
end

-- This removes all tiles at a given depth level with a region number.
-- It fills the tiles with a wall tile.
function Builder:_removeRegion(region, z) 
    for x = 1, self._width do
        for y = 1, self._height do
            if self._regions[z][x][y] == region then
                -- Clear the region and set the tile to a wall tile
                self._regions[z][x][y] = 0
                self._tiles[z][x][y] = Tile.wallTile
            end
        end
    end
end

-- This sets up the regions for a given depth level.
function Builder:_setupRegions(z) 
    local region = 1
    local tilesFilled
    -- Iterate through all tiles searching for a tile that
    -- can be used as the starting point for a flood fill
    for x = 1, self._width do
        for y = 1, self._height do
            if self:_canFillRegion(x, y, z) then
                -- Try to fill
                tilesFilled = self:_fillRegion(region, x, y, z)
                -- If it was too small, simply remove it
                if tilesFilled <= 20 then
                    self:_removeRegion(region, z);
                else 
                    region = region + 1
                end
            end
        end
    end
end


-- This fetches a list of points that overlap between one
-- region at a given depth level and a region at a level beneath it.
function Builder:_findRegionOverlaps(z, r1, r2) 
    local matches = {}
    -- Iterate through all tiles, checking if they respect
    -- the region constraints and are floor tiles. We check
    -- that they are floor to make sure we don't try to
    -- put two stairs on the same tile.
    for x = 1, self._width do
        for y = 1, self._height do
            if self._tiles[z][x][y]  == Tile.floorTile and
                self._tiles[z+1][x][y] == Tile.floorTile and
                self._regions[z][x][y] == r1 and
                self._regions[z+1][x][y] == r2 then
                table.insert(matches, {x= x, y= y})
            end
        end
    end
    -- We shuffle the list of matches to prevent bias
    return shuffled(matches)
end

-- This tries to connect two regions by calculating 
-- where they overlap and adding stairs
function Builder:_connectRegions(z, r1, r2) 
    local overlap = self:_findRegionOverlaps(z, r1, r2)
    -- Make sure there was overlap
    if #overlap == 0 then
        return false
    end
    -- Select the first tile from the overlap and change it to stairs
    local point = overlap[1]
    self._tiles[z][point.x][point.y] = Tile.stairsDownTile
    self._tiles[z+1][point.x][point.y] = Tile.stairsUpTile
    return true
end

-- This tries to connect all regions for each depth level,
-- starting from the top most depth level.
function Builder:_connectAllRegions() 
    for z = 1, self._depth - 1 do
        -- Iterate through each tile, and if we haven't tried
        -- to connect the region of that tile on both depth levels
        -- then we try. We store connected properties as strings
        -- for quick lookups.
        local connected = {}
        local key
        for x = 1, self._width do
            for y = 1, self._height do
                key = self._regions[z][x][y] .. ',' .. self._regions[z+1][x][y]
                if self._tiles[z][x][y] == Tile.floorTile and
                    self._tiles[z+1][x][y] == Tile.floorTile and
                    connected[key] == nil then
                    -- Since both tiles are floors and we haven't 
                    -- already connected the two regions, try now.
                    self:_connectRegions(z, self._regions[z][x][y],
                        self._regions[z+1][x][y]);
                    connected[key] = true
                end
            end
        end
    end
end


function Builder:getTiles()
    return self._tiles
end

function Builder:getDepth()
    return self._depth
end

function Builder:getWidth()
    return self._width
end

function Builder:getHeight()
    return self._height
end

return Builder