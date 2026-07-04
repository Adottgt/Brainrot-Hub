local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOGGLE_KEY = Enum.KeyCode.F1
local GAME_FOLDER = "FUCKASS GAMES"
local CONFIG_FOLDER = "BrainrotHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/settings.cfg"
local CONFIG_FALLBACK_FILE = "BrainrotHub_settings.cfg"

local SupportedGameList = {
	-- Add jobId to try joining a specific public server:
	-- { placeId = 97508801613157, jobId = "fc87d6d3-cdbd-41b6-bbc3-55c4a7572c16", name = "Parkour Run For Brainrots!", description = "Supported Brainrot Game!" },
	{ placeId = 97508801613157, name = "Parkour Run For Brainrots!", description = "Supported Brainrot Game!" },
}

local ConsoleOwners = {
	-- Your account is added by name so owner tools work even if UserId changes in testing.
	ciagovmainalt03 = true,
	[10356151318] = true,
}

local Updates = {
	{ title = "UI rebuilt", body = "Clean rounded shell, smoother spacing, and scrollable pages." },
	{ title = "Supported games", body = "Unsupported games now show places you can join." },
	{ title = "Game detection", body = "Configs can come from built-in entries or PlaceId files." },
}

local SupportedGames = {
	[97508801613157] = {
		name = "Parkour Run for Brainrots",
		actions = {
			{
				title = "Toggle Mythical Farm",
				description = "Moves to the farm spot and buys when mythical brainrots spawn.",
				callback = function()
					local env = getgenv and getgenv() or _G
					env.brainrotHubFarming = not env.brainrotHubFarming

					if not env.brainrotHubFarming then
						return
					end

					local plr = game:GetService("Players").LocalPlayer
					local replicatedStorage = game:GetService("ReplicatedStorage")
					local event = replicatedStorage
						:WaitForChild("Packages")
						:WaitForChild("_Index")
						:WaitForChild("sleitnick_net@0.2.0")
						:WaitForChild("net")
						:WaitForChild("RF/Buy NeuronBase")

					task.spawn(function()
						while env.brainrotHubFarming do
							local character = plr.Character or plr.CharacterAdded:Wait()
							character:MoveTo(Vector3.new(12378, 1498, 231))

							local spawner = workspace:FindFirstChild("BG_BrainrotSpawner")
							if spawner then
								for _, spawnFolder in ipairs(spawner:GetChildren()) do
									local brainrot = spawnFolder:FindFirstChildOfClass("Model")
									if spawnFolder.Name == "Mythical" and brainrot and brainrot.PrimaryPart then
										if not brainrot.PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then
											repeat
												task.wait()
											until not env.brainrotHubFarming or brainrot.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
										end

										if env.brainrotHubFarming then
											event:FireServer()
											task.wait(1)
										end
									end
								end
							end

							task.wait(0.1)
						end
					end)
				end,
			},
		},
	},
	-- [114640202062357] = {
	-- 	name = "Swing Obby for Brainrots",
	-- 	actions = {
	-- 		{ title = "Example Action", description = "Runs code.", callback = function() print("Example") end },
	-- 	},
	-- },
}

local colors = {
	bg = Color3.fromRGB(8, 10, 16),
	surface = Color3.fromRGB(14, 18, 28),
	surface2 = Color3.fromRGB(19, 24, 36),
	surface3 = Color3.fromRGB(25, 31, 46),
	line = Color3.fromRGB(48, 59, 84),
	text = Color3.fromRGB(235, 240, 255),
	muted = Color3.fromRGB(145, 156, 184),
	blue = Color3.fromRGB(79, 126, 255),
	cyan = Color3.fromRGB(67, 214, 231),
	green = Color3.fromRGB(74, 221, 151),
	red = Color3.fromRGB(255, 93, 127),
	yellow = Color3.fromRGB(242, 194, 88),
}

local accentColor = colors.blue
local transparencyAmount = 0
local themedObjects = {}
local transparentObjects = {}
local notify

local function trackTheme(object, property)
	table.insert(themedObjects, { object = object, property = property or "BackgroundColor3" })
	object[property or "BackgroundColor3"] = accentColor
	return object
end

local function trackTransparency(object, baseTransparency)
	table.insert(transparentObjects, { object = object, base = baseTransparency or object.BackgroundTransparency or 0 })
	return object
end

local function ensureFolder(path)
	if type(makefolder) ~= "function" then
		return
	end

	if type(isfolder) == "function" then
		if not isfolder(path) then
			pcall(makefolder, path)
		end
	else
		pcall(makefolder, path)
	end
end

local function colorToText(color)
	return tostring(math.floor(color.R * 255 + 0.5)) .. "," .. tostring(math.floor(color.G * 255 + 0.5)) .. "," .. tostring(math.floor(color.B * 255 + 0.5))
end

local function textToColor(text)
	local r, g, b = tostring(text):match("(%d+),(%d+),(%d+)")
	if not r then
		return nil
	end
	return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
end

