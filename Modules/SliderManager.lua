local SliderManager = {}

local Utility = require(script.Parent.Utility)

local updateFillAndCurrentValueLabel = function(options, percent, value)
	Utility:tween(options.fill, {Size = UDim2.new(percent, 0, 0, 4)}):Play()
	options.currentValueLabel.Text = tostring(value)
	options.callback(value)
	options.value = value
end

function SliderManager:handleSlider(dragBoolean, options)	
	local handler = function(options)	
		local round = function(number)
			if options.decimalPlaces == 0 then
				return math.round(number)
			else
				return math.round(number * 10^options.decimalPlaces) * 10^-options.decimalPlaces
			end
		end

		local getMouseLocation = Utility:getMouseLocation() 

		local Line = options.line	
		local Fill = options.fill

		local min, max = options.min, options.max
		local percent = math.clamp((getMouseLocation.X - Line.AbsolutePosition.X) / Line.AbsoluteSize.X, 0, 1)
		local value = round((percent * (max - min)) + min)

		self:showDragAndCurrentValueLabel(options, 0)()
		updateFillAndCurrentValueLabel(options, percent, value)
	end
	
	return function(input)
		if dragBoolean:get() and input.UserInputType == Enum.UserInputType.MouseMovement then
			handler(options)
		end
	end
end

function SliderManager:updateValue(newValue, options)
	local min, max = options.min, options.max	
	local percent = (math.clamp(newValue, min, max) - min) / (max - min)

	updateFillAndCurrentValueLabel(options, percent, newValue)
end

function SliderManager:showDragAndCurrentValueLabel(options, backgroundTransparency)
	return function()
		local currentValueLabelTextBoundsX = math.clamp(options.currentValueLabel.TextBounds.X + 30, 10, 200)

		Utility:tween(options.drag, {BackgroundTransparency = backgroundTransparency}):Play()
		Utility:tween(options.currentValueLabel, {Size = UDim2.fromOffset(currentValueLabelTextBoundsX, 20), BackgroundTransparency = backgroundTransparency}):Play()
	end
end

function SliderManager:enableDrag(dragBoolean)		
	return function()
		dragBoolean:set(true)
	end
end

function SliderManager:disableDrag(dragBoolean, options)
	return function(input)
		if dragBoolean:get() and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragBoolean:set(false)
			self:showDragAndCurrentValueLabel(options, 1)()
		end
	end
end

function SliderManager:getValue(options)
	return function()
		return options.value
	end
end

return SliderManager
