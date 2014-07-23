local ROT=require 'lib/rotLove/rotLove/rotLove'
local GAME=require 'game' 
local TILE=require 'tile' 
local MAP=require 'map' 

local screens = {}

-- private variables
local _color = ROT.Color()
local _map = {}
local _centerX = 0
local _centerY = 0

-- Define our initial start screen
screens.startScreen = {}

function screens.startScreen.enter()
    print("Entered start screen.")
end

function screens.startScreen.exit()
    print("Exited start screen.")
end

function screens.startScreen.render(display)
    -- Render our prompt to the screen
    display:write("Javascript Roguelike",1,1, _color:fromString("yellow"))
    display:write("Press [Enter] to start!",1,2)
    display:write("j",80,24)
end
    
function screens.startScreen.handleInput(key)
    if key == "return" then
        GAME.switchScreen(screens.playScreen)
    end
end

-- Define our playing screen
screens.playScreen = {}

function callback(x,y,v)
  
end

function screens.playScreen.enter()
    local map = {}
    -- Create a map based on our size parameters
    local mapWidth = 80
    local mapHeight = 24
    for x = 1, mapWidth do
        map[x] = {}
        for y = 1, mapHeight do
            map[x][y] = TILE.nullTile
        end
    end
    -- Setup the map generator
    local generator = ROT.Map.Cellular:new(mapWidth, mapHeight)
    generator:randomize(0.5)
    local totalIterations = 2
    -- Iteratively smoothen the map
    for i = 0, totalIterations - 1 do
        generator:create()
    end
    -- Smoothen it one last time and then update our map
    generator:create(function(x,y,v) 
        if v == 1 then
            map[x][y] = TILE.floorTile
        else
            map[x][y] = TILE.wallTile
        end       
    end)
    -- Create our map from the tiles
    _map = MAP.new(map);    
end

function screens.playScreen.move(dX, dY)
    -- Positive dX means movement right
    -- negative means movement left
    -- 0 means none
    _centerX = math.max(1,
        math.min(_map.getWidth() - 1, _centerX + dx))
    -- Positive dY means movement down
    -- negative means movement up
    -- 0 means none
    _centerY = math.max(1,
        math.min(_map.getHeight() - 1, _centerY + dY))
 end

function screens.playScreen.exit()
    print("Exited play screen.")
end

function screens.playScreen.render(display)
    -- Iterate through all map cells
    for x = 1, _map:getWidth() do
        for y = 1, _map:getHeight() do
            -- Fetch the glyph for the tile and render it to the screen
            local glyph = _map:getTile(x, y):getGlyph()
            display:write(
                glyph:getChar(),
                x, y,
                _color:fromString(glyph:getForeground()), 
                _color:fromString(glyph:getBackground()))
        end
    end
end

function screens.playScreen.handleInput(key)
    -- If enter is pressed, go to the win screen
    -- If escape is pressed, go to lose screen
    if key == "return" then
        GAME.switchScreen(screens.winScreen)
    elseif key == "escape" then
        GAME.switchScreen(screens.loseScreen)
    end
end


-- Define our winning screen
screens.winScreen = {}

function screens.winScreen.enter()
    print("Entered win screen.")
end

function screens.winScreen.exit()
    print("Exited win screen.")
end

function screens.winScreen.render(display)
    -- Render our prompt to the screen
    for i=2,23 do
      display:write("You win!",3,i,nil,
        {r=math.random(0, 255),g=math.random(0, 255),b=math.random(0, 255),a=255})
    end
end

function screens.winScreen.handleInput(key)
    -- Nothing to do here 
end


-- Define our losing screen
screens.loseScreen  = {}

function screens.loseScreen.enter()
    print("Entered lose screen.")
end

function screens.loseScreen.exit()
    print("Exited lose screen.")
end

function screens.loseScreen.render(display)
    -- Render our prompt to the screen
    for i=2,23 do
        display:write("You lose! :(",3,i,nil,_color:fromString("red"))
    end
end

function screens.loseScreen.handleInput(key)
    -- Nothing to do here 
end


return screens