local game=require 'game'
local screens=require 'screens'

function love.load()
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    love.keyboard.setKeyRepeat(true)
    game.init()
    game.switchScreen(screens.startScreen)
end

function love.draw()
    game.getDisplay():draw()
end

function love.keypressed( key, isrepeat )
    game.handleInput(key, isrepeat )
end

