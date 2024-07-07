local Utility = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function Utility:lookBeforeChildOfObject(indexFromLoop, object, specifiedObjectName)
	local Object = object:GetChildren()[indexFromLoop-1]
	return Object and Object.Name == specifiedObjectName, Object
end

function Utility:tween(object, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle[easingStyle or "Circular"], Enum.EasingDirection[easingDirection or "Out"])
	return TweenService:Create(object, tweenInfo, properties)
end

function Utility:getUserInputService()
	return UserInputService
end

function Utility:getMouseLocation()
	return UserInputService:GetMouseLocation()
end

local dragging = function(connectionsTable, ui, uiForResizing, callback)
	local dragging, dragInput, dragStartPosition, currentUIPosition, currentUISizeForUIResizing
	local eventNameToEnableDrag = "InputBegan"
	
	local update = function(input)
		if typeof(dragStartPosition) == "Vector2" then
			input = Vector2.new(input.Position.X, input.Position.Y)
		else
			input = input.Position
		end
				
		local delta = input - dragStartPosition
		callback(delta, ui, currentUIPosition, currentUISizeForUIResizing)
	end
	
	local setInitialPositionsAndSize = function(initialDragStartPosition)
		dragging = true
		dragStartPosition = initialDragStartPosition
		currentUIPosition = ui.Position

		if uiForResizing then
			currentUISizeForUIResizing = uiForResizing.Size
		end
	end
			
	local enableDrag = function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setInitialPositionsAndSize(input.Position)
		end
	end
	
	if ui.ClassName == "TextButton" then
		eventNameToEnableDrag = "MouseButton1Down"
		
		enableDrag = function()
			dragging = true
			setInitialPositionsAndSize(Utility:getMouseLocation())
		end
	end
	
	local disableDrag = function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end
	
	local handleUpdate = function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input)
		end
	end
	
	local Events = {
		{ui, eventNameToEnableDrag, enableDrag},
		{UserInputService, "InputEnded", disableDrag},
		{UserInputService, "InputChanged", handleUpdate},
	}
	
	Utility:connectEvents(connectionsTable, Events)
end

function Utility:draggable(connectionsTable, uiToEnableDrag)
	dragging(connectionsTable, uiToEnableDrag, nil, function(delta, ui, currentUIPosition)
		self:tween(ui, {Position = UDim2.new(currentUIPosition.X.Scale, currentUIPosition.X.Offset + delta.X, currentUIPosition.Y.Scale, currentUIPosition.Y.Offset + delta.Y)}, 0.15):Play()
	end)
end

function Utility:resizable(connectionsTable, uiToEnableDrag, uiToResize)
	dragging(connectionsTable, uiToEnableDrag, uiToResize, function(delta, ui, currentUIPosition, currentUISizeForUIResizing)
		self:tween(uiToResize, {Size = UDim2.fromOffset(currentUISizeForUIResizing.X.Offset + delta.X, currentUISizeForUIResizing.Y.Offset + delta.Y)}, 0.15):Play()
	end)
end

function Utility:calculateScaleAndOffset(uiSize, absoluteSize)
	local value = uiSize / absoluteSize
	
	if value > 1 then
		return 1, 0
	else
		return 0, uiSize
	end
end

function Utility:createBoolean(booleanValue)
	local state = booleanValue

	return {
		get = function(self)
			return state
		end,

		set = function(self, value)
			state = value
		end,
	}
end

function Utility:connectEvents(connectionsTable, events)
	for _, info in ipairs(events) do
		local object, eventName = info[1], info[2] 

		if eventName == "GetPropertyChangedSignal" then
			local property, callback = info[3], info[4]
			table.insert(connectionsTable, object:GetPropertyChangedSignal(property):Connect(callback))
		else
			local callback = info[3]
			table.insert(connectionsTable, object[eventName]:Connect(callback))
		end
	end
end

return Utility
