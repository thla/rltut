local GAME=require 'game' 
local SCREENS=require 'screens' 

function love.load()
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    love.keyboard.setKeyRepeat(true)
    GAME.init()
    GAME.switchScreen(SCREENS.startScreen)
end

function love.draw() 
    GAME.getDisplay():draw() 
end


function love.keypressed( key, isrepeat )
    GAME.handleInput(key, isrepeat )
end
  
