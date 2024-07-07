local Library = {
	Flags = {
		Toggles = {},
		Sliders = {},
	},
	
	Connections = {},
}

local Flags = Library.Flags

local Leny = game:GetObjects("rbxassetid://18419256504")[1]
Leny.Parent = game.StarterGui

local Objects = Leny.Objects
local UI = Objects.UI
local Modules = Objects.Modules

local Utility = require(Modules.Utility)
local ThemeManager = require(Modules.ThemeManager)
local TabManager = require(Modules.TabManager)
local ToggleManager = require(Modules.ToggleManager)
local SliderManager = require(Modules.SliderManager)

local UserInputService = Utility:getUserInputService()
local Theme = ThemeManager.Theme

local Glow = Leny.Glow
local Main = Glow.Main

local LeftFolder = Main.Left
local RightFolder = Main.Right

local firstTabIsVisible = Utility:createBoolean(false)
local firstSubTabIsVisible = Utility:createBoolean(false)
local leftAndRightAbsoluteContentSizeDebounce = Utility:createBoolean(false)

--// Library Functions
function Library:destroy()
	for i,v in ipairs(self.Connections) do
		v:Disconnect()
	end
	
	Leny:Destroy()
end

function Library:createAddons(subElements, imageButton, additionalAddons)
	local DefaultAddons = {
		createToggle = function(options)
			self:createToggle(options, subElements)
		end,
		
		createSlider = function(options)
			self:createSlider(options, subElements)
		end,
	}

	for key, value in pairs(additionalAddons) do
		DefaultAddons[key] = value
	end

	return setmetatable({},  {
		__index = function(table, key)
			local originalFunction = DefaultAddons[key]

			if type(originalFunction) == "function" then
				return function(...)
					if string.find(key, "create") then
						imageButton.Visible = true
					end

					return originalFunction(...)
				end
			else
				return originalFunction
			end
		end,

		__newindex = function(table, key, value)
			DefaultAddons[key] = value
		end
	})
end

function Library:showSubElements(showBoolean, subElements, subElementsUIListLayout)
	return function()
		showBoolean:set(not showBoolean:get())

		if showBoolean:get() then
			Utility:tween(subElements, {Size = UDim2.new(1, 0, 0, subElementsUIListLayout.AbsoluteContentSize.Y)}):Play()
		else
			Utility:tween(subElements, {Size = UDim2.new(1, 0, 0, 0)}):Play()
		end
	end
end

function Library:createLabel(options)
	local Tabs = LeftFolder.Frame.Frame.Tabs

	local Label = UI.Label:Clone()
	Label.Visible = true
	Label.Text = options.text or "Label"
	Label.Parent = Tabs
end

