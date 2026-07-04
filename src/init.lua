local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.F1
local GAME_FOLDER = "FUCKASS GAMES"

local Updates = {
	{ title = "UI Built", body = "Better layout, cleaner tabs, profile card, and better spacing." },
	{ title = "Game detection", body = "Brainrot Hub checks this PlaceId against built-in or folder configs." },
	{ title = "Supported games", body = "The Game tab only appears when a matching game config is found." },
}

local SupportedGames = {
	-- Built-in support example:
	-- [game.PlaceId] = {
	-- 	name = "Current Game",
	-- 	actions = {
	-- 		{ title = "Example", description = "Runs code.", callback = function() print("Example") end },
	-- 	},
	-- },
}

local SupportedGameList = {
	-- Put supported games here so unsupported users can teleport to them:
	-- { placeId = 123456789, name = "Supported Game", description = "Short description of this script." },
}

local colors = {
	window = Color3.fromRGB(10, 12, 18),
	top = Color3.fromRGB(16, 19, 29),
	side = Color3.fromRGB(13, 16, 24),
	panel = Color3.fromRGB(19, 23, 34),
	panelAlt = Color3.fromRGB(24, 30, 44),
	line = Color3.fromRGB(52, 62, 86),
	lineSoft = Color3.fromRGB(35, 42, 59),
	title = Color3.fromRGB(246, 248, 255),
	text = Color3.fromRGB(204, 211, 230),
	muted = Color3.fromRGB(132, 143, 168),
	blue = Color3.fromRGB(74, 122, 255),
	cyan = Color3.fromRGB(64, 206, 230),
	green = Color3.fromRGB(57, 210, 143),
	red = Color3.fromRGB(238, 86, 111),
	yellow = Color3.fromRGB(239, 189, 82),
}

local hiddenPosition = UDim2.new(0.5, -360, 0.5, -202)
local shownPosition = UDim2.new(0.5, -360, 0.5, -226)

local oldGui = playerGui:FindFirstChild("BrainrotHubGui")
if oldGui then
	oldGui:Destroy()
end

local legacyGui = playerGui:FindFirstChild("SimpleGui")
if legacyGui then
	legacyGui:Destroy()
end

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
	return item
end

local function stroke(parent, color, transparency, thickness)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Transparency = transparency or 0
	item.Thickness = thickness or 1
	item.Parent = parent
	return item
end

local function padding(parent, left, right, top, bottom)
	local item = Instance.new("UIPadding")
	item.PaddingLeft = UDim.new(0, left or 0)
	item.PaddingRight = UDim.new(0, right or left or 0)
	item.PaddingTop = UDim.new(0, top or 0)
	item.PaddingBottom = UDim.new(0, bottom or top or 0)
	item.Parent = parent
	return item
end

local function label(parent, name, text, size, color, font)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Font = font or Enum.Font.Gotham
	item.Text = text
	item.TextColor3 = color or colors.text
	item.TextSize = size
	item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.Parent = parent
	return item
end

local function tween(item, props, time)
	TweenService:Create(item, TweenInfo.new(time or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function tweenWithStyle(item, props, time, style, direction)
	local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
	local activeTween = TweenService:Create(item, info, props)
	activeTween:Play()
	return activeTween
end

local function tryLoadGameFile(placeId)
	if type(isfile) ~= "function" or type(readfile) ~= "function" or type(loadstring) ~= "function" then
		return nil
	end

	local paths = {
		GAME_FOLDER .. "/" .. tostring(placeId) .. ".lua",
		"fuckass-script/games/" .. tostring(placeId) .. ".lua",
	}

	for _, path in ipairs(paths) do
		if isfile(path) then
			local ok, result = pcall(function()
				return loadstring(readfile(path))()
			end)

			if ok and type(result) == "table" then
				return result, path
			end

			warn("Failed to load game file:", path, result)
		end
	end

	return nil
end

local function getExperienceName()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	return ok and info and info.Name or "Current Experience"
end

local function buildSupportedGameList()
	local seen = {}
	local list = {}

	for _, entry in ipairs(SupportedGameList) do
		if entry.placeId and not seen[entry.placeId] then
			seen[entry.placeId] = true
			table.insert(list, entry)
		end
	end

	for placeId, config in pairs(SupportedGames) do
		if not seen[placeId] then
			seen[placeId] = true
			table.insert(list, {
				placeId = placeId,
				name = type(config) == "table" and config.name or "Supported Game",
				description = "Built into this hub.",
			})
		end
	end

	table.sort(list, function(a, b)
		return tostring(a.name or a.placeId) < tostring(b.name or b.placeId)
	end)

	return list
end

local gameConfig, loadedPath = SupportedGames[game.PlaceId], "Built-in table"
if not gameConfig then
	gameConfig, loadedPath = tryLoadGameFile(game.PlaceId)
end

local gameSupported = type(gameConfig) == "table"
local gameName = gameSupported and (gameConfig.name or getExperienceName()) or getExperienceName()
local supportedGameList = buildSupportedGameList()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 720, 0, 452)
main.Position = hiddenPosition
main.BackgroundColor3 = colors.window
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui
corner(main, 18)
stroke(main, Color3.fromRGB(70, 84, 116), 0.22, 1)

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = main

local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1, 0, 0, 62)
top.BackgroundColor3 = colors.top
top.BorderSizePixel = 0
top.Parent = main

