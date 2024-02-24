
local signals, mt, cache do
   signals = {}

   mt = {}
   mt.__index = mt
   mt.__newindex = function(self, index: string, value: any?)
      if index == "cached" then
         if value :: boolean then
            cache[self] = value
         else
            table.remove(cache, table.find(cache, self))
         end
      end

      rawset(self, index, value)
   end

   cache = setmetatable({}, {__mode = "k"})

   --[=[
      @param name: string,
      @return signal
   ]=]
   function signals.new<data...>(name: string)
      assert(type(name) == "string", `name expected as string!`)
   
      local signal = {}

      --private
      signal._connections = setmetatable({}, {__mode = "k"})
      signal._event = Instance.new("BindableEvent")
      signal._event.Name = name
      signal._status = "running"

      --public
      signal.cached = false -- is stored in an cache?
      
      --[=[
         connects signal on function

         example
         ```lua
            local signal = signals.new("any-name")
            signal.cached = true
            
            local function anyCallback(...: any)
               print(...)
            end

            local connection = signal:connect(anyCallback)
            signal:await()
            connection.remove(true --[[ignoreAlert<boolean>]])
         ```
      ]=]
      function signal:connect(callback: callback<any?, nil>): RBXScriptConnection
         assert(type(callback) == "function", `function as expected got {typeof(callback)}`)
         local rbxEventConnection = self._event.Event:Connect(callback)
         local connection = {}
         
         function connection.remove(ignoreAlert: boolean)
            if rbxEventConnection.Connected then
               rbxEventConnection:Disconnect()
               self._connections[connection] = nil
               return true
            end
            if not ignoreAlert then
               warn(`connection is not connected on nothing.`)
            end

            return false
         end

         return connection :: connection
      end

      --[=[
         after destroying there is no way to recover
      ]=]
      function signal:destroy()
         assert(self._status == "running", `signal status is now {self._status}`)

         self._status = "destroyed"
         
         for _, connection: connection in self._connections do
            connection.remove(true)
         end

         self._event:Destroy()
         setmetatable(self, nil)
      end

      --[=[
         fires the signal
      ]=]
      function signal:fire(...: any)
         assert(self._status == "running", `signal status is now {self._status}`)

         self._event:Fire(...)
      end

      --[=[
         awaits for signal begin fired
      ]=]
      function signal:await()
         assert(self._status == "running", `signal status is now {self._status}`)

         return self._event.Event:Wait()
      end

      --case user destroy signal manualy
      signal._event.Destroying:Once(function()
         if signal._status == "destroyed" then return end
      end)

      setmetatable(signal, mt)
      return signal :: typeof(signal)
   end

   signals.cache = cache
end
type sucess = boolean
type callback<A, B> = (A...)->B...
type connection ={
   remove: (ignoreAlert: boolean) -> sucess,
}
export type signal = typeof(signals.new())

return signals