function Library:createTab(options)
	options = {
		text = options.text or "Tab",
		icon = options.icon or "11673940370",
		callback = options.callback or function() end,
	}

	local Tabs = LeftFolder.Frame.Frame.Tabs
	local UIListLayout = Tabs.UIListLayout

	local Page = UI.Pages.Page:Clone()
	Page.Parent = RightFolder

	local UIPadding = Page.UIPadding

	local CurrentTab = Page.TextLabel
	CurrentTab.Text = options.text or "Tab"

	local Moveable = Tabs.Parent.Moveable

	local TabBackgroundFrame = Moveable.Frame
	TabBackgroundFrame.BackgroundColor3 = Theme.main

	local Tab = UI.Tabs.Tab:Clone()
	Tab.Visible = true
	Tab.Parent = Tabs

	local Icon = Tab.ImageButton
	Icon.Image = "http://www.roblox.com/asset/?id=" .. options.icon

	local TabButton = Tab.TextButton
	TabButton.Text = options.text

	local TAB_SIZE = Tab.Size.Y.Offset
	local PADDING_Y = 20 -- get UIListLayout Padding value instead, but this is correct still.
	
	--// Functions
	local currentTabPosition = TabManager:getCurrentTabPosition(Tabs, function(index, tab, tabIndex, currentTabPosition)
		if tabIndex ~= 1 then
			currentTabPosition += TAB_SIZE + PADDING_Y
		end

		if Utility:lookBeforeChildOfObject(index, Tabs, "Label") then
			currentTabPosition += 14 + PADDING_Y
		end

		return currentTabPosition
	end)

	local updateTabBackgroundFrame = function()
		Utility:tween(TabBackgroundFrame, {Position = UDim2.fromOffset(0, currentTabPosition)}, 0.2):Play()
	end

	local tweenFadeAndPageObjects = function(fadeObject, backgroundTransparency, paddingY)
		Utility:tween(fadeObject, {BackgroundTransparency = backgroundTransparency}, 0.2):Play()
		Utility:tween(UIPadding, {PaddingTop = UDim.new(0, paddingY)}, 0.2):Play()
	end

	local createFade = function()
		local Fade = UI.Fade:Clone()
		Fade.Visible = true
		Fade.Parent = RightFolder
		Fade.BackgroundTransparency = 1

		tweenFadeAndPageObjects(Fade, 0, 14)
		return Fade
	end

	local destroyFade = function(fadeObject)
		return function()
			tweenFadeAndPageObjects(fadeObject, 1, 24)
			task.wait(0.2)
			fadeObject:Destroy()
		end
	end

	local fade = function()
		local Fade = createFade()
		task.delay(0.2, destroyFade(Fade))
	end

	local autoSizeTabsCanvasSize = function()
		Tabs.CanvasSize = UDim2.fromOffset(0, UIListLayout.AbsoluteContentSize.Y)
	end

	local makeMoveableCanvasPropertiesSameAsTabs = function()
		Moveable.CanvasSize = Tabs.CanvasSize
		Moveable.CanvasPosition = Tabs.CanvasPosition
	end
	--

	--// Function calls and Connections
	local TabManagerOptions = TabManager:validateTabManagerOptions({
		objectWithTabs = Tabs,
		tabType = "Tab",
		objectWithPages = RightFolder,
		currentPage = Page,
		tabButton = TabButton,
		icon = Icon,
		tabBackgroundFrame = TabBackgroundFrame,
		currentTabPosition = currentTabPosition,
		currentTabOnDuration = 0.3,
		allTabsOffDuration = 0.1,
		updateTabBackgroundFrame = updateTabBackgroundFrame,
		animation = fade,
		theme = Theme,
	})
	
	local Events = {
		{TabButton, "MouseButton1Down", TabManager:changeToTab(TabManagerOptions)},
		{UIListLayout, "GetPropertyChangedSignal", "AbsoluteContentSize", autoSizeTabsCanvasSize},
		{Tabs, "GetPropertyChangedSignal", "CanvasPosition", makeMoveableCanvasPropertiesSameAsTabs}
	}
	
	Utility:connectEvents(Library.Connections, Events)
	TabManager:showFirstTab(firstTabIsVisible, TabManagerOptions)
	--

	return setmetatable({Page = Page}, {__index = Library})
end

function Library:createSubTab(options)
	options = {
		text = options.text or "Tab",
		callback = options.callback or function() end,
	}
	
	local Frame = self.Page.Frame
	local SubTabs = Frame.ScrollingFrame
	local SubUIListLayout = SubTabs.UIListLayout

	local SubPages = self.Page.SubPages
	local UIPadding = SubPages.UIPadding

	local SubPage = UI.Pages.SubPage:Clone()
	SubPage.Parent = SubPages

	local SubTabButton = UI.Tabs.SubTab:Clone()
	SubTabButton.Visible = true
	SubTabButton.Text = options.text
	SubTabButton.Parent = SubTabs
	SubTabButton.Size = UDim2.fromOffset(SubTabButton.TextBounds.X + 30, 30)

	local Moveable = SubTabs.Parent.Moveable

	local TabBackgroundFrame = Moveable.Frame
	TabBackgroundFrame.BackgroundColor3 = Theme.main
	TabBackgroundFrame.Size = UDim2.fromOffset(SubTabButton.TextBounds.X + 30, 30)
	
	--// Functions
	local currentTabPosition = TabManager:getCurrentTabPosition(SubTabs, function(index, tab, tabIndex, currentTabPosition)
		if tabIndex == 1 then
			currentTabPosition = 0
		end

		if tabIndex ~= 1 then
			local condition, object = Utility:lookBeforeChildOfObject(index, SubTabs, "SubTab")

			local subTabSize = tab.Size.X.Offset
			local objectSize = object.Size.X.Offset

			currentTabPosition += subTabSize

			if condition then
				currentTabPosition -= (subTabSize - objectSize)
			end
		end

		return currentTabPosition
	end)

	local updateTabBackgroundFrame = function()
		Utility:tween(TabBackgroundFrame, {Position = UDim2.fromOffset(currentTabPosition, 0), Size = UDim2.fromOffset(SubTabButton.Size.X.Offset, 30)}, 0.2):Play()
	end

	local transition = function()
		Utility:tween(UIPadding, {PaddingTop = UDim.new(0, 10)}, 0.2):Play()

		task.delay(0.2, function()
			Utility:tween(UIPadding, {PaddingTop = UDim.new(0, 0)}, 0.2):Play()
		end)
	end

	local autoSizeSubTabsCanvasSizeAndFrameSize = function()
		local scaleX, offsetX = Utility:calculateScaleAndOffset(SubUIListLayout.AbsoluteContentSize.X, Frame.AbsoluteSize.X)
		
		Frame.Size = UDim2.new(scaleX, offsetX, 0, 30)
		SubTabs.CanvasSize = UDim2.fromOffset(SubUIListLayout.AbsoluteContentSize.X, 0)
	end

	local makeMoveableCanvasPropertiesSameAsSubTabs = function()
		Moveable.CanvasSize = SubTabs.CanvasSize
		Moveable.CanvasPosition = SubTabs.CanvasPosition
	end
	--

	--// Function calls and Connections
	local TabManagerOptions = TabManager:validateTabManagerOptions({
		objectWithTabs = SubTabs,
		tabType = "SubTab",
		objectWithPages = SubPages,
		currentPage = SubPage,
		tabButton = SubTabButton,
		icon = nil,
		tabBackgroundFrame = TabBackgroundFrame,
		currentTabPosition = currentTabPosition,
		currentTabOnDuration = 0.3,
		allTabsOffDuration = 0.1,
		updateTabBackgroundFrame = updateTabBackgroundFrame,
		animation = transition,
		theme = Theme,
	})
	
	local Events = {
		{SubTabButton, "MouseButton1Down", TabManager:changeToTab(TabManagerOptions)},
		{SubTabs, "GetPropertyChangedSignal", "CanvasPosition", makeMoveableCanvasPropertiesSameAsSubTabs},
		{SubUIListLayout, "GetPropertyChangedSignal", "AbsoluteContentSize", autoSizeSubTabsCanvasSizeAndFrameSize},
	}
	
	autoSizeSubTabsCanvasSizeAndFrameSize()
	Utility:connectEvents(Library.Connections, Events)
	TabManager:showFirstTab(firstSubTabIsVisible, TabManagerOptions)	
	--

	return setmetatable({SubPages = SubPages, SubPage = SubPage}, {__index = Library})
