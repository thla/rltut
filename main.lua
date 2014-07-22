local GAME=require 'game' 
local SCREENS=require 'screens' 

function love.load()
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    GAME.init()
    GAME.switchScreen(SCREENS.startScreen)
end

function love.draw() 
    GAME.getDisplay():draw() 
end

function love.keyreleased(key)
    GAME.handleInput(key)
end
