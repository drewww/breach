--- @diagnostic disable-next-line
function love.conf(t)
   t.window.vsync = 0 -- Enable vsync (1 by default)
   t.window.width = 960
   t.window.height = 650
   t.window.usedpiscale = false
   t.window.title = "breach"
   -- Other configurations...
end
