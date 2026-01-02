--- @class Dialog : Component
--- @field messages Queue
local Dialog = prism.Component:extend("Dialog")
Dialog.name = "Dialog"

function Dialog:__new()
   self.messages = prism.Queue()
end

---@param string string
function Dialog:push(string)
   -- TODO more elaborate dialog item including a character potrait, name, time(?), formatting instructions, etc.
   self.messages:push(string)
end

---@return string
function Dialog:peek()
   return self.messages:peek()
end

---@return string
function Dialog:pop()
   return self.messages:pop()
end

---@return integer
function Dialog:size()
   return self.messages:size()
end

function Dialog:clear()
   self.messages:clear()
end

return Dialog