local function loadSettings()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then
		return {}
	end

	local path = isfile(CONFIG_FILE) and CONFIG_FILE or (isfile(CONFIG_FALLBACK_FILE) and CONFIG_FALLBACK_FILE or nil)
	if not path then
		return {}
	end

	local ok, data = pcall(readfile, path)
	if not ok or type(data) ~= "string" then
		return {}
	end

	local settings = {}
	for line in data:gmatch("[^\r\n]+") do
		local key, value = line:match("^([^=]+)=(.*)$")
		if key then
			settings[key] = value
		end
	end
	return settings
end

local function saveSettings()
	if type(writefile) ~= "function" then
		return false
	end

	ensureFolder(CONFIG_FOLDER)
	local data = "accent=" .. colorToText(accentColor) .. "\ntransparency=" .. tostring(transparencyAmount)
	local ok = pcall(writefile, CONFIG_FILE, data)
	if ok then
		return true
	end

	return pcall(writefile, CONFIG_FALLBACK_FILE, data)
end

local savedSettings = loadSettings()
if savedSettings.accent then
	local savedAccent = textToColor(savedSettings.accent)
	if savedAccent then
		accentColor = savedAccent
		colors.blue = savedAccent
	end
end
if savedSettings.transparency then
	transparencyAmount = tonumber(savedSettings.transparency) or 0
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

local function gradient(parent, topColor, bottomColor)
	local item = Instance.new("UIGradient")
	item.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	item.Rotation = 90
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

local function tween(item, props, time, style, direction)
	local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
	local activeTween = TweenService:Create(item, info, props)
	activeTween:Play()
	return activeTween
end

local function getExperienceName(placeId)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(placeId or game.PlaceId)
	end)
	return ok and info and info.Name or "Current Experience"
end

local function isConsoleOwner()
	return ConsoleOwners[player.UserId] == true or ConsoleOwners[player.Name] == true or ConsoleOwners[string.lower(player.Name)] == true
end

local function getListedGame(placeId)
	for _, entry in ipairs(SupportedGameList) do
		if tonumber(entry.placeId) == tonumber(placeId) then
			return entry
		end
	end
	return nil
end

local function tryLoadGameFile(placeId)
	if type(isfile) ~= "function" or type(readfile) ~= "function" or type(loadstring) ~= "function" then
		return nil
	end

	for _, path in ipairs({
		GAME_FOLDER .. "/" .. tostring(placeId) .. ".lua",
		"fuckass-script/games/" .. tostring(placeId) .. ".lua",
	}) do
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
				name = type(config) == "table" and config.name or ("Place " .. tostring(placeId)),
				description = "Built into Brainrot Hub.",
			})
		end
	end

	if type(listfiles) == "function" then
		for _, folder in ipairs({ GAME_FOLDER, "fuckass-script/games" }) do
			local ok, files = pcall(function()
				return listfiles(folder)
			end)
			if ok and type(files) == "table" then
				for _, path in ipairs(files) do
					local placeIdText = tostring(path):match("([%d]+)%.lua$")
					local placeId = tonumber(placeIdText)
					if placeId and not seen[placeId] then
						seen[placeId] = true
						table.insert(list, {
							placeId = placeId,
							name = "Place " .. placeIdText,
							description = "Detected from " .. folder .. ".",
						})
					end
				end
			end
		end
	end

	table.sort(list, function(a, b)
		return tostring(a.name or a.placeId) < tostring(b.name or b.placeId)
	end)

	return list
end

local oldGui = playerGui:FindFirstChild("BrainrotHubGui")
if oldGui then oldGui:Destroy() end

local legacyGui = playerGui:FindFirstChild("SimpleGui")
if legacyGui then legacyGui:Destroy() end

local listedGame = getListedGame(game.PlaceId)
local gameConfig, loadedPath = SupportedGames[game.PlaceId], "Built-in table"
if not gameConfig then
	gameConfig, loadedPath = tryLoadGameFile(game.PlaceId)
end
if not gameConfig and listedGame then
	gameConfig = {
		name = listedGame.name,
		actions = listedGame.actions or {},
	}
	loadedPath = "SupportedGameList"
end

local gameSupported = type(gameConfig) == "table"
local gameName = gameSupported and (gameConfig.name or getExperienceName(game.PlaceId)) or getExperienceName(game.PlaceId)
local supportedGames = buildSupportedGameList()
local consoleOwner = isConsoleOwner()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 720, 0, 460)
main.Position = UDim2.new(0.5, -360, 0.5, -230)
main.BackgroundColor3 = colors.bg
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui
trackTransparency(main, 0)
corner(main, 22)
stroke(main, Color3.fromRGB(72, 88, 126), 0.22, 1)
gradient(main, Color3.fromRGB(15, 18, 28), Color3.fromRGB(7, 9, 15))

local scale = Instance.new("UIScale")
scale.Scale = 0.985
scale.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, -28, 0, 64)
header.Position = UDim2.new(0, 14, 0, 14)
header.BackgroundColor3 = colors.surface
header.BorderSizePixel = 0
header.Parent = main
trackTransparency(header, 0)
corner(header, 18)
stroke(header, colors.line, 0.38, 1)
gradient(header, Color3.fromRGB(20, 25, 38), Color3.fromRGB(13, 16, 25))

local title = label(header, "Title", "Brainrot Hub", 19, colors.text, Enum.Font.GothamBold)
title.Size = UDim2.new(0, 260, 0, 24)
title.Position = UDim2.new(0, 18, 0, 11)

