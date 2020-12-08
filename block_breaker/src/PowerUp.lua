PowerUp = Class{}

function PowerUp:init(x, y, type) -- starting positions and type of powerup we're using
    self.x = x
    self.y = y
    self.type = type
    self.PowerUpSpawned = false --initially, no powerups spawned
end

function PowerUp:update(dt)
    if self.x > 0 and self.y > 0 then
        self.PowerUpSpawned = true
    end

    if self.PowerUpSpawned == true then
    self.y = self.y + 1
    end
end

--picking the powerups to use from the spritesheet and drawing it
function PowerUp:render()  
    if self.PowerUpSpawned == true then   
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type], self.x + 8, self.y)                                         
    end

end

-- seeing whether the powerups makes contact with any object
function PowerUp:collide(target)
    if self.y + 16 < target.y 
    or self.y > target.y + target.height 
    or self.x + 16 < target.x or 
    self.x > target.x + target.width then
        return false
    else
        return true
    end
end

