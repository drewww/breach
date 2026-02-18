-- Check if we're running in a web environment
local isWeb = love.system.getOS() == "Web"

local defaults = spectrum.Input.Controls {
   -- stylua: ignore
   controls = {
      -- Controls can be mapped to keys, text, gamepad buttons, joystick axes, or mouse presses.
      -- Prefix the control with the type, e.g. "axis:lefty-", "mouse:1", "button:rightshoulder", "text:>".
      -- If no prefix is given, the control is assumed to be a key.
      -- Controls can also be combinations of inputs, e.g. "lshift a" or "lctrl s".
      -- See the LÖVE wiki for all of the constants.
      move_upleft    = { "q", "y" },
      move_up        = { "w", "k" },
      move_upright   = { "e", "u" },
      move_left      = { "a", "h" },
      move_right     = { "d", "l" },
      move_downleft  = { "z", "b" },
      move_down      = { "s", "j" },
      move_downright = { "c", "n" },

      use            = { "mouse:1" },
      cycle          = { "tab" },
      reload         = { "r" },

      dash_mode      = { "lshift", "rshift" },

      wait           = "x",

      dismiss        = { "space", "return" }
   },
   -- Pairs are controls that map to either 4 or 8 directions.
   -- With only 4 directions, the order is up, left, right, down.
   pairs = {
      -- stylua: ignore
      move = {
         "move_upleft", "move_up", "move_upright",
         "move_left", "move_right",
         "move_downleft", "move_down", "move_downright"
      },
   },
}

-- Skip file I/O in web builds
if not isWeb then
   local saveContents = love.filesystem.read("controls.json")
   if saveContents then
      --- @type ControlsOptions
      local config = prism.json.decode(saveContents)

      -- Update saved controls with any newly added inputs
      for name, control in pairs(defaults:getConfig().controls) do
         if not config.controls[name] then config.controls[name] = control end
      end

      for name, control in pairs(defaults:getConfig().pairs) do
         if not config.pairs[name] then config.pairs[name] = control end
      end

      local controls = spectrum.Input.Controls(config)
      love.filesystem.write("controls.json", prism.json.encode(config))

      -- Add save method to controls object
      function controls:save()
         if not isWeb then
            love.filesystem.write("controls.json", prism.json.encode(self._config))
         end
      end

      return controls
   end

   love.filesystem.write("controls.json", prism.json.encode(defaults:getConfig()))
end

-- Add save method to defaults as well
function defaults:save()
   if not isWeb then
      love.filesystem.write("controls.json", prism.json.encode(self._config))
   end
end

return defaults