local subtitle = label(header, "Subtitle", "the BEST brainrot script for slop ahh games, fake it till you make it", 12, colors.muted, Enum.Font.GothamMedium)
subtitle.Size = UDim2.new(0, 340, 0, 18)
subtitle.Position = UDim2.new(0, 18, 0, 37)

local supportBadge = Instance.new("TextLabel")
supportBadge.Name = "SupportBadge"
supportBadge.Size = UDim2.new(0, 132, 0, 32)
supportBadge.Position = UDim2.new(1, -150, 0.5, -16)
supportBadge.BackgroundColor3 = gameSupported and Color3.fromRGB(24, 86, 63) or Color3.fromRGB(88, 39, 55)
supportBadge.BorderSizePixel = 0
supportBadge.Font = Enum.Font.GothamBold
supportBadge.Text = gameSupported and "SUPPORTED" or "UNSUPPORTED"
supportBadge.TextColor3 = gameSupported and Color3.fromRGB(179, 255, 223) or Color3.fromRGB(255, 177, 194)
supportBadge.TextSize = 11
supportBadge.Parent = header
corner(supportBadge, 14)

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -28, 1, -100)
body.Position = UDim2.new(0, 14, 0, 86)
body.BackgroundTransparency = 1
body.Parent = main

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = colors.surface
sidebar.BorderSizePixel = 0
sidebar.Parent = body
trackTransparency(sidebar, 0)
corner(sidebar, 18)
stroke(sidebar, colors.line, 0.5, 1)
gradient(sidebar, Color3.fromRGB(16, 20, 31), Color3.fromRGB(10, 13, 20))
padding(sidebar, 14, 14, 14, 14)

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 10)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = sidebar

local contentShell = Instance.new("Frame")
contentShell.Name = "ContentShell"
contentShell.Size = UDim2.new(1, -166, 1, 0)
contentShell.Position = UDim2.new(0, 166, 0, 0)
contentShell.BackgroundColor3 = colors.surface
contentShell.BorderSizePixel = 0
contentShell.ClipsDescendants = true
contentShell.Parent = body
trackTransparency(contentShell, 0)
corner(contentShell, 18)
stroke(contentShell, colors.line, 0.5, 1)
gradient(contentShell, Color3.fromRGB(15, 19, 29), Color3.fromRGB(9, 12, 18))
padding(contentShell, 16, 16, 16, 16)

local pages = {}
local tabs = {}
local selectedTab

local function makePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 5
	page.ScrollBarImageColor3 = accentColor
	page.ScrollBarImageTransparency = 0.18
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = contentShell
	trackTheme(page, "ScrollBarImageColor3")
	padding(page, 2, 14, 2, 20)
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
			BackgroundColor3 = active and accentColor or colors.surface2,
			TextColor3 = active and Color3.fromRGB(255, 255, 255) or colors.text,
		}, 0.14)
	end
end

local function makeTab(name, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = colors.surface2
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamSemibold
	button.Text = name
	button.TextColor3 = colors.text
	button.TextSize = 13
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.LayoutOrder = order
	button.Parent = sidebar
	corner(button, 14)
	padding(button, 13, 13, 0, 0)

	button.MouseEnter:Connect(function()
		if selectedTab ~= name then
			tween(button, { BackgroundColor3 = colors.surface3 }, 0.12)
		end
	end)

	button.MouseLeave:Connect(function()
		if selectedTab ~= name then
			tween(button, { BackgroundColor3 = colors.surface2 }, 0.12)
		end
	end)

	button.MouseButton1Click:Connect(function()
		selectTab(name)
		if notify then
			notify("Opened " .. name, "Tab switched.", accentColor)
		end
	end)

	tabs[name] = button
	return button
end

local function makePanel(parent, height)
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, 0, 0, height)
	panel.BackgroundColor3 = colors.surface2
	panel.BorderSizePixel = 0
	panel.Parent = parent
	trackTransparency(panel, 0)
	corner(panel, 16)
	stroke(panel, colors.line, 0.52, 1)
	gradient(panel, Color3.fromRGB(22, 27, 41), Color3.fromRGB(15, 19, 29))
	return panel
end

local function addVerticalLayout(parent, paddingPixels)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, paddingPixels or 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function makeInfoCard(parent, titleText, valueText, valueColor)
	local card = makePanel(parent, 78)
	local titleLabel = label(card, "Title", titleText, 12, colors.muted, Enum.Font.GothamSemibold)
	titleLabel.Size = UDim2.new(1, -24, 0, 18)
	titleLabel.Position = UDim2.new(0, 12, 0, 12)

	local valueLabel = label(card, "Value", valueText, 15, valueColor or colors.text, Enum.Font.GothamBold)
	valueLabel.Size = UDim2.new(1, -24, 0, 28)
	valueLabel.Position = UDim2.new(0, 12, 0, 36)
	return card
end

