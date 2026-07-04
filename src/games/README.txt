Game-specific files should be named with the Roblox PlaceId.

Example:
123456789.lua

The script looks for files at:
fuckass-script/games/<PlaceId>.lua

Each file should return a table like:

return {
	name = "Game Name",
	actions = {
		{
			title = "Action Name",
			description = "What it does.",
			callback = function()
				print("Run action code here")
			end,
		},
	},
}

If your executor reads files from its workspace folder, put the games folder there as:
fuckass-script/games/