local topGradient = Instance.new("UIGradient")
topGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 15, 23)),
})
topGradient.Rotation = 0
topGradient.Parent = top

local accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Size = UDim2.new(1, 0, 0, 1)
accentLine.Position = UDim2.new(0, 0, 1, -1)
accentLine.BackgroundColor3 = colors.lineSoft
accentLine.BorderSizePixel = 0
accentLine.Parent = top

local title = label(top, "Title", "Brainrot Hub", 19, colors.title, Enum.Font.GothamBold)
title.Size = UDim2.new(0, 260, 0, 24)
title.Position = UDim2.new(0, 20, 0, 11)

local subtitle = label(top, "Subtitle", "the BEST brainrot hub script for slop games, fake it till you make it", 12, colors.muted, Enum.Font.GothamMedium)
subtitle.Size = UDim2.new(0, 280, 0, 18)
subtitle.Position = UDim2.new(0, 20, 0, 37)

local supportBadge = Instance.new("TextLabel")
supportBadge.Name = "SupportBadge"
supportBadge.Size = UDim2.new(0, 128, 0, 30)
supportBadge.Position = UDim2.new(1, -148, 0, 16)
supportBadge.BackgroundColor3 = gameSupported and Color3.fromRGB(22, 83, 61) or Color3.fromRGB(78, 36, 48)
supportBadge.BorderSizePixel = 0
supportBadge.Font = Enum.Font.GothamBold
supportBadge.Text = gameSupported and "SUPPORTED" or "UNSUPPORTED"
supportBadge.TextColor3 = gameSupported and Color3.fromRGB(173, 255, 218) or Color3.fromRGB(255, 170, 188)
supportBadge.TextSize = 11
supportBadge.Parent = top
corner(supportBadge, 10)

local side = Instance.new("Frame")
side.Name = "Sidebar"
side.Size = UDim2.new(0, 148, 1, -62)
side.Position = UDim2.new(0, 0, 0, 62)
side.BackgroundColor3 = colors.side
side.BorderSizePixel = 0
side.Parent = main
padding(side, 0, 0, 0, 0)

local sideLine = Instance.new("Frame")
sideLine.Name = "Divider"
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(0, 147, 0, 62)
sideLine.BackgroundColor3 = colors.lineSoft
sideLine.BorderSizePixel = 0
sideLine.Parent = main

local tabHolder = Instance.new("Frame")
tabHolder.Name = "Tabs"
tabHolder.Size = UDim2.new(1, -28, 1, -28)
tabHolder.Position = UDim2.new(0, 14, 0, 18)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = side

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabHolder

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -148, 1, -62)
content.Position = UDim2.new(0, 148, 0, 62)
content.BackgroundTransparency = 1
content.Parent = main
padding(content, 18, 18, 16, 18)

local pages = {}
local tabs = {}
local selectedTab

local function makePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Position = UDim2.new(0, 0, 0, 8)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = colors.blue
	page.ScrollBarImageTransparency = 0.25
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.Visible = false
	page.Parent = content
	padding(page, 2, 14, 2, 20)
	pages[name] = page
	return page
end

