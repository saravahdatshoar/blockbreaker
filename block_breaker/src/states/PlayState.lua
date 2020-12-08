--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

HIT_MAX = 40              -- capping how many times we can hit a brick to not get a powerup to make things easier
lockedBrick = false       -- checks if the the screen contains any locked bricks

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.keys = params.keys + 1

   self.recoverPoints = params.recoverPoints
   self.paddlePoints = params.paddlePoints

    -- give ball random starting velocity
    --self.ball.dx = math.random(-200, 200)
    self.ball[1].dy = math.random(-70, -80)

    self.powerup = { [1] = PowerUp(-5, -5, 4)}
       --tracks how many times the ball has had a collision. 100 - hitcount gives the number

       hitcount =  math.floor(self.health/3 * HIT_MAX) 
end


function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for i, b in pairs(self.ball) do
    b:update(dt)
    end
    for i, padhit in pairs(self.powerup) do
    padhit:update(dt)
    end
    
   for i, ballvar in pairs(self.ball) do
    if ballvar:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        ballvar.y = self.paddle.y - 8
        ballvar.dy = -ballvar.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ballvar.x < self.paddle.x + (self.paddle.width / 2) 
        and self.paddle.dx < 0 then
            ballvar.dx = -50 + -(8 *(self.paddle.x + self.paddle.width/2 - ballvar.x) 
                                           * 2 / self.paddle.size)
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ballvar.x > self.paddle.x + (self.paddle.width / 2) 
        and self.paddle.dx > 0 then
            ballvar.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width/2 - ballvar.x) 
                                            * 2 / self.paddle.size)
        end

        gSounds['paddle-hit']:play()
    end
    end
    
    -- checking if we got a powerup 
     for i, padhit in pairs(self.powerup) do
        if padhit:collide(self.paddle) then  --resetting the powerup
            padhit.y = self.paddle.y - 16
            table.remove(self.powerup,i)

            gSounds['paddle-hit']:play()
            gSounds['select']:play()


            if padhit.type == 4 then
            for i = 1, 4 do
            ballpw = Ball() --adding four more balls
            ballpw.skin = math.random(7)
            ballpw.x = self.ball[1].x
            ballpw.y = self.ball[1].y
            ballpw.dy = self.ball[1].dy + math.random(-15,15)
            ballpw.dx = self.ball[1].dx + math.random(-10,10)
            table.insert(self.ball,ballpw)
            end
        elseif padhit.type == 10 then
                self.keys = self.keys + 1
             end

        end
        if padhit.y > VIRTUAL_HEIGHT then
            table.remove(self.powerup,i)
        end
    
    end


    -- detect collision across all bricks with the ball
    for i, ballvar in pairs(self.ball) do
    for j, brick in pairs(self.bricks) do
        if brick.isLocked == true then
            lockedBrick = true
        end

        -- only check collision if we're in play                
        
        if brick.inPlay and ballvar:collides(brick) then

            -- if we have a key and we hit a locked brick, unlock/break brick
            if brick.isLocked == true and self.keys > 0 then
                brick.inPlay = false
                self.keys = self.keys - 1
                gSounds['brick-hit-1']:play()
                self.score = self.score + 200
            end
            
         -- locked bricks are affected differently
            hitcount = hitcount - 1
            if math.random(hitcount) == hitcount then
                table.insert(self.powerup, PowerUp(brick.x, brick.y, 4))
                hitcount =   math.floor(self.health/3 * HIT_MAX) --had to look up how to do this with love2d documentation 
                                  -- brick hit count reset
            elseif lockedBrick == true and math.random(math.floor(hitcount/2)) == math.floor(hitcount/2)  then
                table.insert(self.powerup, PowerUp(brick.x, brick.y, 10))
                hitcount =   math.floor(self.health/3 * HIT_MAX) 
            end

            if brick.isLocked == false then   
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
             -- hitting and breaking the block with our function
                brick:hit()
            else
                hitcount = hitcount - 1
                gSounds['no-select']:play()
            end
            

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            if self.score > self.paddlePoints then
                if self.paddle.size < 4 then
                self.paddle.size = self.paddle.size + 1
                self.paddle.width = self.paddle.size * 32
                end
                self.paddlePoints = math.min(120000, self.paddlePoints + 7000)
                -- paddle expansion sound is the same as recover
                gSounds['recover']:play()
            end

            
            
            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    paddlePoints = self.paddlePoints,
                    keys = self.keys
                })
            end

            --
            -- collision code for bricks

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ballvar.x + 2 < brick.x and ballvar.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ballvar.dx = -ballvar.dx
                ballvar.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ballvar.x + 6 > brick.x + brick.width and ballvar.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ballvar.dx = -ballvar.dx
                ballvar.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ballvar.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ballvar.dy = -ballvar.dy
                ballvar.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ballvar.dy = -ballvar.dy
                ballvar.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capadhiting at +- 150
            if math.abs(ballvar.dy) < 150 then
                ballvar.dy = ballvar.dy * 1.02
            end

            -- only allow colliding with one brici, for corners
            break
        end
    end
end

    -- if ball goes below bounds, revert to serve state and decrease health
    for j, ballvar in pairs(self.ball) do
        if ballvar.y > VIRTUAL_HEIGHT then
            table.remove(self.ball,j)
        end
    end
    if #self.ball == 0 then
        self.health = self.health - 1
        if self.paddle.size > 1 then
        self.paddle.size = self.paddle.size - 1
        self.paddle.width = self.paddle.size * 32
        self.keys = math.max(0, self.keys - 3)
        end
        gSounds['hurt']:play()
    
        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                paddlePoints = self.paddlePoints,
                keys = self.keys
            })
        end
    end

    -- for rendering particle systems
    for i, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.iuit()
    end
end

function PlayState:render()
    -- render bricks
    for i, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for i, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for i, b in pairs(self.ball) do
    b:render()
    end
    
    for i, padhit in pairs(self.powerup) do 
    padhit:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderKeys(self.keys)

    --love.graphics.print(tostring(hitcount),5,20)
    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for i, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end