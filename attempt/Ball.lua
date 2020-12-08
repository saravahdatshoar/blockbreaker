Ball = Class{}

function Ball:init(skin)
    self.width = 8
    self.height = 8
    self.dy = 0
    self.dx = 0

    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this
    self.skin = skin
end

-- checking if the ball hits something
function Ball:collides(target)
    
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false-- checking if edges don't overlap (ball in play)
    end
    
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false -- checking if edges don't overlap (ball in play)
    end 

    return true -- overlapping (collision)
end

-- starting point of ball
function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- ball bounces off walls rather than goes off screen
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function Ball:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    -- CHANGED FROM TUTORIAL
    love.graphics.draw(gTextures['main'], gFrames['balls'][self.skin],
        self.x, self.y)
end