local function makeSupportedGameButton(parent, entry, order)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 76)
	button.BackgroundColor3 = colors.surface2
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = order
	button.Parent = parent
	corner(button, 16)
	stroke(button, colors.line, 0.45, 1)
	gradient(button, Color3.fromRGB(24, 30, 46), Color3.fromRGB(16, 20, 31))

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 5, 1, -26)
	accent.Position = UDim2.new(0, 14, 0, 13)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Parent = button
	trackTheme(accent)
	corner(accent, 5)

	local gameTitle = label(button, "GameTitle", entry.name or ("Place " .. tostring(entry.placeId)), 14, colors.text, Enum.Font.GothamBold)
	gameTitle.Size = UDim2.new(1, -150, 0, 22)
	gameTitle.Position = UDim2.new(0, 32, 0, 13)

	local gameBody = label(button, "GameBody", entry.description or "Supported by Brainrot Hub.", 11, colors.muted, Enum.Font.GothamMedium)
	gameBody.Size = UDim2.new(1, -150, 0, 28)
	gameBody.Position = UDim2.new(0, 32, 0, 36)

	local join = Instance.new("TextLabel")
	join.Size = UDim2.new(0, 88, 0, 32)
	join.Position = UDim2.new(1, -104, 0.5, -16)
	join.BackgroundColor3 = accentColor
	join.BorderSizePixel = 0
	join.Font = Enum.Font.GothamBold
	join.Text = "Join"
	join.TextColor3 = Color3.fromRGB(255, 255, 255)
	join.TextSize = 12
	join.Parent = button
	corner(join, 14)
	trackTheme(join)

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = colors.surface3 }, 0.12)
		tween(join, { BackgroundColor3 = Color3.fromRGB(101, 148, 255) }, 0.12)
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = colors.surface2 }, 0.12)
		tween(join, { BackgroundColor3 = accentColor }, 0.12)
	end)

	button.MouseButton1Click:Connect(function()
		if entry.placeId then
			join.Text = "Joining..."
			if notify then
				notify("Joining game", entry.name or ("Place " .. tostring(entry.placeId)), accentColor)
			end
			local ok = pcall(function()
				if entry.jobId then
					TeleportService:TeleportToPlaceInstance(entry.placeId, entry.jobId, player)
				else
					TeleportService:Teleport(entry.placeId, player)
				end
			end)
			if not ok then
				join.Text = "Restricted"
				join.BackgroundColor3 = colors.red
				if notify then
					notify("Teleport failed", "Roblox blocked this place or server.", colors.red)
				end
				task.delay(2, function()
					if join and join.Parent then
						join.Text = "Join"
						join.BackgroundColor3 = accentColor
					end
				end)
			end
		end
	end)

	return button
end

local homePage = makePage("Home")
addVerticalLayout(homePage, 12)

local welcome = makePanel(homePage, 82)
local welcomeTitle = label(welcome, "WelcomeTitle", "Welcome back, " .. player.DisplayName, 18, colors.text, Enum.Font.GothamBold)
welcomeTitle.Size = UDim2.new(1, -28, 0, 26)
welcomeTitle.Position = UDim2.new(0, 14, 0, 13)
local welcomeBody = label(welcome, "WelcomeBody", "Thanks for using Brainrot Hub. Use the tabs to check support, updates, and game actions.", 12, colors.muted, Enum.Font.GothamMedium)
welcomeBody.Size = UDim2.new(1, -28, 0, 30)
welcomeBody.Position = UDim2.new(0, 14, 0, 42)

local profile = makePanel(homePage, 96)
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 60, 0, 60)
avatar.Position = UDim2.new(0, 16, 0, 18)
avatar.BackgroundColor3 = colors.surface3
avatar.BorderSizePixel = 0
avatar.Image = ""
avatar.Parent = profile
corner(avatar, 16)

task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then avatar.Image = image end
end)

local displayName = label(profile, "DisplayName", player.DisplayName, 17, colors.text, Enum.Font.GothamBold)
displayName.Size = UDim2.new(1, -104, 0, 24)
displayName.Position = UDim2.new(0, 92, 0, 18)
local username = label(profile, "Username", "@" .. player.Name .. "  |  UserId " .. tostring(player.UserId), 12, colors.muted, Enum.Font.GothamMedium)
username.Size = UDim2.new(1, -104, 0, 18)
username.Position = UDim2.new(0, 92, 0, 43)
local currentPlace = label(profile, "CurrentPlace", gameName .. "  |  PlaceId " .. tostring(game.PlaceId), 12, gameSupported and colors.green or colors.red, Enum.Font.GothamSemibold)
currentPlace.Size = UDim2.new(1, -104, 0, 18)
currentPlace.Position = UDim2.new(0, 92, 0, 63)

local updatesTitle = label(homePage, "UpdatesTitle", "Updates", 15, colors.text, Enum.Font.GothamBold)
updatesTitle.Size = UDim2.new(1, 0, 0, 26)

for index, update in ipairs(Updates) do
	local item = makePanel(homePage, 62)
	local marker = Instance.new("Frame")
	marker.Size = UDim2.new(0, 5, 0, 36)
	marker.Position = UDim2.new(0, 14, 0, 13)
	marker.BackgroundColor3 = index == 1 and colors.blue or (index == 2 and colors.cyan or colors.green)
	marker.BorderSizePixel = 0
	marker.Parent = item
	corner(marker, 5)

	local updateTitle = label(item, "UpdateTitle", update.title, 13, colors.text, Enum.Font.GothamBold)
	updateTitle.Size = UDim2.new(1, -44, 0, 20)
	updateTitle.Position = UDim2.new(0, 30, 0, 11)
	local updateBody = label(item, "UpdateBody", update.body, 11, colors.muted, Enum.Font.Gotham)
	updateBody.Size = UDim2.new(1, -44, 0, 24)
	updateBody.Position = UDim2.new(0, 30, 0, 31)
