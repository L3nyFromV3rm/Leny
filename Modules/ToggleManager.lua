local ToggleManager = {}

local Utility = require(script.Parent.Utility)

local tweenToggle = function(toggleBackgroundFrame, circle, backgroundFrameColor, circleColor, anchorPoint, position, duration)
	Utility:tween(toggleBackgroundFrame, {BackgroundColor3 = backgroundFrameColor}, duration):Play()
	Utility:tween(circle, {BackgroundColor3 = circleColor, AnchorPoint = anchorPoint, Position = position}, duration):Play()
end

function ToggleManager:handleToggle(options)	
	return function()
		options.state = not options.state

		if options.state then
			tweenToggle(options.toggleBackgroundFrame, options.circle, options.theme.main, options.theme.background, Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), 0.2)
		else
			tweenToggle(options.toggleBackgroundFrame, options.circle, options.theme.background1, options.theme.background, Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), 0.2)
		end
		
		options.callback(options.state)
	end
end

function ToggleManager:getState(options)
	return function()
		return options.state
	end
end

function ToggleManager:updateState(newState, options)
	options.state = not newState
	self:handleToggle(options)()
end

return ToggleManager
