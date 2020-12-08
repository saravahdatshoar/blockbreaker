--[[
    GD50
    Breakout Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally developed by Atari in 1976. An effective evolution of
    Pong, Breakout ditched the two-player mechanic in favor of a single-
    player game where the player, still controlling a paddle, was tasked
    with eliminating a screen full of differently placed bricks of varying
    values by deflecting a ball back at them.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.

    Credit for graphics (amazing work!):
    https://opengameart.org/users/buch

    Sara also used this pretty background:
    https://opengameart.org/content/starfield-background

    Credit for music (great loop):
    http://freesound.org/people/joshuaempyre/sounds/251461/
    http://www.soundcloud.com/empyreanma
    
    Sara also used this music (one of my favorite YT channels of all time):
    https://www.youtube.com/watch?v=wwhDXB7UX7o
    
]]

require 'src/Dependencies'


function love.load()
    -- crisp graphics
    love.graphics.setDefaultFilter('nearest', 'nearest')

    math.randomseed(os.time())
    love.window.setTitle('Breakout')

    -- fonts
    gFonts = {
        ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
        ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
        ['large'] = love.graphics.newFont('fonts/font.ttf', 32)
    }
    love.graphics.setFont(gFonts['small'])

    -- load up the graphics we'll be using throughout our states
    gTextures = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['main'] = love.graphics.newImage('graphics/breakout.png'),
        ['arrows'] = love.graphics.newImage('graphics/arrows.png'),
        ['hearts'] = love.graphics.newImage('graphics/hearts.png'),
        ['particle'] = love.graphics.newImage('graphics/particle.png')
    }

    -- Quads we will generate for all of our textures; Quads allow us
    -- to show only part of a texture and not the entire thing
    gFrames = {
        ['arrows'] = GenerateQuads(gTextures['arrows'], 24, 24),
        ['paddles'] = GenerateQuadsPaddles(gTextures['main']),
        ['balls'] = GenerateQuadsBalls(gTextures['main']),
        ['bricks'] = GenerateQuadsBricks(gTextures['main']),
        ['hearts'] = GenerateQuads(gTextures['hearts'], 10, 9),
        ['powerups'] = GenerateQuadsPowerups(gTextures['main']),}
    
    -- initializing dimensions, making sure they work when resized
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- sound effects
    gSounds = {
        ['paddle-hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall-hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
        ['select'] = love.audio.newSource('sounds/select.wav', 'static'),
        ['no-select'] = love.audio.newSource('sounds/no-select.wav', 'static'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav', 'static'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['victory'] = love.audio.newSource('sounds/victory.wav', 'static'),
        ['recover'] = love.audio.newSource('sounds/recover.wav', 'static'),
        ['high-score'] = love.audio.newSource('sounds/high_score.wav', 'static'),
        ['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),

        --CHANGED FROM TUTORIAL
        ['music'] = love.audio.newSource('sounds/dance_shadow.wav', 'static')
    }

    -- state machine used to update game states as player plays
    -- possible game states: 'start', 'paddle-select', 'serve', 'play', 'victory', 'game-over'
    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['serve'] = function() return ServeState() end,
        ['game-over'] = function() return GameOverState() end,
        ['victory'] = function() return VictoryState() end,
        ['high-scores'] = function() return HighScoreState() end,
        ['enter-high-score'] = function() return EnterHighScoreState() end,
        ['paddle-select'] = function() return PaddleSelectState() end
    }
    gStateMachine:change('start', {
        highScores = loadHighScores()
    })

    -- loop background music (even though it's ~20 min long)
    gSounds['music']:play()
    gSounds['music']:setLooping(true)

    -- keeping track of keys pressed
    love.keyboard.keysPressed = {}
end

-- resizing the window
function love.resize(w, h)
    push:resize(w, h)
end

-- performance consistency using dt (deltaTime)
function love.update(dt)
    gStateMachine:update(dt) -- pass dt into current game state
    love.keyboard.keysPressed = {} -- reset keys pressed
end

-- adding keys that are pressed once to current frame's table
function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

-- testing keystrokes
function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end

-- drawing objects in the game (paddle, bricks, etc.)
function love.draw()
    -- begin drawing with push
    push:apply('start')

    
    --background always fits game state and resolution
    local backgroundWidth = gTextures['background']:getWidth()
    local backgroundHeight = gTextures['background']:getHeight()

    love.graphics.draw(gTextures['background'], 
        -- draw at coordinates 0, 0 then scale to fill screen
        0, 0, 0, VIRTUAL_WIDTH / (backgroundWidth - 1), VIRTUAL_HEIGHT / (backgroundHeight - 1))
    
    -- ensuring using current game state
    gStateMachine:render()
    
    push:apply('end')
end

-- loading high scores from 'breakout' directory
function loadHighScores()
    love.filesystem.setIdentity('breakout')

    -- some default high scores to begin with
    if not love.filesystem.getInfo('breakout.lst') then
        local scores = ''
        for i = 5, 1, -1 do
            scores = scores .. 'Player\n'
            scores = scores .. tostring(i * 1000) .. '\n'
        end

        love.filesystem.write('breakout.lst', scores)
    end

    -- flag for whether we're reading a name or not
    local name = true
    local currentName = nil
    local counter = 1

    -- initialize scores table with at least 5 blank entries
    local scores = {}

    -- table holding high scores
    for i = 1, 10 do
        scores[i] = {
            name = nil,
            score = nil
        }
    end

    -- iterate over each line in the file, filling in names and scores
    for line in love.filesystem.lines('breakout.lst') do
        if name then
            scores[counter].name = string.sub(line, 1, 3)
        else
            scores[counter].score = tonumber(line)
            counter = counter + 1
        end

        -- flip the name flag
        name = not name
    end

    return scores
end

-- making the heart health
function renderHealth(health)
    local healthX = VIRTUAL_WIDTH - 100

    -- showing how much health is left
    for i = 1, health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], healthX, 4)
        healthX = healthX + 11
    end

    -- showing how much health is lost
    for i = 1, 3 - health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], healthX, 4)
        healthX = healthX + 11
    end
end

function renderKeys(keys) 
    love.graphics.draw(gTextures['main'], gFrames['powerups'][10], VIRTUAL_WIDTH - 40,  VIRTUAL_HEIGHT - 15, 0)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print("X "..keys, VIRTUAL_WIDTH - 20, VIRTUAL_HEIGHT - 15)
end

-- showing player's score
function renderScore(score)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)
    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end