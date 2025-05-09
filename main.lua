local anim8 = require 'anim8'

gravity = 500
ground = 400
level1Text = "You might want to get Over that"
myFont = love.graphics.newFont("PixeloidSans.ttf", 36)
level1Environment = {}


-- ALT + L to run
function love.load()
    local screenWidth = love.graphics.getWidth()
    --init player
    player = {
        x = 400,
        y = ground,
        width = 20,
        height = 110,
        speed = 200,
        vy = 0,
        jumpVelocity = 300,
        onGround = false,
        playerImage = love.graphics.newImage("images/player.bmp")
    }

    --level 1 obj
    level1Egg = {
        x = 456,
        y = 183,
        width = 19,
        height = 32,
        vy = 0,
        vx = 0,
        angle = 0,
        isFlying = false,
        onGround = false,
        isPushable = true
    }
    level1Wall = {
        x = screenWidth - 100,
        y = 300, 
        width = 100, 
        height = 100
    }
    level1Ground = {
        x = 0, 
        y = ground,
        width = love.graphics.getWidth(), 
        height = 32
    }
    level1Environment = {level1Egg, level1Wall, level1Ground}
    
    --load fonts
    love.graphics.setFont(myFont)

    --load animating mustache
    spriteSheet = love.graphics.newImage("images/Sprite-0002-Sheet.png")
    local g = anim8.newGrid(32, 32, spriteSheet:getWidth(), spriteSheet:getHeight())
    animation = anim8.newAnimation(g('1-4',1), 0.6) -- 4 frames, 0.1s each

    --music
    -- backgroundMusic = love.audio.newSource("audio/puzzle-game-first-try.ogg", "stream")
    -- backgroundMusic:setLooping(true)
    -- backgroundMusic:play()
end

function love.update(dt)
    local dx = 0

    -- Left/right input
    if love.keyboard.isDown("left") then
        dx = -player.speed * dt
    elseif love.keyboard.isDown("right") then
        dx = player.speed * dt
    end

    -- Jumping
    if love.keyboard.isDown("space") and player.onGround then
        player.vy = -player.jumpVelocity
    end

    -- Apply gravity
    player.vy = player.vy + gravity * dt
    local dy = player.vy * dt

    resolveCollisions(player, level1Environment, dx, dy)

    if level1Egg.isFlying then
        -- Apply gravity and fall
        level1Egg.vy = level1Egg.vy + gravity * dt
        level1Egg.y = level1Egg.y + level1Egg.vy * dt

        -- Some Horizontal movement to fling
        level1Egg.x = level1Egg.x + level1Egg.vx * dt
    
        -- Rotate while flying
        level1Egg.angle = level1Egg.angle + 5 * dt
    
        -- Stop at the ground (like any falling object)
        local groundY = ground - level1Egg.height
        if level1Egg.y >= groundY then
            level1Egg.y = groundY
            level1Egg.vy = 0
            level1Egg.vx = 0
            level1Egg.angle = 0
            level1Egg.isFlying = false
            level1Egg.onGround = true
        end
    end

    animation:update(dt)
    
    -- block off screen
    local screenWidth = love.graphics.getWidth()
    player.x = math.max(0, math.min(player.x, screenWidth))
    
end

function love.draw()
    --draw the ground
    love.graphics.line(level1Ground.x,level1Ground.y,level1Ground.width,level1Ground.y)

    --draw the player
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.draw(player.playerImage, player.x, player.y) -- x, y position
    -- love.graphics.rectangle("fill", player.x,  player.y - player.height, player.width, player.height)
    love.graphics.setColor(1, 1, 1)

    --draw level 1 text
    love.graphics.print(level1Text, 20, 175)

    --draw level 1 egg
    love.graphics.push()
    love.graphics.translate(level1Egg.x + level1Egg.width/2, level1Egg.y + level1Egg.height/2)
    love.graphics.rotate(level1Egg.angle)
    love.graphics.translate(-level1Egg.width/2, -level1Egg.height/2)

    love.graphics.rectangle("fill", 0, 0, level1Egg.width, level1Egg.height, 20, 20)

    love.graphics.pop()

    --draw level 1 wall, purple
    love.graphics.setColor(0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", level1Wall.x, level1Wall.y, level1Wall.width, level1Wall.height)  -- x, y, width, height
    love.graphics.setColor(1, 1, 1)

    animation:draw(spriteSheet, 100, 100)

    -- -- DEBUG: draw collision boxes
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("line", player.x, player.y, player.width, player.height)

    -- for _, block in ipairs(level1Environment) do
    --     love.graphics.rectangle("line", block.x, block.y, block.width, block.height)
    -- end
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

--movement and collisions
function resolveCollisions(player, blocks, dx, dy)
    -- Move X
    player.x = player.x + dx
    for _, block in ipairs(blocks) do
        if checkCollision(player, block) then
            if block.isPushable and player.onGround and block.onGround then
                -- Try to push the block
                block.x = block.x + dx

                -- Check if the block now collides with anything else (e.g. a wall)
                local blocked = false
                for _, other in ipairs(blocks) do
                    if other ~= block and checkCollision(block, other) and not other.isPushable then
                        blocked = true
                        break
                    end
                end

                if blocked then
                    -- Undo the push and stop player
                    block.x = block.x - dx
                    if dx > 0 then
                        player.x = block.x - player.width
                    elseif dx < 0 then
                        player.x = block.x + block.width
                    end
                end
            else
                -- Not pushable — resolve normally
                if dx > 0 then
                    player.x = block.x - player.width
                elseif dx < 0 then
                    player.x = block.x + block.width
                end
            end
        end
    end

    -- Move Y
    player.y = player.y + dy
    local landed = false

    for _, block in ipairs(blocks) do
        if checkCollision(player, block) then
            if dy > 0 then
                -- Coming down onto something
                player.y = block.y - player.height
                player.vy = 0
                landed = true
            elseif dy < 0 then
                -- Jumping up into a block
                player.y = block.y + block.height
                player.vy = 0

                if block == level1Egg then
                    level1Egg.vy = -150  -- bounce up speed
                    level1Egg.vx = 50
                    level1Egg.isFlying = true
                end
            end
        end
    end

    player.onGround = landed
end