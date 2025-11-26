--- A controller component that stops to wait for input to receive its action.
--- @class WaitController : Controller
--- @overload fun(): WaitController
--- @type WaitController
local WaitController = prism.components.Controller:extend "WaitController"

function WaitController:decide(level, owner, decision)
   return level:yield(prism.actions.Wait(owner))
end

return WaitController