end

function Library:createSection(options)
	options = {
		position = options.position or "Left",
		text = options.text or "Section",
	}

	local Section = UI.Section:Clone()
	Section.Visible = true
	Section.Parent = self.SubPage[options.position]

	local UIListLayout = Section.UIListLayout
	
	local TextLabel = Section.TextLabel
	TextLabel.Text = options.text

	local SubPageLeft = self.SubPage.Left
	local SubPageRight = self.SubPage.Right

	local PADDING_Y = 14
	
	--// Functions
	local autoSectionSize = function()
		Section.Size = UDim2.new(1, 0, 0, UIListLayout.AbsoluteContentSize.Y + (PADDING_Y * 2))
	end

	local autoSubPagesCanvasSize = function()
		local max = math.max(SubPageLeft.UIListLayout.AbsoluteContentSize.Y, SubPageRight.UIListLayout.AbsoluteContentSize.Y)
		self.SubPages.CanvasSize = UDim2.fromOffset(0, max)
	end
	--

	--// Function calls and Connections
	autoSectionSize()
	UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoSectionSize)

	if not leftAndRightAbsoluteContentSizeDebounce:get() then
		leftAndRightAbsoluteContentSizeDebounce:set(true)
		SubPageLeft.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoSubPagesCanvasSize)
		SubPageRight.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoSubPagesCanvasSize)
	end
	--
	
	return setmetatable({Section = Section}, {__index = Library})
end

