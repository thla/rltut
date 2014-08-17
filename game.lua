local rot=require 'lib/rotLove/rotLove/rotLove'
local game = {}

-- private variables
local _display = nil
local _currentScreen = nil
local _screenWidth = 80
local _screenHeight = 24

function game.init()
    -- Any necessary initialization will go here.
    _display = rot.Display(_screenWidth, _screenHeight + 1)
end

function game.getDisplay()
    return _display
end


function game.switchScreen(screen)
    -- If we had a screen before, notify it that we exited
    if _currentScreen ~= nil then
        _currentScreen.exit()
    end
    -- Clear the display
    _display:clearCanvas()
    -- Update our current screen, notify it we entered
    -- and then render it
    _currentScreen = screen
    if _currentScreen ~= nil then
        _currentScreen.enter()
        game.refresh()
    end
end


function game.handleInput(key, isrepeat)
    if _currentScreen ~= nil then
        -- Send the event type and data to the screen
        _currentScreen.handleInput(key, isrepeat)
    end
end


function game.refresh()
    -- Clear the screen
    _display:clear()
    -- Render the screen
    _currentScreen.render(_display)
end


function game.getScreenWidth()
    return _screenWidth
end


function game.getScreenHeight()
    return _screenHeight
end

return game