end

local gamesPage = makePage("Games")
addVerticalLayout(gamesPage, 12)

local supportPanel = makePanel(gamesPage, 126)
local supportTitle = label(supportPanel, "SupportTitle", gameSupported and "This game is supported" or "This game is not supported yet", 18, gameSupported and colors.green or colors.red, Enum.Font.GothamBold)
supportTitle.Size = UDim2.new(1, -170, 0, 28)
supportTitle.Position = UDim2.new(0, 16, 0, 15)
local supportBody = label(supportPanel, "SupportBody", gameSupported and ("Loaded " .. gameName .. ". The Game tab is ready.") or "Pick a supported game below to teleport there, or add this PlaceId to your configs.", 12, colors.muted, Enum.Font.GothamMedium)
supportBody.Size = UDim2.new(1, -32, 0, 34)
supportBody.Position = UDim2.new(0, 16, 0, 47)
local source = label(supportPanel, "Source", gameSupported and ("Source: " .. tostring(loadedPath or "Unknown")) or ("Expected file: " .. GAME_FOLDER .. "/" .. tostring(game.PlaceId) .. ".lua"), 11, colors.muted, Enum.Font.GothamMedium)
source.Size = UDim2.new(1, -32, 0, 20)
source.Position = UDim2.new(0, 16, 0, 86)

local statusPill = Instance.new("TextLabel")
statusPill.Size = UDim2.new(0, 126, 0, 34)
statusPill.Position = UDim2.new(1, -142, 0, 16)
statusPill.BackgroundColor3 = gameSupported and Color3.fromRGB(24, 86, 63) or Color3.fromRGB(88, 39, 55)
statusPill.BorderSizePixel = 0
statusPill.Font = Enum.Font.GothamBold
statusPill.Text = gameSupported and "READY" or "NO CONFIG"
statusPill.TextColor3 = gameSupported and Color3.fromRGB(179, 255, 223) or Color3.fromRGB(255, 177, 194)
statusPill.TextSize = 12
statusPill.Parent = supportPanel
corner(statusPill, 14)

