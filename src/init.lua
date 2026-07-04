local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.F1
local GAME_FOLDER = "FUCKASS GAMES"

local Updates = {
	{ title = "UI Built", body = "Sharper layout, cleaner tabs, profile card, and better spacing." },
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

local colors = {
	window = Color3.fromRGB(10, 12, 18),
	top = Color3.fromRGB(15, 18, 27),
	side = Color3.fromRGB(12, 15, 22),
	panel = Color3.fromRGB(18, 22, 32),
	panelAlt = Color3.fromRGB(21, 26, 38),
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

local gameConfig, loadedPath = SupportedGames[game.PlaceId], "Built-in table"
if not gameConfig then
	gameConfig, loadedPath = tryLoadGameFile(game.PlaceId)
end

local gameSupported = type(gameConfig) == "table"
local gameName = gameSupported and (gameConfig.name or getExperienceName()) or getExperienceName()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(0, 610, 0, 386)
shadow.Position = UDim2.new(0.5, -296, 0.5, -184)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel = 0
shadow.Parent = screenGui
corner(shadow, 8)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 600, 0, 376)
main.Position = UDim2.new(0.5, -300, 0.5, -194)
main.BackgroundColor3 = colors.window
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui
corner(main, 8)
stroke(main, colors.line, 0.18, 1)

local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1, 0, 0, 64)
top.BackgroundColor3 = colors.top
top.BorderSizePixel = 0
top.Parent = main

local title = label(top, "Title", "Brainrot Hub", 19, colors.title, Enum.Font.GothamBold)
title.Size = UDim2.new(0, 260, 0, 24)
title.Position = UDim2.new(0, 18, 0, 12)

local subtitle = label(top, "Subtitle", "F1 toggles the menu", 12, colors.muted, Enum.Font.GothamMedium)
subtitle.Size = UDim2.new(0, 280, 0, 18)
subtitle.Position = UDim2.new(0, 18, 0, 38)

local supportBadge = Instance.new("TextLabel")
supportBadge.Name = "SupportBadge"
supportBadge.Size = UDim2.new(0, 128, 0, 30)
supportBadge.Position = UDim2.new(1, -146, 0, 17)
supportBadge.BackgroundColor3 = gameSupported and Color3.fromRGB(22, 83, 61) or Color3.fromRGB(78, 36, 48)
supportBadge.BorderSizePixel = 0
supportBadge.Font = Enum.Font.GothamBold
supportBadge.Text = gameSupported and "SUPPORTED" or "UNSUPPORTED"
supportBadge.TextColor3 = gameSupported and Color3.fromRGB(173, 255, 218) or Color3.fromRGB(255, 170, 188)
supportBadge.TextSize = 11
supportBadge.Parent = top
corner(supportBadge, 5)

local side = Instance.new("Frame")
side.Name = "Sidebar"
side.Size = UDim2.new(0, 154, 1, -64)
side.Position = UDim2.new(0, 0, 0, 64)
side.BackgroundColor3 = colors.side
side.BorderSizePixel = 0
side.Parent = main
padding(side, 14, 14, 14, 14)

local sideLine = Instance.new("Frame")
sideLine.Name = "Divider"
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = colors.lineSoft
sideLine.BorderSizePixel = 0
sideLine.Parent = side

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = side

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -154, 1, -64)
content.Position = UDim2.new(0, 154, 0, 64)
content.BackgroundTransparency = 1
content.Parent = main
padding(content, 16, 16, 14, 16)

local pages = {}
local tabs = {}
local selectedTab

