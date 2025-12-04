-- A trivial extension of AnimationMessage

--- @class OverlayAnimationMessage : AnimationMessage
--- @field camera boolean if true, use the display's camera offset to shift the animation.
--- @overload fun(options: AnimationMessageOptions): OverlayAnimationMessage
local OverlayAnimationMessage = prism.messages.AnimationMessage:extend "OverlayAnimationMessage"

return OverlayAnimationMessage