local function selectTab(name)
	selectedTab = name
	for pageName, page in pairs(pages) do
		local active = pageName == name
		page.Visible = active
		if active then
			page.Position = UDim2.new(0, 0, 0, 8)
			tweenWithStyle(page, { Position = UDim2.new(0, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quart)
		end
	end
	for tabName, button in pairs(tabs) do
		local active = tabName == name
		tween(button, {
			BackgroundColor3 = active and colors.blue or Color3.fromRGB(17, 21, 31),
			TextColor3 = active and Color3.fromRGB(255, 255, 255) or colors.text,
		})
	end
end

local function makeTab(name, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(17, 21, 31)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamSemibold
	button.Text = name
	button.TextColor3 = colors.text
	button.TextSize = 13
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.LayoutOrder = order
	button.Parent = tabHolder
	corner(button, 10)
	padding(button, 12, 12, 0, 0)

	button.MouseEnter:Connect(function()
		if selectedTab ~= name then
			tween(button, { BackgroundColor3 = Color3.fromRGB(24, 30, 44) })
		end
	end)

	button.MouseLeave:Connect(function()
		if selectedTab ~= name then
			tween(button, { BackgroundColor3 = Color3.fromRGB(17, 21, 31) })
		end
	end)

	button.MouseButton1Click:Connect(function()
		selectTab(name)
	end)

	tabs[name] = button
	return button
end

local function makePanel(parent, size, position)
	local panel = Instance.new("Frame")
	panel.Size = size
	panel.Position = position or UDim2.new()
	panel.BackgroundColor3 = colors.panel
	panel.BorderSizePixel = 0
	panel.Parent = parent
	corner(panel, 12)
	stroke(panel, colors.lineSoft, 0.15, 1)
	return panel
end

local function addPanelGradient(panel, topColor, bottomColor)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = 90
	gradient.Parent = panel
	return gradient
end

local function makeUpdate(parent, update, order)
	local item = makePanel(parent, UDim2.new(1, 0, 0, 58))
	item.LayoutOrder = order

	local marker = Instance.new("Frame")
	marker.Size = UDim2.new(0, 4, 0, 34)
	marker.Position = UDim2.new(0, 12, 0, 12)
	marker.BackgroundColor3 = order == 1 and colors.blue or (order == 2 and colors.cyan or colors.green)
	marker.BorderSizePixel = 0
	marker.Parent = item

	local updateTitle = label(item, "UpdateTitle", update.title, 13, colors.title, Enum.Font.GothamBold)
	updateTitle.Size = UDim2.new(1, -38, 0, 20)
	updateTitle.Position = UDim2.new(0, 26, 0, 9)

	local updateBody = label(item, "UpdateBody", update.body, 11, colors.muted, Enum.Font.Gotham)
	updateBody.Size = UDim2.new(1, -38, 0, 22)
	updateBody.Position = UDim2.new(0, 26, 0, 29)
	return item
end

local function makeSupportedGameButton(parent, entry, order)
	local button = Instance.new("TextButton")
	button.Name = "SupportedGame"
	button.Size = UDim2.new(1, 0, 0, 72)
	button.BackgroundColor3 = colors.panel
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = order
	button.Parent = parent
	corner(button, 14)
	stroke(button, colors.lineSoft, 0.12, 1)
	addPanelGradient(button, Color3.fromRGB(24, 30, 45), Color3.fromRGB(17, 21, 31))

	local glow = Instance.new("Frame")
	glow.Name = "Accent"
	glow.Size = UDim2.new(0, 5, 1, -24)
	glow.Position = UDim2.new(0, 14, 0, 12)
	glow.BackgroundColor3 = colors.blue
	glow.BorderSizePixel = 0
	glow.Parent = button
	corner(glow, 5)

	local gameTitle = label(button, "GameTitle", entry.name or ("Place " .. tostring(entry.placeId)), 14, colors.title, Enum.Font.GothamBold)
	gameTitle.Size = UDim2.new(1, -150, 0, 22)
	gameTitle.Position = UDim2.new(0, 30, 0, 12)

	local gameBody = label(button, "GameBody", entry.description or "Supported by Brainrot Hub.", 11, colors.muted, Enum.Font.GothamMedium)
	gameBody.Size = UDim2.new(1, -150, 0, 22)
	gameBody.Position = UDim2.new(0, 30, 0, 36)

	local join = Instance.new("TextLabel")
	join.Name = "Join"
	join.Size = UDim2.new(0, 92, 0, 30)
	join.Position = UDim2.new(1, -106, 0.5, -15)
	join.BackgroundColor3 = colors.blue
	join.BorderSizePixel = 0
	join.Font = Enum.Font.GothamBold
	join.Text = "Join"
	join.TextColor3 = Color3.fromRGB(255, 255, 255)
	join.TextSize = 12
	join.Parent = button
	corner(join, 10)

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = colors.panelAlt }, 0.12)
		tween(join, { BackgroundColor3 = Color3.fromRGB(94, 143, 255) }, 0.12)
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = colors.panel }, 0.12)
		tween(join, { BackgroundColor3 = colors.blue }, 0.12)
	end)

	button.MouseButton1Click:Connect(function()
		if entry.placeId then
			TeleportService:Teleport(entry.placeId, player)
		end
	end)

	return button
