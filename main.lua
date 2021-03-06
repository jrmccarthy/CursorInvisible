TARGET_SPAWN_DELAY = 5
TARGETS_ON_SCREEN = 0
MAX_TARGETS = 10
TARGET_RADIUS = 96
TIME_BETWEEN_SPAWN = 100

spawnCounter = TARGET_SPAWN_DELAY
alive = true
score = 0

windowHeight = 960
windowWidth = 640
MOAISim.openWindow ( "test", windowHeight, windowWidth )

viewport = MOAIViewport.new ()
viewport:setSize ( windowHeight, windowWidth )
viewport:setScale ( windowHeight, windowWidth )

layer = MOAILayer2D.new ()
layer:setViewport ( viewport )

textLayer = MOAILayer2D.new ()
textLayer:setViewport ( viewport )

layers = {}
table.insert(layers, layer)
table.insert(layers, textLayer)
MOAIRenderMgr.setRenderTable(layers)

bholeGfx = MOAIGfxQuad2D.new ()
bholeGfx:setTexture ( "assets/images/bhole.png" )
bholeGfx:setRect ( -20, -20, 20, 20 )

targetGfx = MOAIGfxQuad2D.new ()
targetGfx:setTexture ( "assets/images/target.png" )
targetGfx:setRect ( -TARGET_RADIUS, -TARGET_RADIUS, TARGET_RADIUS, TARGET_RADIUS )

font =  MOAIFont.new ()
font:loadFromTTF ("assets/arialbd.ttf", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,.?! ", 22, 163 )

gameScoreText = MOAITextBox.new()
gameScoreText:setFont( font )
gameScoreText:setRect( -160, -80, 160, 80 )
gameScoreText:setLoc( ( windowHeight / 2 ) - 75, ( windowWidth / 2 ) - 75 )
gameScoreText:setAlignment( MOAITextBox.CENTER_JUSTIFY )
gameScoreText:setYFlip( true )
gameScoreText:setString( tostring(score) )
textLayer:insertProp( gameScoreText )

gameStateText = MOAITextBox.new()
gameStateText:setFont( font )
gameStateText:setRect( -160, -80, 160, 80 )
gameStateText:setLoc( 0, 0 )
gameStateText:setAlignment( MOAITextBox.CENTER_JUSTIFY )
gameStateText:setYFlip( true )
textLayer:insertProp( gameStateText )

local bholes = {}
local targets = {}

function setState ( prop, state, ... )

	if prop then
		if prop.finish then
			prop:finish ()
			prop.finish = nil
		end
		state ( prop, ... )
	end
end

function targetState ( prop, x, y )

	if alive == true then
		prop:setDeck ( targetGfx )
		prop:setLoc ( x, y )
		prop.state = targetState
		layer:insertProp ( prop )
	end
	table.insert(targets,prop)
	TARGETS_ON_SCREEN = TARGETS_ON_SCREEN + 1
	-- targets[prop] = true

	function prop:finish ()
		--Placeholder
	end

	function prop:main ()
		--Placeholder
	end
end

function targetHitState( prop )
	layer:removeProp(prop)
	score = score + 1
	TARGETS_ON_SCREEN = TARGETS_ON_SCREEN - 1
	gameScoreText:setString( tostring(score) )

end

function handleClickOrTouch( xin, yin )
	local x,y = layer:wndToWorld( xin, yin )
	local partition = layer:getPartition()
	local pickedProp = partition:propForPoint(x, y)
	if pickedProp then
		-- Find the center of the circle
		local tmpx, tmpy = pickedProp:getLoc()
		-- Figure out the component vectors from the center of the circle to the click location
		local vecx, vecy = x-tmpx, y-tmpy
		-- Find the length of the vector from center to click
		local incircle = math.sqrt(math.pow(vecx, 2) + math.pow(vecy, 2)) - 1  -- Image / math isnt perfectly sized
		print( 'In circle: ', incircle)
		-- If the length is more than the radius of the target, this click missed
		if incircle <= TARGET_RADIUS then
			setState( pickedProp, targetHitState )
		else
			pickedProp = nil
		end
	end

	--If the mouse click missed all props, game over
	if pickedProp == nil then
		alive = false
	end
end

function handleMouse( down )
	if down then
		local x,y = MOAIInputMgr.device.pointer:getLoc()
		handleClickOrTouch( x, y )
	end
end

function handleTouch( eventType, idx, x, y, tapCount )
	if (tapCount == 1) then
		handleClickOrTouch( x, y )
	end
end

if MOAIInputMgr.device.pointer then
	MOAIInputMgr.device.mouseLeft:setCallback(handleMouse)
end
if MOAIInputMgr.device.touch then
	MOAIInputMgr.device.touch:setCallback(handleTouch)
end

function handleKeyboard(key,down)
	if down==true then
		if key == 27 then -- 'escape' key
			os.exit()
		end
	end
end
MOAIInputMgr.device.keyboard:setCallback(handleKeyboard)

function main ()
	--Main game loop
	while alive == true do
		if( TARGETS_ON_SCREEN > MAX_TARGETS ) then
			alive = false
			coroutine.yield()
		end
		--Generate new randomly placed target
		setState (
			MOAIProp2D.new()
			, targetState
			, math.random(
				((windowWidth/2) - TARGET_RADIUS) * -1
				,((windowWidth/2) - TARGET_RADIUS)
			)
			, math.random(
				((windowHeight/2) -TARGET_RADIUS) * -1
				, (windowHeight / 2) - TARGET_RADIUS
			)
		)

		--Throttle thread so you dont create a million targets
		for i = 1, TIME_BETWEEN_SPAWN do
			spawnCounter = spawnCounter + 1
			coroutine.yield()
		end
	end

	while alive == false do
		gameStateText:setString ( "Game Over" )
		gameStateText:spool ()
		alive = nil
	end
end

spawnThread = MOAIThread.new ()
spawnThread:run ( main )