local stats = Instance.new("Frame")
stats.Size = UDim2.new(1, 0, 0, 78)
stats.BackgroundTransparency = 1
stats.Parent = gamesPage
local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.Padding = UDim.new(0, 10)
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Parent = stats
makeInfoCard(stats, "PlaceId", tostring(game.PlaceId), colors.text).Size = UDim2.new(0.333, -7, 0, 78)
makeInfoCard(stats, "Supported Games", tostring(#supportedGames), colors.blue).Size = UDim2.new(0.333, -7, 0, 78)
makeInfoCard(stats, "Status", gameSupported and "Ready" or "Unsupported", gameSupported and colors.green or colors.yellow).Size = UDim2.new(0.333, -7, 0, 78)

local listTitle = label(gamesPage, "ListTitle", gameSupported and "Other Supported Games" or "Supported Games", 15, colors.text, Enum.Font.GothamBold)
listTitle.Size = UDim2.new(1, 0, 0, 26)

if #supportedGames == 0 then
	local empty = makePanel(gamesPage, 78)
	local emptyTitle = label(empty, "EmptyTitle", "No supported games listed yet", 14, colors.text, Enum.Font.GothamBold)
	emptyTitle.Size = UDim2.new(1, -28, 0, 22)
	emptyTitle.Position = UDim2.new(0, 14, 0, 13)
	local emptyBody = label(empty, "EmptyBody", "Add entries to SupportedGameList so unsupported users can teleport to them.", 12, colors.muted, Enum.Font.Gotham)
	emptyBody.Size = UDim2.new(1, -28, 0, 28)
	emptyBody.Position = UDim2.new(0, 14, 0, 37)
else
	for index, entry in ipairs(supportedGames) do
		makeSupportedGameButton(gamesPage, entry, index)
	end
end

if gameSupported then
	local gamePage = makePage("Game")
	addVerticalLayout(gamePage, 12)
	local headerPanel = makePanel(gamePage, 76)
	local gameHeader = label(headerPanel, "GameHeader", gameName, 18, colors.text, Enum.Font.GothamBold)
	gameHeader.Size = UDim2.new(1, -28, 0, 26)
	gameHeader.Position = UDim2.new(0, 14, 0, 13)
	local gameBody = label(headerPanel, "GameBody", "Game-specific actions for this place.", 12, colors.muted, Enum.Font.GothamMedium)
	gameBody.Size = UDim2.new(1, -28, 0, 24)
	gameBody.Position = UDim2.new(0, 14, 0, 39)

	local actions = type(gameConfig.actions) == "table" and gameConfig.actions or {}
	if #actions == 0 then
		local empty = makePanel(gamePage, 72)
		local emptyTitle = label(empty, "EmptyTitle", "No actions yet", 14, colors.text, Enum.Font.GothamBold)
		emptyTitle.Size = UDim2.new(1, -28, 0, 22)
		emptyTitle.Position = UDim2.new(0, 14, 0, 13)
		local emptyBody = label(empty, "EmptyBody", "Add actions to this game config to show controls here.", 12, colors.muted, Enum.Font.Gotham)
		emptyBody.Size = UDim2.new(1, -28, 0, 24)
		emptyBody.Position = UDim2.new(0, 14, 0, 37)
	else
		for _, action in ipairs(actions) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 68)
			button.BackgroundColor3 = colors.surface2
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.Text = ""
			button.Parent = gamePage
			corner(button, 16)
			stroke(button, colors.line, 0.45, 1)

			local actionTitle = label(button, "ActionTitle", action.title or "Game Action", 14, colors.text, Enum.Font.GothamBold)
			actionTitle.Size = UDim2.new(1, -28, 0, 22)
			actionTitle.Position = UDim2.new(0, 14, 0, 11)
			local actionBody = label(button, "ActionBody", action.description or "Run this game action.", 11, colors.muted, Enum.Font.Gotham)
			actionBody.Size = UDim2.new(1, -28, 0, 24)
			actionBody.Position = UDim2.new(0, 14, 0, 34)

			button.MouseButton1Click:Connect(function()
				if type(action.callback) == "function" then
					local ok, err = pcall(action.callback)
					if ok then
						if notify then notify("Action ran", action.title or "Game Action", colors.green) end
					else
						warn("Game action failed:", err)
						if notify then notify("Action failed", tostring(err), colors.red) end
					end
				end
			end)
		end
	end
end

local function applyAccent(newColor)
	accentColor = newColor
	colors.blue = newColor

	for _, item in ipairs(themedObjects) do
		if item.object and item.object.Parent then
			item.object[item.property] = newColor
		end
	end

	if selectedTab and tabs[selectedTab] then
		tabs[selectedTab].BackgroundColor3 = newColor
	end

	saveSettings()

	if notify then
		notify("Color updated", "Accent color changed.", newColor)
	end
end

local function applyTransparency(amount)
	transparencyAmount = amount
	for _, item in ipairs(transparentObjects) do
		if item.object and item.object.Parent then
			item.object.BackgroundTransparency = math.clamp(item.base + amount, 0, 0.82)
		end
	end

	saveSettings()

	if notify then
		notify("Transparency updated", amount > 0 and "Light transparency enabled." or "Solid UI enabled.", colors.cyan)
	end
end

local function makeSettingButton(parent, text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = colors.surface2
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamSemibold
	button.Text = text
	button.TextColor3 = colors.text
	button.TextSize = 13
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = parent
	corner(button, 14)
	stroke(button, colors.line, 0.5, 1)
	padding(button, 14, 14, 0, 0)
	trackTransparency(button, 0)

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = colors.surface3 }, 0.12)
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = colors.surface2 }, 0.12)
	end)

	button.MouseButton1Click:Connect(callback)
	return button
end

local settingsPage = makePage("Settings")
addVerticalLayout(settingsPage, 12)

local settingsIntro = makePanel(settingsPage, 86)
local settingsTitle = label(settingsIntro, "SettingsTitle", "Settings", 18, colors.text, Enum.Font.GothamBold)
settingsTitle.Size = UDim2.new(1, -28, 0, 26)
settingsTitle.Position = UDim2.new(0, 14, 0, 13)
local settingsBody = label(settingsIntro, "SettingsBody", "Change the accent color, transparency, and install an autoexec loader when your executor supports file writes.", 12, colors.muted, Enum.Font.GothamMedium)
settingsBody.Size = UDim2.new(1, -28, 0, 34)
settingsBody.Position = UDim2.new(0, 14, 0, 41)

local ownerPanel = makePanel(settingsPage, 104)
local ownerTitle = label(ownerPanel, "OwnerTitle", "Console Owner", 15, consoleOwner and colors.green or colors.red, Enum.Font.GothamBold)
ownerTitle.Size = UDim2.new(1, -28, 0, 24)
ownerTitle.Position = UDim2.new(0, 14, 0, 12)
local ownerBody = label(ownerPanel, "OwnerBody", consoleOwner and "Permissions active. Owner-only controls are unlocked." or "Permissions locked. Add your UserId or username to ConsoleOwners.", 12, colors.muted, Enum.Font.GothamMedium)
ownerBody.Size = UDim2.new(1, -28, 0, 36)
ownerBody.Position = UDim2.new(0, 14, 0, 38)
local ownerId = label(ownerPanel, "OwnerId", "User: @" .. player.Name .. "  |  UserId " .. tostring(player.UserId), 11, colors.muted, Enum.Font.GothamMedium)
ownerId.Size = UDim2.new(1, -28, 0, 18)
ownerId.Position = UDim2.new(0, 14, 0, 76)

local colorPanel = makePanel(settingsPage, 118)
local colorTitle = label(colorPanel, "ColorTitle", "UI Color", 15, colors.text, Enum.Font.GothamBold)
colorTitle.Size = UDim2.new(1, -28, 0, 24)
colorTitle.Position = UDim2.new(0, 14, 0, 12)