end

local homePage = makePage("Home")

local welcomePanel = makePanel(homePage, UDim2.new(1, 0, 0, 70))
welcomePanel.Position = UDim2.new(0, 0, 0, 0)
welcomePanel.BackgroundColor3 = Color3.fromRGB(19, 25, 39)
addPanelGradient(welcomePanel, Color3.fromRGB(25, 33, 53), Color3.fromRGB(16, 20, 31))

local welcomeTitle = label(welcomePanel, "WelcomeTitle", "Welcome back, " .. player.DisplayName, 17, colors.title, Enum.Font.GothamBold)
welcomeTitle.Size = UDim2.new(1, -28, 0, 24)
welcomeTitle.Position = UDim2.new(0, 14, 0, 10)

local welcomeBody = label(welcomePanel, "WelcomeBody", "Thanks for using Brainrot Hub. Pick a tab on the left and the hub will handle game support automatically.", 12, colors.text, Enum.Font.GothamMedium)
welcomeBody.Size = UDim2.new(1, -28, 0, 28)
welcomeBody.Position = UDim2.new(0, 14, 0, 34)

local profilePanel = makePanel(homePage, UDim2.new(1, 0, 0, 92))
profilePanel.Position = UDim2.new(0, 0, 0, 82)
addPanelGradient(profilePanel, Color3.fromRGB(20, 25, 37), Color3.fromRGB(16, 20, 29))

local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.Size = UDim2.new(0, 58, 0, 58)
avatar.Position = UDim2.new(0, 16, 0, 17)
avatar.BackgroundColor3 = colors.panelAlt
avatar.BorderSizePixel = 0
avatar.Image = ""
avatar.Parent = profilePanel
corner(avatar, 12)

task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then
		avatar.Image = image
	end
end)

local displayName = label(profilePanel, "DisplayName", player.DisplayName, 17, colors.title, Enum.Font.GothamBold)
displayName.Size = UDim2.new(1, -96, 0, 24)
displayName.Position = UDim2.new(0, 88, 0, 16)

local username = label(profilePanel, "Username", "@" .. player.Name .. "  |  UserId " .. tostring(player.UserId), 12, colors.muted, Enum.Font.GothamMedium)
username.Size = UDim2.new(1, -96, 0, 18)
username.Position = UDim2.new(0, 88, 0, 40)

local place = label(profilePanel, "Place", gameName .. "  |  PlaceId " .. tostring(game.PlaceId), 12, gameSupported and colors.green or colors.red, Enum.Font.GothamSemibold)
place.Size = UDim2.new(1, -96, 0, 18)
place.Position = UDim2.new(0, 88, 0, 60)

local updatesTitle = label(homePage, "UpdatesTitle", "Updates", 15, colors.title, Enum.Font.GothamBold)
updatesTitle.Size = UDim2.new(1, 0, 0, 24)
updatesTitle.Position = UDim2.new(0, 0, 0, 188)

local updatesHolder = Instance.new("Frame")
updatesHolder.Name = "Updates"
updatesHolder.Size = UDim2.new(1, 0, 1, -218)
updatesHolder.Position = UDim2.new(0, 0, 0, 218)
updatesHolder.BackgroundTransparency = 1
updatesHolder.Parent = homePage