function Library:createToggle(options, parent)
	options = {
		text = options.text or "Toggle",
		callback = options.callback or function() end,
		state = options.state or false,
		flagName = options.flagName or "Toggle",
		handlers = {},
	}
	
	options.flagName = options.flagName or options.text
	parent = parent or self.Section
	
	local Toggle = Objects.UI.Elements.Toggle:Clone()
	Toggle.Visible = true
	Toggle.Parent = parent
	
	local ToggleUIListLayout = Toggle.UIListLayout
	local TextButton = Toggle.TextButton
	local SubElements = Toggle.SubElements
	local SubElementsUIListLayout = SubElements.UIListLayout
	
	local TextLabel = TextButton.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local Frame = TextLabel.Frame
	local Circle = Frame.Circle
	local ToggleButton = Circle.TextButton
	
	--// Functions
	local autoToggleSize = function()
		Utility:tween(Toggle, {Size = UDim2.new(1, 0, 0, ToggleUIListLayout.AbsoluteContentSize.Y - 8)}):Play()
	end
	--
	
	--// Function calls and Connections
	local ToggleOptions = {
		theme = Theme,
		toggleBackgroundFrame = Frame,
		circle = Circle,
		state = options.state,
		callback = options.callback,
	}
	
	local Addons = self:createAddons(SubElements, ImageButton, {
		updateState = function(self, newState)
			ToggleManager:updateState(newState, ToggleOptions)
		end,

		getState = ToggleManager:getState(ToggleOptions),
	})
	
	local showingUI = Utility:createBoolean(false)
		
	local Events = {
		{TextButton, "MouseButton1Down", ToggleManager:handleToggle(ToggleOptions)},
		{ToggleButton, "MouseButton1Down", ToggleManager:handleToggle(ToggleOptions)},
		{ImageButton, "MouseButton1Down", self:showSubElements(showingUI, SubElements, SubElementsUIListLayout)},
		{ToggleUIListLayout, "GetPropertyChangedSignal", "AbsoluteContentSize", autoToggleSize}
	}
	
	Utility:connectEvents(Library.Connections, Events)
	Flags.Toggles[options.flagName] = Addons
	ToggleManager:updateState(options.state, ToggleOptions)
	--
	
	return Addons
end

function Library:createSlider(options, parent)
	options = {
		text = options.text or "Slider",
		callback = options.callback or function() end,
		min = options.min or 0,
		max = options.max or 100,
		default = options.default or 0,
		decimalPlaces = options.decimalPlaces or 0,
		flagName = options.flagName or "Slider",
	}
	
	options.default = options.default or options.min
	options.flagName = options.flagName or options.text 
	parent = parent or self.Section
	
	local Slider = Objects.UI.Elements.Slider:Clone()
	Slider.Visible = true
	Slider.Parent = parent
	
	local SliderUIListLayout = Slider.UIListLayout
	local SubElements = Slider.SubElements
	local SubElementsUIListLayout = SubElements.UIListLayout
	local TextButton = Slider.TextButton
	
	local TextLabel = TextButton.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local Line = TextLabel.Line	
	local LineButton = Line.TextButton
	local Fill = Line.Fill
	local Drag = Fill.Drag
	local DragButton = Drag.TextButton
	
	local CurrentValueLabel = DragButton.TextLabel
	CurrentValueLabel.Text = options.default
	CurrentValueLabel.Size = UDim2.fromOffset(CurrentValueLabel.TextBounds.X + 30, 20)
	
	local autoSliderSize = function()
		Utility:tween(Slider, {Size = UDim2.new(1, 0, 0, SliderUIListLayout.AbsoluteContentSize.Y - 8)}):Play()
	end
			
	--// Function calls and Connections
	local SliderOptions = {
		line = Line,
		lineButton = LineButton,
		fill = Fill,
		drag = Drag,
		dragButton = DragButton,
		currentValueLabel = CurrentValueLabel,	
		value = options.default,
		callback = options.callback,
		min = options.min,
		max = options.max,
		default = options.default,
		decimalPlaces = options.decimalPlaces,
	}
		
	local Addons = self:createAddons(SubElements, ImageButton, {
		setValue = function(self, newValue)
			SliderManager:setValue(newValue, SliderOptions)
		end,
		
		getValue = SliderManager:getValue(SliderOptions),
	})
	
	local dragging = Utility:createBoolean(false)
	local showingUI = Utility:createBoolean(false)

	local Events = {
		{UserInputService, "InputChanged", SliderManager:handleSlider(dragging, SliderOptions)},
		{UserInputService, "InputEnded", SliderManager:disableDrag(dragging, SliderOptions)},
		{Line, "MouseEnter", SliderManager:showDragAndCurrentValueLabel(SliderOptions, 0)},
		{Line, "MouseLeave", SliderManager:showDragAndCurrentValueLabel(SliderOptions, 1)},
		{LineButton, "MouseButton1Down", SliderManager:enableDrag(dragging)},
		{DragButton, "MouseButton1Down", SliderManager:enableDrag(dragging)},
		{SliderUIListLayout, "GetPropertyChangedSignal", "AbsoluteContentSize", autoSliderSize},
		{ImageButton, "MouseButton1Down", self:showSubElements(showingUI, SubElements, SubElementsUIListLayout)}
	}
	
	Utility:connectEvents(Library.Connections, Events)
	Flags.Sliders[options.flagName] = Addons
	SliderManager:setValue(options.default, SliderOptions)
	--
	
	return Addons
end
--

--// Make UI Draggable and Resizable
Utility:draggable(Library.Connections, Glow)
Utility:resizable(Library.Connections, RightFolder.Frame.TextButton, Glow)
--

return Library