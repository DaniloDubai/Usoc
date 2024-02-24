# Usoc
Usoc- Unique System Of Collision is a roblox overlap wrapper multifunctional.

#Pratical Example

```lua
  local UsocModule = require(ReplicatedStorage.Usoc)

  local HitBoxSize = Vector3.new(2,2,2) -- you can use vectorstate, which creates a vector state for you that updates as set()
  local HitBoxSizeState = UsocModule.vectorState():set(Vector3.new(4,4,4))
  
  local Usoc = UsocModule.new(HitBoxSize or HitBoxSizeState) -- both are valid
  Usoc.OverlapParams = OverlapParams.new()
  Usoc.OverlapParams.FilterDescendantsInstances = {Character}

  Usoc.StopWhenHit = true -- Stop the colision object when hit in something
  Usoc.BreakOnFindHumanoid = true -- Breaks the colision on find the first humanoid on colision, if false then gonna return a list of humanoids hitteds on hitbox.
  Usoc.ResultMode = "Filter" -- On Filter mode Hitted signal only got receive Humanoid(s), on Raw mode they gonna receive everything hitted in hitbox.

  Usoc:Start(function()
    return Character.PrimaryPart.CFrame -- first argument of Start is a callback whos return the actual CFrame position
  end, 1) -- the seccond argument is the hitbox duration, can be an animation.length

  Usoc:Stop() -- force to stop the UsocObject colision
  Usoc:ConnectStopToRobloxEvent(Event: RBXScriptSignal) -- connects the stop to any roblox event, *example below*
  
  Usoc.hitted:connect(function(Humanoid: Humanoid|HumanoidList, Character: Model?)
      --hitted can receive much things, depends on the configuration do you want
      Humanoid:TakeDamage(10)
  end)
```


# Fire ball example

*https://gyazo.com/1ff433a90b86db899e182d3ad2312e1f*

```lua
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Usoc = require(ReplicatedStorage.Usoc)

local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local Mouse = Players.LocalPlayer:GetMouse()

local fireBallSpawned = nil

local function fireBall()
   local ball = Instance.new("Part")
   ball.CanCollide = false
   ball.CanQuery = false
   ball.CanTouch = false
   ball.Size = Vector3.new(3,3,3)
   ball.Material = Enum.Material.Neon
   ball.BrickColor = BrickColor.new("Neon orange")
   ball.Shape = Enum.PartType.Ball
   ball.CFrame = CFrame.lookAt(
      Character.PrimaryPart.Position,
      Mouse.Hit.Position
   )

   local bv = Instance.new("BodyVelocity", ball)
   bv.P = 100000
   bv.MaxForce = Vector3.new(10e5, 10e5, 10e5)
   bv.Velocity = ball.CFrame.LookVector * 150

   Debris:AddItem(ball, 4.5)
   
   ball.Parent = workspace
   return ball
end

local function updateCFrame()
   return fireBallSpawned.CFrame
end

local UsocObject = Usoc.new(Usoc.vectorState(Vector3.new(4,4,4)))
UsocObject.Visible = true
UsocObject.OverlapParams = OverlapParams.new()
UsocObject.OverlapParams.FilterDescendantsInstances = {Character}

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
   if gameProcessedEvent then return end

   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      fireBallSpawned = fireBall()
      UsocObject:ConnectStopToRobloxEvent(fireBallSpawned.Destroying)
      UsocObject:Start(updateCFrame)
   end
end)

UsocObject.Hitted:connect(function(Humanoid, Character)
   Humanoid:TakeDamage(15)
   if fireBallSpawned then fireBallSpawned:Destroy() end
end)
```