local updatesLayout = Instance.new("UIListLayout")
updatesLayout.Padding = UDim.new(0, 8)
updatesLayout.SortOrder = Enum.SortOrder.LayoutOrder
updatesLayout.Parent = updatesHolder

for index, update in ipairs(Updates) do
	makeUpdate(updatesHolder, update, index)
end

local hubPage = makePage("Brainrot Hub")

local supportPanel = makePanel(hubPage, UDim2.new(1, 0, 0, 126))
supportPanel.Position = UDim2.new(0, 0, 0, 0)
supportPanel.BackgroundColor3 = Color3.fromRGB(21, 26, 39)
addPanelGradient(supportPanel, Color3.fromRGB(28, 35, 54), Color3.fromRGB(17, 21, 32))

local supportTitle = label(supportPanel, "SupportTitle", gameSupported and "This game is supported" or "This game is not supported yet", 18, gameSupported and colors.green or colors.red, Enum.Font.GothamBold)
supportTitle.Size = UDim2.new(1, -180, 0, 28)
supportTitle.Position = UDim2.new(0, 18, 0, 16)

local supportBodyText = gameSupported
	and ("Loaded config for " .. gameName .. ". The Game tab is ready.")
	or "Pick a supported game below to teleport there, or add this PlaceId to your configs."
local supportBody = label(supportPanel, "SupportBody", supportBodyText, 12, colors.text, Enum.Font.GothamMedium)
supportBody.Size = UDim2.new(1, -36, 0, 34)
supportBody.Position = UDim2.new(0, 18, 0, 47)

local sourceText = gameSupported and ("Source: " .. tostring(loadedPath or "Unknown")) or ("Expected file: " .. GAME_FOLDER .. "/" .. tostring(game.PlaceId) .. ".lua")
local source = label(supportPanel, "Source", sourceText, 11, colors.muted, Enum.Font.GothamMedium)
source.Size = UDim2.new(1, -36, 0, 18)
source.Position = UDim2.new(0, 18, 0, 88)

local supportStatus = Instance.new("TextLabel")
supportStatus.Name = "SupportStatus"
supportStatus.Size = UDim2.new(0, 132, 0, 34)
supportStatus.Position = UDim2.new(1, -150, 0, 18)
supportStatus.BackgroundColor3 = gameSupported and Color3.fromRGB(23, 88, 64) or Color3.fromRGB(88, 40, 55)
supportStatus.BorderSizePixel = 0
supportStatus.Font = Enum.Font.GothamBold
supportStatus.Text = gameSupported and "READY" or "NO CONFIG"
supportStatus.TextColor3 = gameSupported and Color3.fromRGB(177, 255, 223) or Color3.fromRGB(255, 171, 190)
supportStatus.TextSize = 12
supportStatus.Parent = supportPanel
corner(supportStatus, 12)

local infoGrid = Instance.new("Frame")
infoGrid.Size = UDim2.new(1, 0, 0, 86)
infoGrid.Position = UDim2.new(0, 0, 0, 140)
infoGrid.BackgroundTransparency = 1
infoGrid.Parent = hubPage

local leftInfo = makePanel(infoGrid, UDim2.new(0.333, -8, 1, 0), UDim2.new(0, 0, 0, 0))
local middleInfo = makePanel(infoGrid, UDim2.new(0.334, -8, 1, 0), UDim2.new(0.333, 4, 0, 0))
local rightInfo = makePanel(infoGrid, UDim2.new(0.333, -8, 1, 0), UDim2.new(0.667, 8, 0, 0))

local placeTitle = label(leftInfo, "PlaceTitle", "PlaceId", 12, colors.muted, Enum.Font.GothamSemibold)
placeTitle.Size = UDim2.new(1, -24, 0, 18)
placeTitle.Position = UDim2.new(0, 12, 0, 12)
local placeValue = label(leftInfo, "PlaceValue", tostring(game.PlaceId), 14, colors.title, Enum.Font.GothamBold)
placeValue.Size = UDim2.new(1, -24, 0, 26)
placeValue.Position = UDim2.new(0, 12, 0, 36)