local colorButtons = Instance.new("Frame")
colorButtons.Size = UDim2.new(1, -28, 0, 48)
colorButtons.Position = UDim2.new(0, 14, 0, 50)
colorButtons.BackgroundTransparency = 1
colorButtons.Parent = colorPanel

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 10)
colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
colorLayout.Parent = colorButtons

local swatches = {
	{ "Blue", Color3.fromRGB(79, 126, 255) },
	{ "Pink", Color3.fromRGB(255, 93, 161) },
	{ "Green", Color3.fromRGB(74, 221, 151) },
	{ "Gold", Color3.fromRGB(242, 194, 88) },
}

for _, swatch in ipairs(swatches) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.25, -8, 0, 42)
	button.BackgroundColor3 = swatch[2]
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBold
	button.Text = swatch[1]
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Parent = colorButtons
	corner(button, 14)
	button.MouseButton1Click:Connect(function()
		applyAccent(swatch[2])
	end)
end

local transparencyPanel = makePanel(settingsPage, 166)
local transparencyTitle = label(transparencyPanel, "TransparencyTitle", "Transparency", 15, colors.text, Enum.Font.GothamBold)
transparencyTitle.Size = UDim2.new(1, -28, 0, 24)
transparencyTitle.Position = UDim2.new(0, 14, 0, 12)
local transparencyBody = label(transparencyPanel, "TransparencyBody", "Pick how see-through the menu should be.", 12, colors.muted, Enum.Font.GothamMedium)
transparencyBody.Size = UDim2.new(1, -28, 0, 22)
transparencyBody.Position = UDim2.new(0, 14, 0, 38)

local transparencyButtons = Instance.new("Frame")
transparencyButtons.Size = UDim2.new(1, -28, 0, 92)
transparencyButtons.Position = UDim2.new(0, 14, 0, 64)
transparencyButtons.BackgroundTransparency = 1
transparencyButtons.Parent = transparencyPanel

local transparencyLayout = Instance.new("UIListLayout")
transparencyLayout.Padding = UDim.new(0, 8)
transparencyLayout.SortOrder = Enum.SortOrder.LayoutOrder
transparencyLayout.Parent = transparencyButtons

makeSettingButton(transparencyButtons, "Solid", function() applyTransparency(0) end)
makeSettingButton(transparencyButtons, "Light Transparency", function() applyTransparency(0.18) end)

local autoPanel = makePanel(settingsPage, 154)
local autoTitle = label(autoPanel, "AutoTitle", "Auto Inject", 15, colors.text, Enum.Font.GothamBold)
autoTitle.Size = UDim2.new(1, -28, 0, 24)
autoTitle.Position = UDim2.new(0, 14, 0, 12)
local autoBody = label(autoPanel, "AutoBody", "Creates an autoexec loader file for executors that support writefile. This cannot bypass executor permissions.", 12, colors.muted, Enum.Font.GothamMedium)
autoBody.Size = UDim2.new(1, -28, 0, 42)
autoBody.Position = UDim2.new(0, 14, 0, 38)

local autoStatus = label(autoPanel, "AutoStatus", "Not installed", 12, colors.yellow, Enum.Font.GothamSemibold)
autoStatus.Size = UDim2.new(1, -28, 0, 22)
autoStatus.Position = UDim2.new(0, 14, 0, 82)

local installButton = makeSettingButton(autoPanel, "Install Autoexec Loader", function()
	if not consoleOwner then
		autoStatus.Text = "Console Owner permission required"
		autoStatus.TextColor3 = colors.red
		if notify then notify("Permission denied", "Console Owner is required for auto inject.", colors.red) end
		return
	end

	if type(writefile) ~= "function" then
		autoStatus.Text = "writefile is not supported by this executor"
		autoStatus.TextColor3 = colors.red
		if notify then notify("Autoexec unavailable", "This executor does not expose writefile.", colors.red) end
		return
	end

	local loader = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/Adottgt/Brainrot-Hub/main/src/init.lua"))()]]
	local paths = {
		"autoexec/BrainrotHub.lua",
		"autoexecute/BrainrotHub.lua",
		"AutoExec/BrainrotHub.lua",
		"BrainrotHub.autoexec.lua",
	}

	local installed = false
	for _, path in ipairs(paths) do
		local ok = pcall(function()
			local folder = path:match("^(.*)/[^/]+$")
			if folder then
				ensureFolder(folder)
			end
			writefile(path, loader)
		end)
		if ok then
			installed = true
			autoStatus.Text = "Installed to " .. path
			autoStatus.TextColor3 = colors.green
			if notify then notify("Autoexec installed", path, colors.green) end
			break
		end
	end

	if not installed then
		autoStatus.Text = "Could not write autoexec file"
		autoStatus.TextColor3 = colors.red
		if notify then notify("Autoexec failed", "Could not write to known autoexec paths.", colors.red) end
	end
end)
installButton.Size = UDim2.new(1, -28, 0, 42)
installButton.Position = UDim2.new(0, 14, 0, 104)
installButton.Parent = autoPanel

