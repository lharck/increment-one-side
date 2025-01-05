local module = {}

local playerDataAddedListeners = {}
local onChangeBindings = {}

local IS_SERVER = game:GetService("RunService"):IsServer()
local getDataRemote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerData"):WaitForChild("getData")
local valueChangedRemote = game.ReplicatedStorage.Remotes.PlayerData:WaitForChild("valueChanged")
local playerDataAddedRemote = game.ReplicatedStorage.Remotes.PlayerData:WaitForChild("playerDataAdded")
--[[
	addPlayerData(player, profile): Adds player data to the system
	getValue(player, path): Gets a value from the player data
	setValue(player, path, newValue): Sets a value in the player data
	playerDataAdded(player): Fired when player data is added
	playerDataAdded(player, callback): Connects a function to player data being added
	onChange(player, path, callback): Connects a function to a specific value in player data being changed
]]

if IS_SERVER then
	module.temp = {}
	module.allPlayerData = {}

	getDataRemote.OnServerInvoke = function(player, path, getTemp)
		if getTemp then
			return module.temp[player]
		end

		return module.getValue(player, path)
	end
else
	module.DataLoaded = false
	
	playerDataAddedRemote.OnClientEvent:Connect(function()
		module.DataLoaded = true

		for _, callback in pairs(playerDataAddedListeners) do
			callback(game.Players.LocalPlayer)
		end
	end)
	
	valueChangedRemote.OnClientEvent:Connect(function(path, oldValue, newValue)
		onChangeBindings[game.Players.LocalPlayer..path](oldValue, newValue)
	end)
end

function module.removePlayerData(player)
	if not IS_SERVER then return end
	
	module.allPlayerData[player] = nil	
	module.temp[player] = nil
end

function module.addPlayerData(player, profile)
	if not IS_SERVER then return end

	if module.allPlayerData[player] then error("Player already has data table") end
	module.allPlayerData[player] = profile.Data
	module.temp[player] = {
		PlayerState = "Idle";
	}
	
	for _, callback in pairs(playerDataAddedListeners) do
		callback(player)
	end
	
	playerDataAddedRemote:FireClient(player)
end

function module.getValue(player, path)
	if not IS_SERVER then 
		return getDataRemote:InvokeServer(path)
	end

	local endPath, key = resolvePath(player, path)
	
	return endPath[key]
end

function module.setValue(player, path, newValue)
	if not IS_SERVER then return end

	local endPath, key = resolvePath(player, path)
	local callback = onChangeBindings[player.UserId .. path]
	
	if typeof(endPath[key]) == "table" then 
		error("Cannot use setValue on a table.\nUse getTable() and then call childAdded() or childRemoved() respectfully")
	end
	
	local oldValue = endPath[key]
	endPath[key] = newValue
	
	if callback then
		valueChangedRemote:FireClient(player, path, oldValue, newValue)
		callback(oldValue, newValue)
	end
end


function module.onChanged(player, path, callback)
	onChangeBindings[player.UserId .. path] = callback
end

function module.onPlayerDataLoaded(callback)
	if IS_SERVER then
		--TODO: what should we do if this function is bound and a players data has already been loaded
		table.insert(playerDataAddedListeners, callback)
	else
		if module.DataLoaded then
			callback(game.Players.LocalPlayer) 
		end
	end
end

function module.DebugPrintPlayersData(player)
	if not IS_SERVER then warn("can only be used on server") return end
	if not module.allPlayerData[player] then warn("no data for " .. player.Name) end 

	warn("data for: ", player.Name)
	warn("datastore data", module.allPlayerData[player])
	warn("temp data", module.temp[player])
end

--------------------------------------------------------------------------------

function resolvePath(player, path)
	local pathParts = path:split(".")
	local desiredChange = pathParts[#pathParts]

	local currPath = module.allPlayerData[player]

	for i = 1, #pathParts-1 do
		currPath = currPath[pathParts[i]]
		if currPath == nil then 
			warn("path does not exist: ", path)
			return nil, nil
		end
	end

	return currPath, pathParts[#pathParts]
end


return module
