return spectrum.Input.Controls {
   -- stylua: ignore
   controls = {
      -- Controls can be mapped to keys, text, gamepad buttons, joystick axes, or mouse presses.
      -- Prefix the control with the type, e.g. "axis:lefty-", "mouse:1", "button:rightshoulder", "text:>".
      -- If no prefix is given, the control is assumed to be a key.
      -- Controls can also be combinations of inputs, e.g. "lshift a" or "lctrl s".
      -- See the LÖVE wiki for all of the constants.
      move_upleft    = { "q", "y" },
      move_up        = { "w", "k", "axis:lefty+" },
      move_upright   = { "e", "u" },
      move_left      = { "a", "h", "axis:leftx-" },
      move_right     = { "d", "l", "axis:leftx+" },
      move_downleft  = { "z", "b" },
      move_down      = { "s", "j", "axis:lefty-" },
      move_downright = { "c", "n" },

      -- dash_upleft    = { "lshift q", "rshift q" },
      -- dash_up        = { "lshift w", "rshift w" },
      -- dash_upright   = { "lshift e", "rshift e" },
      -- dash_left      = { "lshift a", "rshift a" },
      -- dash_right     = { "lshift d", "rshift d" },
      -- dash_downleft  = { "lshift z", "rshift z" },
      -- dash_down      = { "lshift s", "rshift s" },
      -- dash_downright = { "lshift c", "rshift c" },

      dash_mode      = { "lshift", "rshift" },

      wait           = "x",
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

      -- dash = {
      --    "dash_upleft", "dash_up", "dash_upright",
      --    "dash_left", "dash_right",
      --    "dash_downleft", "dash_down", "dash_downright"
      -- }
   },
}
