--- A controller component that stops to wait for input to receive its action.
--- @class WaitController : Controller
--- @overload fun(): WaitController
--- @type WaitController
local WaitController = prism.components.Controller:extend "WaitController"

function WaitController:act(level, actor)
   return prism.actions.Wait(actor)
end

return WaitController
