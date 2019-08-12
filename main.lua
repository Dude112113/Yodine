require "utils"  -- provides a set of global functions

-- Constant's and defining locals
BackgroundCellSize = 20
local background
DefaultFont = GetFont()
Consola = love.graphics.newFont("Consola.ttf")

local camera = require "camera"
local yolol = require "yolol"
local helpers = require "yolol.tests.helpers"

local devices = require "devices.init"
local Map = require "Map"


local loadedMap = Map.new()
-- Testing stuff
loadedMap:createObject(0, -100, devices.button)
loadedMap:createObject(100, -100, devices.led)
loadedMap:createObject(-100, 0, devices.chip)

-- Variables
local connectionTarget
local centerDrawObject  -- used if a map object has a :drawGUI(), there are other functions for input ect


function SetCenterDrawObject(obj)
	if obj == nil then
		centerDrawObject = nil
	else
		if obj.drawGUI == nil then
			error("Attempt to set center draw object but does not have :drawGUI()")
		end
		if obj.getSizeGUI == nil then
			error("Attempt to set center draw object but does not have :getSizeGUI()")
		end
		centerDrawObject = obj
	end
end


local function genBackgroundImage()
	local imgData = love.image.newImageData(love.graphics.getWidth()+BackgroundCellSize, love.graphics.getHeight()+BackgroundCellSize)
	local mapCells = function(x, y, r, g, b, a)
		if (x+1)%BackgroundCellSize <= 1 or (y+1)%BackgroundCellSize <= 1 then
			return 0, 0, 0, 1
		else
			return 0.8, 0.8, 0.8, 1
		end
	end
	imgData:mapPixel(mapCells)
	background = love.graphics.newImage(imgData)
end

function love.load()
	love.window.maximize()

	camera.x = -love.graphics.getWidth()/2
	camera.y = -love.graphics.getHeight()/2

	love.filesystem.write("/Help.txt", love.filesystem.read("/data/_Help.txt"))
end

function love.draw()
	local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()

	love.graphics.setColor(1, 1, 1, 1)

	if background == nil then
		genBackgroundImage()
	end
	love.graphics.draw(background, -camera.x%BackgroundCellSize-BackgroundCellSize, -camera.y%BackgroundCellSize-BackgroundCellSize)

	camera:set()
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.print("0,0", -GetFont():getWidth("0,0")/2, -GetFont():getHeight()+2)
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.circle("line", 0, 0, 50)

		love.graphics.setColor(0.3, 0.3, 0.3, 1)
		love.graphics.setLineWidth(3)
		for _, v in pairs(loadedMap.objects) do
			for _, other in pairs(v.connections) do
				local vOffX, vOffY = 0, 0
				local otherOffX, otherOffY = 0, 0
				if v.getWireDrawOffset then vOffX, vOffY = v:getWireDrawOffset() end
				if other.getWireDrawOffset then otherOffX, otherOffY = other:getWireDrawOffset() end
				love.graphics.line(v.x+vOffX, v.y+vOffY, other.x+otherOffX, other.y+otherOffY)
			end
		end

		for _, v in pairs(loadedMap.objects) do
			love.graphics.push()
				love.graphics.translate(v.x, v.y)
				if v.draw == nil then
					love.graphics.setColor(0, 0, 0, 1)
					love.graphics.print(v.name .. " Has no :draw()")
				else
					love.graphics.setColor(1, 1, 1, 1)
					v:draw()
				end
			love.graphics.pop()
		end
	camera:unset()

	if centerDrawObject ~= nil and centerDrawObject.drawGUI ~= nil and centerDrawObject.getSizeGUI ~= nil then
		love.graphics.push()
			local cdo_w, cdo_h = centerDrawObject:getSizeGUI()
			love.graphics.translate((ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2))
			centerDrawObject:drawGUI()
		love.graphics.pop()
	end

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print(love.timer.getFPS(), 1, 1)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(love.timer.getFPS())
end

function love.update(dt)
	camera:dragPosition()
end

function love.mousereleased(x, y, button)
	local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()
	local worldX, worldY = camera:cameraPosition(x, y)
	local has_cdo, cdo_x, cdo_y, cdo_w, cdo_h, cdo_mx, cdo_my
	if centerDrawObject ~= nil and centerDrawObject.getSizeGUI ~= nil then
		has_cdo = true
		cdo_w, cdo_h = centerDrawObject:getSizeGUI()
		cdo_x, cdo_y = (ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2)
		cdo_mx, cdo_my = x-cdo_x, y-cdo_y
	end
	if button == 3 then
		local obj = loadedMap:getObjectAt(worldX, worldY)
		if connectionTarget ~= nil and obj ~= nil then
			if loadedMap:isConnected(obj, connectionTarget) then
				loadedMap:disconnect(obj, connectionTarget)
			else
				loadedMap:connect(obj, connectionTarget)
			end
			connectionTarget = nil
		else
			connectionTarget = obj
		end
	elseif has_cdo and IsInside(cdo_x, cdo_y, cdo_x+cdo_w, cdo_y+cdo_h, x, y) then
		centerDrawObject:clickedGUI(cdo_mx, cdo_my, button)
	elseif button == 1 then
		local obj = loadedMap:getObjectAt(worldX, worldY)
		if obj then
			if obj.clicked then
				obj:clicked(obj.x-worldX, obj.y-worldY, button)
				return
			end
		end
	end
end

function love.keypressed(key)
	if centerDrawObject ~= nil and key == "escape" then
		SetCenterDrawObject()
	elseif centerDrawObject ~= nil and centerDrawObject.keypressedGUI then
		centerDrawObject:keypressedGUI(key)
	end
end

function love.textinput(text)
	if centerDrawObject.textinputGUI then
		centerDrawObject:textinputGUI(text)
	end
end

function love.resize()
	genBackgroundImage()
end