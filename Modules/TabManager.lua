local TabManager = {}

local Utility = require(script.Parent.Utility)

local validateOptions = function(options, requiredOptions)
	local missingRequiredOptions = {}
	local invalidOptions = {}

	for option, expectedType in pairs(requiredOptions) do
		if not options[option] then
			table.insert(missingRequiredOptions, option)
		elseif typeof(options[option]) ~= expectedType then
			table.insert(invalidOptions, option)
		end
	end

	if #missingRequiredOptions > 0 then
		local message = "Missing required options: " .. table.concat(missingRequiredOptions, ", ")
		warn(message)
	end

	if #invalidOptions > 0 then
		local message = "Invalid types: " .. table.concat(invalidOptions, ", ")
		warn(message)
	end
end

local tweenTab = function(button, icon, newButtonColor, newIconColor, duration)
	if button then
		Utility:tween(button, {TextColor3 = newButtonColor}, duration):Play()
	end

	if icon then
		Utility:tween(icon, {ImageColor3 = newIconColor}, duration):Play()
	end
end

local makeCurrentPageVisible = function(options)
	for _, page in ipairs(options.objectWithPages:GetChildren()) do
		if string.match(page.Name, "Page") and page.Visible then
			page.Visible = false
		end
	end

	options.currentPage.Visible = true
end

local currentTabOn = function(options)
	tweenTab(options.tabButton, options.icon, options.theme.tabOn, options.theme.tabOn, options.currentTabOnDuration)
	options.updateTabBackgroundFrame()
end

function TabManager:getCurrentTabPosition(objectWithTabs, calculationCallback)
	local tabIndex = 0
	local currentTabPosition = 0

	for index, tab in ipairs(objectWithTabs:GetChildren()) do
		if tab:IsA("UIListLayout") then
			continue
		end

		if not string.match(tab.Name, "Tab") then
			continue
		end 

		tabIndex += 1
		currentTabPosition = calculationCallback(index, tab, tabIndex, currentTabPosition)
	end

	return currentTabPosition
end

function TabManager:validateTabManagerOptions(options)
	local requiredOptions = {
		objectWithTabs = "Instance",
		tabType = "string",
		objectWithPages = "Instance",
		currentPage = "Instance",
		tabButton = "Instance",
		--icon = nil,
		tabBackgroundFrame = "Instance",
		currentTabPosition = "number",
		allTabsOffDuration = "number",
		currentTabOnDuration = "number",
		updateTabBackgroundFrame = "function",
		animation = "function",
		theme = "table",
	}

	validateOptions(options, requiredOptions)

	return {
		objectWithTabs = options.objectWithTabs,
		tabType = options.tabType,
		objectWithPages = options.objectWithPages,
		currentPage = options.currentPage,
		tabButton = options.tabButton,
		icon = options.icon,
		tabBackgroundFrame = options.tabBackgroundFrame,
		currentTabPosition = options.currentTabPosition,
		allTabsOffDuration = options.allTabsOffDuration,
		currentTabOnDuration = options.currentTabOnDuration,
		updateTabBackgroundFrame = options.updateTabBackgroundFrame,
		animation = options.animation,
		theme = options.theme,
	}
end

function TabManager:changeToTab(options)
	local allTabsOff = function()
		for _, tab in ipairs(options.objectWithTabs:GetChildren()) do
			if not (tab:IsA("TextButton") or tab:IsA("ImageButton")) then
				continue
			end

			if options.tabType == "Tab" then
				tweenTab(tab.TextButton, tab.ImageButton, options.theme.tabOff, options.theme.tabOff, options.allTabsOffDuration)
			elseif options.tabType == "SubTab" then
				tweenTab(tab, nil, options.theme.tabOff, options.theme.tabOff, options.allTabsOffDuration)
			end
		end
	end
	
	return function()
		if options.currentPage.Visible then
			return
		end

		allTabsOff()
		makeCurrentPageVisible(options)
		options.animation()
		currentTabOn(options)
	end
end

function TabManager:showFirstTab(booleanState, options, updateTabBackgroundFrame)
	if not booleanState:get() then
		booleanState:set(true)
		makeCurrentPageVisible(options)
		currentTabOn(options)
	end
end

return TabManager
