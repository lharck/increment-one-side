local part = workspace.Part
local increment = 1
for i = 1, 100 do
	part.Position = part.Position + Vector3.new(0,0,increment/2)
	part.Size = part.Size + Vector3.new(0,0,increment)
	wait()
end
