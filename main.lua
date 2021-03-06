-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- PHYSICS
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- SEED
math.randomseed( os.time() )


-- SHEET CONFIG
local sheetOptions = 
{
	frames = {
		{	-- 1) asteroid A
			x = 0,
			y = 0,
			width = 102,
			height = 85
		},
		{	-- 2) asteroid B
			x = 0,
			y = 85,
			width = 90,
			height = 83
		},
		{	-- 3) asteroid C
			x = 0,
			y = 168,
			width = 100,
			height = 97
		},
		{	-- 4) ship
			x = 0,
			y = 265,
			width = 98,
			height = 79
		},
		{	-- 5) laser
			x = 98,
			y = 265,
			width = 14,
			height = 40
		},
	},
}

local objectSheet = graphics.newImageSheet( "gameObjects.png", sheetOptions )


-- VARIABLES
local lives = 3
local score = 0
local died = false

local asteroidTable = {}

local ship 
local gameLoopTimer
local livesText
local scoreText


-- DISPLAY GROUPS
local backGroup = display.newGroup()	-- background image
local elementGroup = display.newGroup()	-- asteroids, ship and missiles
local hudGroup = display.newGroup()		-- stats


-- LOAD BACKGROUND
local background = display.newImageRect( backGroup, "background.png", 800, 1400 )
background.x = display.contentCenterX
background.y = display.contentCenterY

ship = display.newImageRect( elementGroup, objectSheet, 4, 98, 79)
ship.x = display.contentCenterX
ship.y = display.contentHeight - 100
physics.addBody( ship, { radius=30, isSensor=true } )	--collision detection
ship.myName = "Vogayer"


-- LOAD HUD
livesText = display.newText( hudGroup, "Lives: " .. lives, 100, 40, native.systemfont, 20 )
scoreText = display.newText( hudGroup, "Score: " .. score, 100, 80, native.systemfont, 20 )


-- HIDE STATUSBAR
display.setStatusBar( display.HiddenStatusBar )


-- HUD UPDATE
local function updateHUD()
	livesText.text = "Lives: " .. lives
	scoreText = "Score: " .. score
end


-- ASTEROID GENERATION
local function createAsteroid() 
    local newAsteroid = display.newImageRect( elementGroup, objectSheet, 1, 102, 85 )
    table.insert( asteroidTable, newAsteroid )
    physics.addBody( newAsteroid, "dynamic", { radius=40, bounce=0.8 } )
    newAsteroid.myName = "asteroid"

	
	
	-- Movement
	local origin = math.random( 3 )
	
	if ( origin == 1 ) then	-- left
		newAsteroid.x = -60
		newAsteroid.y = math.random( 300 )	--! See if this can be automatically calulated from device settings
		newAsteroid:setLinearVelocity( math.random( 40,120 ), math.random( 20,60 ) )	-- random int between the two values
	elseif ( origin == 2 ) then	-- top
		newAsteroid.x = math.random( display.contentWidth )
		newAsteroid.y = -60
		newAsteroid:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) )	
	elseif ( origin == 3 ) then	-- right
		newAsteroid.x = display.contentWidth + 60
		newAsteroid.y = math.random( 300 )
		newAsteroid:setLinearVelocity( math.random( -120,-40 ), math.random( 20,60 ) )
	end
	
	newAsteroid:applyTorque( math.random( -6,6 ) )
	
end


-- LASERS
local function fireLaser()
	local newLaser = display.newImageRect( elementGroup, objectSheet, 5, 14, 40 )
	physics.addBody( newLaser, "dynamic", { isSensor=true } )
	newLaser.isBullet = true
	newLaser.myName = "pew"
	
	newLaser.x = ship.x
	newLaser.y = ship.y
	newLaser:toBack()
	
	transition.to( newLaser, { y=-40, time=500,
		onComplete = function() display.remove( newLaser ) end	-- anon function
		} )
end


ship:addEventListener( "tap", fireLaser )


-- MOVEMENT
local function dragShip( event )

	local ship = event.target
	local phase = event.phase
	
	if ( phase == "began" ) then
		--fireLaser() -- Checking functionalitty
		--createAsteroid()
		-- Touch event focuses ship object
		display.currentStage:setFocus( ship )
		-- store offset position
		ship.touchOffsetX = event.x - ship.x
	elseif ( "moved" == phase ) then
		-- move ship
		ship.x = event.x - ship.touchOffsetX
	elseif ( "ended" == phase or "cancelled" == phase ) then
		-- lose ship focuses
		display.currentStage:setFocus( nil )
	end
	
	-- Prevents touch propagation to underlying objects (??)
	return true
	
	
end

-- Upon 'touching' a ship, trigger dragShip function
ship:addEventListener( "touch", dragShip )


-- Define gameloop
local function gameLoop()
	-- create asteroids
	createAsteroid()
	-- for loop in count(asteroidTable), stop at 1 and count -1
	for i = #asteroidTable, 1, -1 do
		local thisAsteroid = asteroidTable[i]
		
		if ( thisAsteroid.x < -100
			or thisAsteroid.x > display.contentWidth + 100
			or thisAsteroid.y < -100
			or thisAsteroid.y > display.contentHeight + 100)
		then
			display.remove( thisAsteroid )
			table.remove( asteroidTable, i )
		end
	end
end


-- Collision
local function onCollision( event )
	if ( event.phase == "began" ) then

		local obj1 = event.object1
		local obj2 = event.object2
		
		-- Pewpew the asteroid
		if (
			( obj1.myName == "pew" and obj2.myName == "asteroid" ) or ( obj1.myName == "asteroid" and obj1.myName == "pew" )
		)
		then
			--print( "hupsa" ) --check
			display.remove( obj1 )
			display.remove( obj2 )
		
			for i = #asteroidTable, 1, -1 do
				if ( asteroidTable[i] == obj1 or asteroidTable[i] == obj2 ) then
					table.remove( asteroidTable, i )
					break
				end		
			end
			
			score = score + 100
			scoreText.text = "Score: " .. score
		end
		
		-- Boomboom the ship
		if (
			( obj1.myName == "Vogayer" and obj2.myName == "asteroid" ) or ( obj1.myName == "asteroid" and obj1.myName == "Voyager" )
		)
		then
			if ( died == false ) then
				died = true
				
				lives = lives - 1
				livesText.text = "Lives: " .. lives
				
				if ( lives == 0 ) then --GAME OVER
					display.remove( ship )
				else
					ship.alpha = 0
					timer.performWithDelay( 1000, restoreShip )
				end
			
			end
		end
		
	end
end

	

--object.collision = shootAsteroid
--object:addEventListener( "collision" )

Runtime:addEventListener( "collision", onCollision )



-- Initiate gameloop. 0 / -1 means indefinite looping
gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )


local function restoreShip()
	--Remove ship from physics simulation
	ship.isBodyActive = false
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100
	
	-- Fade in
	transition.to(
		ship, {
			alpha=1,
			time=3000,
			onComplete = function ()
				ship.isBodyActive = true
				died = false
			end
		}
	)
end
	
