local DropdownManager = {}

local Utility = require(script.Parent.Utility)

local tweenDropButton = function(button, newBackgroundColor, newImageTransparency)
	Utility:tween(button.Frame, {BackgroundColor3 = newBackgroundColor}, 0.2, "Circular", "InOut"):Play()
	Utility:tween(button.Frame.ImageLabel, {ImageTransparency = newImageTransparency}, 0.3):Play()
end

local getAllDropButtons = function(options, callback)
	for _, button in ipairs(options.objectWithDropButtons:GetChildren()) do
		if button.Name == "DropButton" then
			callback(button)
		end
	end
end

function DropdownManager:handleDropdown(options)
	local updateValueAndCallbackAndLabel = function(newValue)
		options.value = newValue
		options.callback(options.value)
		
		if (typeof(newValue) == "table" and options.multiple) then
			options.showListButton.Text = table.concat(newValue, ", ")
		else
			options.showListButton.Text = tostring(newValue)
		end
	end
	
	local createDropButtons = function(chooseCallback, setDefaultCallback)	
		for _, value in ipairs(options.list) do
			local currentButton = options.createDropButton(value)	
			setDefaultCallback(currentButton, value)
			currentButton.MouseButton1Down:Connect(chooseCallback(currentButton, value))
		end
	end
			
	local choose = function()
		local single = function(currentButton, value)
			return function()
				getAllDropButtons(options, function(button)
					tweenDropButton(button.TextButton, options.theme.background1, 1)
				end)

				tweenDropButton(currentButton, options.theme.main, 0)
				updateValueAndCallbackAndLabel(value)
			end
		end

		local multiple = function(currentButton, value)
			return function()
				local valueInMultipleTable = table.find(options.multipleTable, value)
				
				if not valueInMultipleTable then
					tweenDropButton(currentButton, options.theme.main, 0)
					table.insert(options.multipleTable, value)
				else
					tweenDropButton(currentButton, options.theme.background1, 1)
					table.remove(options.multipleTable, table.find(options.multipleTable, value))
				end
				
				updateValueAndCallbackAndLabel(options.multipleTable)
			end
		end
		
		if not options.multiple then
			return single
		else
			return multiple
		end
	end
	
	local setDefault = function(currentButton, value)
		local valueInDefaultsTable = table.find(options.default, value)
		
		if valueInDefaultsTable then
			tweenDropButton(currentButton, options.theme.main, 0)

			if not options.multiple then
				updateValueAndCallbackAndLabel(value)
			else
				table.insert(options.multipleTable, value)
				updateValueAndCallbackAndLabel(options.multipleTable)
			end
		end
	end
	
	createDropButtons(choose(), setDefault)
end

function DropdownManager:updateList(newList, newDefault, options)
	getAllDropButtons(options, function(button)
		button:Destroy()
	end)
	
	options.list = newList
	options.default = newDefault or options.default
	options.multipleTable = {}
	
	self:handleDropdown(options)
end

function DropdownManager:getValue(options)
	return options.value
end

return DropdownManager
