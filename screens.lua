local rot=require 'lib/rotLove/rotLove/rotLove'
local game=require 'game'
local Tile=require 'Tile'
local Map=require 'Map'
local Entity=require 'Entity'
local entities=require 'entities'


local screens = {}

-- private variables
local _color = rot.Color()
local _map = {}
local _player

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
end

function screens.startScreen.handleInput(key, isrepeat)
    if not isrepeat and key == "return" then
        game.switchScreen(screens.playScreen)
    end
end

-- Define our playing screen
screens.playScreen = {}

function screens.playScreen.enter()
    if arg[#arg] == "-debug" then require("mobdebug").off() end

    local map = {}
    -- Create a map based on our size parameters
    local mapWidth = 100
    local mapHeight = 48
    for x = 1, mapWidth do
        map[x] = {}
        for y = 1, mapHeight do
            map[x][y] = Tile.nullTile
        end
    end
    -- Setup the map generator
    local generator = rot.Map.Cellular:new(mapWidth, mapHeight)
    generator:randomize(0.5)
    local totalIterations = 2
    -- Iteratively smoothen the map
    for i = 0, totalIterations - 1 do
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
    -- Create our player and set the position
    _player = Entity:new(entities.PlayerTemplate)
    -- Create our map from the tiles
    _map = Map:new(map, _player)
    -- Start the map's engine
    _map:getEngine():start()
end

function screens.playScreen.move(dX, dY)
    -- Positive dX means movement right
    -- negative means movement left
    -- 0 means none
    local newX = _player:getX() + dX
    local newY = _player:getY() + dY
    -- Try to move to the new cell
    _player:tryMove(newX, newY, _map)
 end

function screens.playScreen.exit()
    print("Exited play screen.")
end

function screens.playScreen.render(display)
    local screenWidth = game.getScreenWidth()
    local screenHeight = game.getScreenHeight()
    -- Make sure the x-axis doesn't go to the left of the left bound
    local topLeftX = math.max(0, _player:getX() - (screenWidth / 2))
    -- Make sure we still have enough space to fit an entire game screen
    topLeftX = math.min(topLeftX, _map:getWidth() - screenWidth)
    -- Make sure the y-axis doesn't above the top bound
    local topLeftY = math.max(0, _player:getY() - (screenHeight / 2))
    -- Make sure we still have enough space to fit an entire game screen
    topLeftY = math.min(topLeftY, _map:getHeight() - screenHeight)

    -- Iterate through all map cells
    for x = topLeftX + 1, topLeftX + screenWidth do
        for y = topLeftY + 1, topLeftY + screenHeight do
            -- Fetch the glyph for the tile and render it to the screen
            -- at the offset position.
            local tile = _map:getTile(x, y)
            display:write(
                tile:getChar(),
                x - topLeftX,
                y - topLeftY,
                _color:fromString(tile:getForeground()),
                _color:fromString(tile:getBackground()))
        end
    end

    -- Render the entities
    for _, entity in ipairs(_map:getEntities()) do
        -- Only render the entitiy if they would show up on the screen
        if entity:getX() > topLeftX and entity:getY() > topLeftY and
            entity:getX() <= topLeftX + screenWidth and
            entity:getY() <= topLeftY + screenHeight then
            display:write(
                entity:getChar(),
                entity:getX() - topLeftX,
                entity:getY() - topLeftY,
                _color:fromString(entity:getForeground()),
                _color:fromString(entity:getBackground()))
        end
    end

	-- Get the messages in the player's queue and render them
	local messages = _player:getMessages()
	local messageY = 1
	for i = 1, #messages do
		-- Draw each message, adding the number of lines
		display:write(
			 messages[i],
			1, 
			messageY,
			_color:fromString('white'),
			_color:fromString('black')
		)
		messageY = messageY + 1
	end
     
	-- Render player HP 
	display:write(
		string.format('HP: %i/%i ', _player:getHp(), _player:getMaxHp()),	
		1, 
		screenHeight + 1,
		_color:fromString('white'),
		_color:fromString('black')
	)
end


function screens.playScreen.handleInput(key, isrepeat)
    -- If enter is pressed, go to the win screen
    -- If escape is pressed, go to lose screen
    if not isrepeat then
        if key == "return" then
            game.switchScreen(screens.winScreen)
        elseif key == "escape" then
            game.switchScreen(screens.loseScreen)
        end
    end
    -- Movement
    if key == "left" then
        screens.playScreen.move(-1, 0)
    elseif key == "right" then
        screens.playScreen.move(1, 0)
    elseif key == "up" then
        screens.playScreen.move(0, -1)
    elseif key == "down" then
        screens.playScreen.move(0, 1)
    end
    -- Unlock the engine
    _map:getEngine():unlock()
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

function screens.winScreen.handleInput(key, isrepeat)
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

function screens.loseScreen.handleInput(key, isrepeat)
    -- Nothing to do here
end


return screens