local function makePage(name)
	local page = Instance.new("Frame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = content
	pages[name] = page
	return page
end

local function selectTab(name)
	selectedTab = name
	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
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
	button.Parent = side
	corner(button, 5)
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
	corner(panel, 6)
	stroke(panel, colors.lineSoft, 0.15, 1)
	return panel
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

local homePage = makePage("Home")

local profilePanel = makePanel(homePage, UDim2.new(1, 0, 0, 92))
profilePanel.Position = UDim2.new(0, 0, 0, 0)

local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.Size = UDim2.new(0, 58, 0, 58)
avatar.Position = UDim2.new(0, 16, 0, 17)
avatar.BackgroundColor3 = colors.panelAlt
avatar.BorderSizePixel = 0
avatar.Image = ""
avatar.Parent = profilePanel
corner(avatar, 6)

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
updatesTitle.Position = UDim2.new(0, 0, 0, 106)

local updatesHolder = Instance.new("Frame")
updatesHolder.Name = "Updates"
updatesHolder.Size = UDim2.new(1, 0, 1, -136)
updatesHolder.Position = UDim2.new(0, 0, 0, 136)
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

local supportPanel = makePanel(hubPage, UDim2.new(1, 0, 0, 112))
supportPanel.Position = UDim2.new(0, 0, 0, 0)

local supportTitle = label(supportPanel, "SupportTitle", gameSupported and "This game is supported" or "This game is not supported yet", 18, gameSupported and colors.green or colors.red, Enum.Font.GothamBold)
supportTitle.Size = UDim2.new(1, -28, 0, 28)
supportTitle.Position = UDim2.new(0, 14, 0, 14)

local supportBody = label(supportPanel, "SupportBody", gameSupported and ("Loaded config for " .. gameName .. ".") or "No config matched this PlaceId. Add a file named with this PlaceId to support it.", 12, colors.text, Enum.Font.Gotham)
supportBody.Size = UDim2.new(1, -28, 0, 38)
supportBody.Position = UDim2.new(0, 14, 0, 44)

local sourceText = gameSupported and ("Source: " .. tostring(loadedPath or "Unknown")) or ("Expected file: " .. GAME_FOLDER .. "/" .. tostring(game.PlaceId) .. ".lua")
local source = label(supportPanel, "Source", sourceText, 11, colors.muted, Enum.Font.GothamMedium)
source.Size = UDim2.new(1, -28, 0, 18)
source.Position = UDim2.new(0, 14, 0, 82)

local infoGrid = Instance.new("Frame")
infoGrid.Size = UDim2.new(1, 0, 0, 86)
infoGrid.Position = UDim2.new(0, 0, 0, 126)
infoGrid.BackgroundTransparency = 1
infoGrid.Parent = hubPage

local leftInfo = makePanel(infoGrid, UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0))
local rightInfo = makePanel(infoGrid, UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0))

local placeTitle = label(leftInfo, "PlaceTitle", "PlaceId", 12, colors.muted, Enum.Font.GothamSemibold)
placeTitle.Size = UDim2.new(1, -24, 0, 18)
placeTitle.Position = UDim2.new(0, 12, 0, 12)
local placeValue = label(leftInfo, "PlaceValue", tostring(game.PlaceId), 16, colors.title, Enum.Font.GothamBold)
placeValue.Size = UDim2.new(1, -24, 0, 26)
placeValue.Position = UDim2.new(0, 12, 0, 36)

local statusTitle = label(rightInfo, "StatusTitle", "Status", 12, colors.muted, Enum.Font.GothamSemibold)
statusTitle.Size = UDim2.new(1, -24, 0, 18)
statusTitle.Position = UDim2.new(0, 12, 0, 12)
local statusValue = label(rightInfo, "StatusValue", gameSupported and "Ready" or "Waiting for config", 16, gameSupported and colors.green or colors.yellow, Enum.Font.GothamBold)
statusValue.Size = UDim2.new(1, -24, 0, 26)
statusValue.Position = UDim2.new(0, 12, 0, 36)

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
			corner(button, 6)
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

local dragging = false
local dragStart
local mainStart
local shadowStart

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + delta.X, mainStart.Y.Scale, mainStart.Y.Offset + delta.Y)
	shadow.Position = UDim2.new(shadowStart.X.Scale, shadowStart.X.Offset + delta.X, shadowStart.Y.Scale, shadowStart.Y.Offset + delta.Y)
end

top.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	dragging = true
	dragStart = input.Position
	mainStart = main.Position
	shadowStart = shadow.Position

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
		screenGui.Enabled = not screenGui.Enabled
	end
end)
