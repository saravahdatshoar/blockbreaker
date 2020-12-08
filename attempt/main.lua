WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 700

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

Class = require 'class'
push = require 'push'

require 'Ball'

gameState = 'start'

function love.load()
    love.graphics.setDefaultFilter('nearest','nearest')

    smallFont = love.graphics.newFont('font.ttf',8)
    scoreFont = love.graphics.newFont('font.ttf',32)

    player1Y = 210
    player1X = VIRTUAL_WIDTH / 2 - 32
    player1dX = 0

    ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/2 - 2,5,5)

    push:setupScreen(VIRTUAL_WIDTH,VIRTUAL_HEIGHT,WINDOW_WIDTH,WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = false
    })
end

function love.update(dt)
    if love.keyboard.isDown('left') then
        player1dX = -PADDLE_SPEED
    elseif love.keyboard.isDown('right') then
        player1dX = PADDLE_SPEED
    else
        player1dX = 0
    end

    -- if love.keyboard.isDown('up') then
    --    player2Y = player2Y - PADDLE_SPEED * dt
    --elseif love.keyboard.isDown('down') then
    --    player2Y = player2Y + PADDLE_SPEED * dt
    --end
    

    if player1dX < 0 then
        player1X = math.max(0, player1X + player1dX * dt)
    else
        player1X = math.min(VIRTUAL_WIDTH - 64, player1X + player1dX * dt)
    end

    if gameState == 'play' then
        ball:update(dt)
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()

    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'
        else
            gameState = 'start'
            ball:reset()
        end
        
    end
end
function love.draw()
    push:apply('start')

    love.graphics.clear(40/225,45/225,52/255,1)

    love.graphics.setFont(smallFont)
    if gameState == 'start' then
        love.graphics.printf('BLOCK BREAKER', 0, 20, VIRTUAL_WIDTH,'center')
    --elseif gameState == 'play' then
    --    love.graphics.printf('Hello Play!', 0, 20, VIRTUAL_WIDTH,'center')
    end

    love.graphics.setFont(smallFont)
    --love.graphics.printf('BLOCK BREAKER', 0, 20, VIRTUAL_WIDTH,'center')

    love.graphics.setFont(scoreFont)
    --love.graphics.print(player1Score,VIRTUAL_WIDTH/2-50, VIRTUAL_HEIGHT/3)
    --love.graphics.print(player2Score,VIRTUAL_WIDTH/2+30, VIRTUAL_HEIGHT/3)

    love.graphics.rectangle('fill',player1X,player1Y,30,5) --player 1 brick
    --love.graphics.rectangle('fill',VIRTUAL_WIDTH/2-2,VIRTUAL_HEIGHT/2-2,4,4) --ball
    
    push:apply('end')
end