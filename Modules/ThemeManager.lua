local ThemeManager = {
	Theme = {
		glow = Color3.fromRGB(255, 255, 255),
		main = Color3.fromRGB(106, 128, 255),
		tabOn = Color3.fromRGB(255, 255, 255),
		tabOff = Color3.fromRGB(133, 151, 180),
		background = Color3.fromRGB(255, 255, 255),
		background1 = Color3.fromRGB(233, 233, 235),
	}
}

local Theme = ThemeManager.Theme
local ThemeObjects = {}

for themeIndexName, _ in pairs(Theme) do
	ThemeObjects[themeIndexName] = {}
end

function ThemeManager:insertObjectToThemeManager(objects)
	for i,v in ipairs(objects) do
		table.insert(ThemeObjects[v.theme], {object = v.object, property = v.property})
	end
end

--// refactor later so you can input a table with multiple themes for you to change
function ThemeManager:setTheme(theme, color)
	-- tolerance check because rgb values aren't exact when set to objects. 
	local tolerance = 0.01 -- 1% difference check

	local getDifference = function(colorPropertyOne, colorPropertyTwo)
		return math.abs(colorPropertyOne.R - colorPropertyTwo.R) + math.abs(colorPropertyOne.G - colorPropertyTwo.G) + math.abs(colorPropertyOne.B - colorPropertyTwo.B)
	end

	for _, themeTable in ipairs(ThemeObjects[Theme]) do
		if getDifference(themeTable.object[themeTable.property], Theme[theme]) <= tolerance then
			themeTable.object[themeTable.property] = color
		end
	end

	Theme[theme] = color
end
--

return ThemeManager