local supportedTitle = label(middleInfo, "SupportedTitle", "Supported Games", 12, colors.muted, Enum.Font.GothamSemibold)
supportedTitle.Size = UDim2.new(1, -24, 0, 18)
supportedTitle.Position = UDim2.new(0, 12, 0, 12)
local supportedValue = label(middleInfo, "SupportedValue", tostring(#supportedGameList), 18, colors.blue, Enum.Font.GothamBold)
supportedValue.Size = UDim2.new(1, -24, 0, 26)
supportedValue.Position = UDim2.new(0, 12, 0, 36)

local statusTitle = label(rightInfo, "StatusTitle", "Status", 12, colors.muted, Enum.Font.GothamSemibold)
statusTitle.Size = UDim2.new(1, -24, 0, 18)
statusTitle.Position = UDim2.new(0, 12, 0, 12)
local statusValue = label(rightInfo, "StatusValue", gameSupported and "Ready" or "Unsupported", 16, gameSupported and colors.green or colors.yellow, Enum.Font.GothamBold)
statusValue.Size = UDim2.new(1, -24, 0, 26)
statusValue.Position = UDim2.new(0, 12, 0, 36)

local supportedListTitle = label(hubPage, "SupportedListTitle", gameSupported and "Other Supported Games" or "Supported Games", 15, colors.title, Enum.Font.GothamBold)
supportedListTitle.Size = UDim2.new(1, 0, 0, 24)
supportedListTitle.Position = UDim2.new(0, 0, 0, 244)

local supportedList = Instance.new("Frame")
supportedList.Name = "SupportedGames"
supportedList.Size = UDim2.new(1, 0, 0, math.max(84, #supportedGameList * 80))
supportedList.Position = UDim2.new(0, 0, 0, 274)
supportedList.BackgroundTransparency = 1
supportedList.Parent = hubPage

local supportedLayout = Instance.new("UIListLayout")
supportedLayout.Padding = UDim.new(0, 8)
supportedLayout.SortOrder = Enum.SortOrder.LayoutOrder
supportedLayout.Parent = supportedList

if #supportedGameList == 0 then
	local emptyList = makePanel(supportedList, UDim2.new(1, 0, 0, 76))
	emptyList.LayoutOrder = 1
	local emptyTitle = label(emptyList, "EmptyTitle", "No supported games listed yet", 14, colors.title, Enum.Font.GothamBold)
	emptyTitle.Size = UDim2.new(1, -28, 0, 22)
	emptyTitle.Position = UDim2.new(0, 14, 0, 12)
	local emptyBody = label(emptyList, "EmptyBody", "Add entries to SupportedGameList so unsupported users can teleport to them.", 12, colors.muted, Enum.Font.Gotham)
	emptyBody.Size = UDim2.new(1, -28, 0, 28)
	emptyBody.Position = UDim2.new(0, 14, 0, 36)
else
	for index, entry in ipairs(supportedGameList) do
		makeSupportedGameButton(supportedList, entry, index)
	end
end

if gameSupported then
	local gamePage = makePage("Game")
	local gameHeader = label(gamePage, "GameHeader", gameName, 18, colors.title, Enum.Font.GothamBold)
	gameHeader.Size = UDim2.new(1, 0, 0, 28)
	gameHeader.Position = UDim2.new(0, 0, 0, 0)

	local actionsHolder = Instance.new("Frame")
	actionsHolder.Size = UDim2.new(1, 0, 1, -42)
	actionsHolder.Position = UDim2.new(0, 0, 0, 42)
	actionsHolder.BackgroundTransparency = 1
	actionsHolder.Parent = gamePage

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.Padding = UDim.new(0, 8)
	actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	actionLayout.Parent = actionsHolder

	local actions = type(gameConfig.actions) == "table" and gameConfig.actions or {}
	if #actions == 0 then
		local empty = makePanel(actionsHolder, UDim2.new(1, 0, 0, 70))
		label(empty, "EmptyTitle", "No actions yet", 14, colors.title, Enum.Font.GothamBold).Position = UDim2.new(0, 14, 0, 13)
		local body = label(empty, "EmptyBody", "Add actions to this game config to show controls here.", 12, colors.muted, Enum.Font.Gotham)
		body.Size = UDim2.new(1, -28, 0, 22)
		body.Position = UDim2.new(0, 14, 0, 36)
	else
		for _, action in ipairs(actions) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 62)
			button.BackgroundColor3 = colors.panel
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.Text = ""
			button.Parent = actionsHolder
			corner(button, 12)
			stroke(button, colors.lineSoft, 0.15, 1)

			local actionTitle = label(button, "ActionTitle", action.title or "Game Action", 14, colors.title, Enum.Font.GothamBold)
			actionTitle.Size = UDim2.new(1, -28, 0, 22)
			actionTitle.Position = UDim2.new(0, 14, 0, 9)
			local actionBody = label(button, "ActionBody", action.description or "Run this game action.", 11, colors.muted, Enum.Font.Gotham)
			actionBody.Size = UDim2.new(1, -28, 0, 22)
			actionBody.Position = UDim2.new(0, 14, 0, 31)

			button.MouseEnter:Connect(function()
				tween(button, { BackgroundColor3 = colors.panelAlt })
			end)
			button.MouseLeave:Connect(function()
				tween(button, { BackgroundColor3 = colors.panel })
			end)
			button.MouseButton1Click:Connect(function()
				if type(action.callback) == "function" then
					local ok, err = pcall(action.callback)
					if not ok then
						warn("Game action failed:", err)
					end
				end
			end)
		end
	end
end

makeTab("Home", 1)
makeTab("Brainrot Hub", 2)
if gameSupported then
	makeTab("Game", 3)
end
selectTab("Home")

local toast = Instance.new("Frame")
toast.Name = "WelcomeToast"
toast.Size = UDim2.new(0, 280, 0, 54)
toast.Position = UDim2.new(1, -298, 1, 16)
toast.BackgroundColor3 = Color3.fromRGB(20, 25, 37)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Parent = main
	corner(toast, 12)
stroke(toast, colors.lineSoft, 1, 1)

local toastTitle = label(toast, "ToastTitle", "Welcome to Brainrot Hub", 13, colors.title, Enum.Font.GothamBold)
toastTitle.Size = UDim2.new(1, -24, 0, 20)
toastTitle.Position = UDim2.new(0, 12, 0, 8)
toastTitle.TextTransparency = 1

local toastBody = label(toast, "ToastBody", "Thanks for using the script.", 11, colors.muted, Enum.Font.GothamMedium)
toastBody.Size = UDim2.new(1, -24, 0, 18)
toastBody.Position = UDim2.new(0, 12, 0, 28)
toastBody.TextTransparency = 1

local uiOpen = true

local function showToast()
	toast.Position = UDim2.new(1, -298, 1, 16)
	tweenWithStyle(toast, { Position = UDim2.new(1, -298, 1, -72), BackgroundTransparency = 0 }, 0.35, Enum.EasingStyle.Back)
	tween(toastTitle, { TextTransparency = 0 }, 0.18)
	tween(toastBody, { TextTransparency = 0 }, 0.18)
	task.delay(3, function()
		if toast and toast.Parent then
			tweenWithStyle(toast, { Position = UDim2.new(1, -298, 1, 16), BackgroundTransparency = 1 }, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			tween(toastTitle, { TextTransparency = 1 }, 0.16)
			tween(toastBody, { TextTransparency = 1 }, 0.16)
		end
	end)
end

local function showUi()
	screenGui.Enabled = true
	uiOpen = true
	main.Position = hiddenPosition
	main.BackgroundTransparency = 1
	scale.Scale = 0.985
	tweenWithStyle(main, { Position = shownPosition, BackgroundTransparency = 0 }, 0.22, Enum.EasingStyle.Quart)
	tweenWithStyle(scale, { Scale = 1 }, 0.22, Enum.EasingStyle.Quart)
end

local function hideUi()
	uiOpen = false
	tweenWithStyle(main, { Position = hiddenPosition, BackgroundTransparency = 1 }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	tweenWithStyle(scale, { Scale = 0.985 }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	task.delay(0.19, function()
		if not uiOpen then
			screenGui.Enabled = false
		end
	end)
end

showUi()
task.delay(0.45, showToast)

local dragging = false
local dragStart
local mainStart

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + delta.X, mainStart.Y.Scale, mainStart.Y.Offset + delta.Y)
end

top.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	dragging = true
	dragStart = input.Position
	mainStart = main.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TOGGLE_KEY then
		if uiOpen then
			hideUi()
		else
			showUi()
		end
	end
end)
