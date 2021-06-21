local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()


local remotesFolder; 

if isServer then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
else
	remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
end


local handler = {}

function fireEvent(topic, ...)
	local event = remotesFolder:FindFirstChild(topic.."Event")
	assert(event, "Event for '" .. topic .. "'" .. " does not exist")

	local args = table.pack(...)

	if isServer then
		local player = args[1]
		event:FireClient(player, table.unpack(args, 2))
	else
		event:FireServer(table.unpack(args))
	end
end

function handler.runEvent(topic, ...)
	return fireEvent(topic, ...)
end

function handler.runEventForClients(topic, clients, ...)
	if not isServer then return end

	for _, client in pairs(clients)do
		fireEvent(topic, client, ...)
	end
end

function handler.connectEvent(topic, funct) 
	local event = remotesFolder:FindFirstChild(topic)

	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = topic.."Event"
		event.Parent = remotesFolder
	end

	if isServer then
		event.OnServerEvent:Connect(funct)
	else
		event.OnClientEvent:Connect(funct)
	end
end
----------------------------------------------------------------------

function fireFunct(topic, ...)
	local remoteFunction = remotesFolder:FindFirstChild(topic.."Function")
	assert(remoteFunction, "Remote Function for '" .. topic .. "'" .. " does not exist")

	local args = table.pack(...)

	if isServer then
		local player = args[1]

		warn(
			"You are invoking the client with the topic " .. topic .. 
				"Hackers can delete the localscript that this connects to, idling your server code forever."..
				"Consider refactoring"
		)

		return remoteFunction:InvokeClient(player, table.unpack(args, 2))
	else
		return remoteFunction:InvokeServer(table.unpack(args))
	end
end

function handler.runFunct(topic, ...)
	return fireFunct(topic, ...)
end

--function handler.runFunctForClients(topic, clients, ...)
--	if not isServer then return end

--	for _, client in pairs(clients)do
--		return fireFunct(topic, client, ...)
--	end
--end

function handler.connectFunct(topic, funct)
	local event = remotesFolder:FindFirstChild(topic)

	if not event then
		event = Instance.new("RemoteFunction")
		event.Name = topic.."Remote"
		event.Parent = remotesFolder
	end

	if isServer then
		event.OnServerInvoke = funct
	else
		event.OnClientInvoke = funct
	end
end

return handler
