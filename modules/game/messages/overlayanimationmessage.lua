-- A trivial extension of AnimationMessage

--- @class OverlayAnimationMessage : AnimationMessage
--- @overload fun(options: AnimationMessageOptions): OverlayAnimationMessage
local OverlayAnimationMessage = prism.messages.AnimationMessage:extend "OverlayAnimationMessage"

return OverlayAnimationMessage
