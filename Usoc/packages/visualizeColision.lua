local function colisionPart(color: Color3, location: CFrame, size: Vector3)
   local part = Instance.new("Part")
   part.Material = Enum.Material.SmoothPlastic
   part.Anchored = true
   part.CanQuery = false
   part.CanCollide = false
   part.CanTouch = false
   part.Size = size
   part.CFrame = location
   part.Color = color
   part.Transparency = .75

   part.Parent = workspace
   task.delay(.1, part.Destroy, part)
end

return function(location: CFrame, size: Vector3, color: Color3)
   local visualizeColor = color or Color3.fromRGB(255, 0, 0)
   
   colisionPart(visualizeColor, location, size)
end