local ownerTools = makePanel(settingsPage, 120)
local ownerToolsTitle = label(ownerTools, "OwnerToolsTitle", "Owner Tools", 15, colors.text, Enum.Font.GothamBold)
ownerToolsTitle.Size = UDim2.new(1, -28, 0, 24)
ownerToolsTitle.Position = UDim2.new(0, 14, 0, 12)
local ownerToolsBody = label(ownerTools, "OwnerToolsBody", consoleOwner and "Copy useful debug info for configs and support checks." or "Locked until Console Owner permission is active.", 12, colors.muted, Enum.Font.GothamMedium)
ownerToolsBody.Size = UDim2.new(1, -28, 0, 34)
ownerToolsBody.Position = UDim2.new(0, 14, 0, 38)

local copyDebug = makeSettingButton(ownerTools, "Copy Debug Info", function()
	if not consoleOwner then
		if notify then notify("Permission denied", "Console Owner is required.", colors.red) end
		return
	end

	local debugText = "PlaceId: " .. tostring(game.PlaceId) .. "\nJobId: " .. tostring(game.JobId) .. "\nGame: " .. tostring(gameName)
	if type(setclipboard) == "function" then
		setclipboard(debugText)
		if notify then notify("Copied debug info", "PlaceId and JobId copied.", colors.green) end
	else
		print(debugText)
		if notify then notify("Printed debug info", "setclipboard is unavailable.", colors.yellow) end
	end
end)
copyDebug.Size = UDim2.new(1, -28, 0, 42)
copyDebug.Position = UDim2.new(0, 14, 0, 70)
copyDebug.Parent = ownerTools

makeTab("Home", 1)
makeTab("Games", 2)
makeTab("Settings", 3)
if gameSupported then
	makeTab("Game", 4)
end
applyAccent(accentColor)
applyTransparency(transparencyAmount)
selectTab("Home")

local toast = Instance.new("Frame")
toast.Name = "WelcomeToast"
toast.Size = UDim2.new(0, 280, 0, 56)
toast.Position = UDim2.new(1, -312, 1, 16)
toast.BackgroundColor3 = colors.surface2
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Parent = main
corner(toast, 16)
stroke(toast, colors.line, 1, 1)

local toastTitle = label(toast, "ToastTitle", "Welcome to Brainrot Hub", 13, colors.text, Enum.Font.GothamBold)
toastTitle.Size = UDim2.new(1, -24, 0, 20)
toastTitle.Position = UDim2.new(0, 12, 0, 8)
toastTitle.TextTransparency = 1
local toastBody = label(toast, "ToastBody", "Thanks for using the script.", 11, colors.muted, Enum.Font.GothamMedium)
toastBody.Size = UDim2.new(1, -24, 0, 18)
toastBody.Position = UDim2.new(0, 12, 0, 30)
toastBody.TextTransparency = 1

local uiOpen = true
local shownPosition = main.Position
local hiddenPosition = UDim2.new(shownPosition.X.Scale, shownPosition.X.Offset, shownPosition.Y.Scale, shownPosition.Y.Offset + 22)
local toastBusy = false

notify = function(titleText, bodyText, toneColor)
	if toastBusy then
		toast.Position = UDim2.new(1, -312, 1, 16)
	end

	toastBusy = true
	toastTitle.Text = titleText or "Brainrot Hub"
	toastBody.Text = bodyText or ""
	toastTitle.TextColor3 = toneColor or colors.text
	tween(toast, { Position = UDim2.new(1, -312, 1, -74), BackgroundTransparency = 0 }, 0.25)
	tween(toastTitle, { TextTransparency = 0 }, 0.18)
	tween(toastBody, { TextTransparency = 0 }, 0.18)
	task.delay(3, function()
		if toast and toast.Parent then
			tween(toast, { Position = UDim2.new(1, -312, 1, 16), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			tween(toastTitle, { TextTransparency = 1 }, 0.16)
			tween(toastBody, { TextTransparency = 1 }, 0.16)
			task.delay(0.22, function()
				toastBusy = false
			end)
		end
	end)
end

local function showUi()
	screenGui.Enabled = true
	uiOpen = true
	main.Position = hiddenPosition
	main.BackgroundTransparency = 1
	scale.Scale = 0.985
	tween(main, { Position = shownPosition, BackgroundTransparency = 0 }, 0.2)
	tween(scale, { Scale = 1 }, 0.2)
end

local function hideUi()
	uiOpen = false
	tween(main, { Position = hiddenPosition, BackgroundTransparency = 1 }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	tween(scale, { Scale = 0.985 }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	task.delay(0.17, function()
		if not uiOpen then screenGui.Enabled = false end
	end)
end

showUi()
task.delay(0.4, function()
	notify("Welcome to Brainrot Hub", consoleOwner and "Console Owner permissions active." or "Thanks for using the script.", consoleOwner and colors.green or colors.text)
end)

local dragging = false
local dragStart
local mainStart

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + delta.X, mainStart.Y.Scale, mainStart.Y.Offset + delta.Y)
	shownPosition = main.Position
	hiddenPosition = UDim2.new(shownPosition.X.Scale, shownPosition.X.Offset, shownPosition.Y.Scale, shownPosition.Y.Offset + 22)
end

header.InputBegan:Connect(function(input)
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
