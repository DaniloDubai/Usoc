local RunService = game:GetService("RunService")
--[[
   Usoc - Unique System Of Colision
   What is? Is a colision wrapper for overlap system
]]

local packages = script.packages
local signals = require(packages.signals)
local visualizeColision = require(packages.visualizeColision)

local function isVectorState(target: any)
   local _type = typeof(target)

   if _type == "table" then
      local _validType = target._type == "VectorState"
      local _flag = if _validType then "VectorState" else nil

      return _validType, _flag
   elseif _type == "Vector3" then
      return true, "Vector3"
   else
      return nil
   end
end

type array<v> = {[number]: v}
local function getFilteredParts(partList: array<BasePart>, breakOnFindHumanoid: boolean): Humanoid | array<Humanoid>
   local HumanoidList = {}
   for _, part in partList do
      local Character = part:FindFirstAncestorWhichIsA("Model")
      if Character  then
         local Humanoid = Character:FindFirstChildOfClass("Humanoid", true)
         
         if Humanoid then
            if breakOnFindHumanoid then return Humanoid end
            HumanoidList[Character.Name] = Humanoid
         end
      end
   end

   if not HumanoidList[1] then
      HumanoidList = nil
   end

   return HumanoidList
end

local Usoc do
   Usoc = {}

   --[=[
      use vectorState to resize your hitbox

      @param initialValue: Vector3? if not definied then result on Vector3.zero
      ```lua   
         --setting the base size of hitbox
         local UsocObject = Usoc.new(Usoc.vectorState():set(Vector3.new(1,1,1)))

         UsocObject:Start(function()
            return HumanoidRootPart.CFrame
         end, Animation.Length)
      ```
   ]=]
   function Usoc.vectorState(initialValue: Vector3?)
      initialValue = initialValue or Vector3.zero
      local vector = {}
      vector._value = initialValue
      vector._type = "VectorState"

      function vector:set(value: Vector3)
         assert(typeof(value) == "Vector3", `expected Vector3 got {value}`)
         self._value = value
         return self
      end

      function vector:get()
         return self._value
      end

      function vector:_destroy()
         table.clear(self)
      end

      return vector
   end

   --[=[
      Creates an new object of colision
   ]=]
   function Usoc.new(HitBoxSize: Vector3)
      local _typeof, _flag = isVectorState(HitBoxSize)
      assert(_typeof, `Vector3 expected got {typeof(HitBoxSize)}`)
      
      local ColisionObject = {}

      --//private
      ColisionObject._runningConnection = nil :: RBXScriptConnection?
      ColisionObject._realType = _flag :: string

      --//public
      ColisionObject.Hitted = signals.new("HitboxColision") :: signals.signal & {connect: (_: any, HitResult)->()}
      ColisionObject.OverlapParams = nil :: OverlapParams
      ColisionObject.ResultMode = "Filter" :: "Filter"|"Raw"
      ColisionObject.BreakOnFindHumanoid = true

      --[[
         #NODE
         In raw mode your receive all parts the hitbox is hitted.
         BreakOnFindHumanoid, you gonna receive all Humanoid hitteds in Overlap
      ]]

      ColisionObject.Visible = false
      ColisionObject.StopWhenHit = true

      --[=[
         Start your colision object

         Example:
         ```lua
         Usoc:Start(function()
            return HumanoidRootPart.CFrame
         end, PunchAnimation.Length)

         Usoc.Hitted:connect(warn)
         ```
      ]=]
      function ColisionObject:Start(updateCallback:()->CFrame, duration: number)
         assert(typeof(updateCallback) == "function", `function as expected got {typeof(updateCallback)}`)
         assert(self.OverlapParams, `OverlapParams is not definied, set like: UsocObject.OverlapParams = OverlapParams`)
         assert(self._realType, `invalid argument received on hitbox member?`)
         
         if duration then
            assert(typeof(duration) == "number", `number expected got {typeof(duration)}`)
         end

         local _start = if duration then os.clock() else nil
         
         if self._runningConnection then
            self:Stop()
         end

         self._runningConnection = RunService.RenderStepped:Connect(function()
            if _start then
               if (os.clock() - _start) >= duration then
                  print("reached time")
                  self:Stop()
                  return
               end
            end

            local _location = updateCallback()
            local _size = if self._realType == "Vector3" then HitBoxSize else HitBoxSize:get()

            local result = workspace:GetPartBoundsInBox(_location, _size, self.OverlapParams)
            
            if result then
               if self.StopWhenHit and self.ResultMode == "Raw" then
                  self.Hitted:fire(unpack(result))
                  self:Stop()
                  warn("stoped")
                  if self.Visible then visualizeColision(_location, _size, Color3.new(0,1,0)) end
                  return
               end
               
               local filteredParts = getFilteredParts(result, self.BreakOnFindHumanoid)
               local _filteredPartType = typeof(filteredParts)

               if self.Visible and _filteredPartType == "table" then 
                  if filteredParts[1] then 
                     visualizeColision(_location, _size, Color3.new(0,1,0)) 
                  else 
                     visualizeColision(_location,_size) 
                  end
               elseif self.Visible and _filteredPartType == "nil" then
                  visualizeColision(_location, _size)
               elseif self.Visible and _filteredPartType == "Instance" then
                  visualizeColision(_location, _size, Color3.new(0,1,0))
               end
               
               if not filteredParts then
                  return 
               end
               if self.StopWhenHit and self.BreakOnFindHumanoid then
                  print("humanoid finded")
                  self.Hitted:fire(filteredParts, filteredParts.Parent)
                  self:Stop()
               elseif self.StopWhenHit and not self.BreakOnFindHumanoid then
                  print("stopped")
                  self.Hitted:fire(filteredParts)
                  self:Stop()
               else
                  self.Hitted:fire(filteredParts)
               end            
            end
         end)
      end

      function ColisionObject:Stop()
         if self._runningConnection.Connected then
            self._runningConnection:Disconnect()
         else
            warn("not running")
         end
      end

      function ColisionObject:ConnectStopToRobloxEvent(event: RBXScriptSignal)
         assert(typeof(event) == "RBXScriptSignal", `signal expected`)

         event:Once(function()
            self:Stop()
         end)
      end

      return ColisionObject
   end
end

type HitResult = (Humanoid: Humanoid|array<Humanoid>, Character: Model) -> ()

return Usoc