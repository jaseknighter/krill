--- lorenz attractor
-- sam wolk 2019.10.13
-- in1 resets the attractor to the {x,y,z} coordinates stored in the lorenz.origin table
-- in2 controls the speed of the attractor
-- out1 is the x-coordinate (by default)
-- out2 is the y-coordinate (by default)
-- out3 is the z-coordinate (by default)
-- out4 is a weighted sum of x and y (by default)
-- the lorenz.weigths table allows you to specify the weight of each axis for each output.

--------------------------------
-- pixels
--------------------------------
pixels = {}
pixels.active = nil

function pixels.update(display)
  local lb = lorenz.get_boundary()
  -- print(#pixels)
  for i=1,#pixels,1 do
    pixels[i]:update(display)
  end
  for i=1,#pixels,1 do
    if pixels[i] and pixels[i].remove == true then
      -- print("remove"..i)
      if (pixels[i].last_x>lb[1] and pixels[i].last_x<lb[1]+lb[3] and pixels[i].last_y>lb[2] and pixels[i].last_y<lb[2]+lb[4]) then
        local x = math.floor(pixels[i].last_x)
        local y = math.floor(pixels[i].last_y)
        if (x and y) then
          screen.poke(x-1,y-1,2,2,blank_pixel)
        end
        table.remove(pixels,i)
      end
    elseif pixels[i] and pixels[i].remove == false then
      local lb = lorenz.get_boundary()
      if (pixels[i].last_x>lb[1] and pixels[i].last_x<lb[1]+lb[3] and pixels[i].last_y>lb[2] and pixels[i].last_y<lb[2]+lb[4]) then
        pixels.active = i
      end
    end
  end
end

local pixel = {}
pixel.__index = pixel

function pixel:new(x,y)
  local p={}
  setmetatable(p, pixel)

  p.x = x
  p.y = y
  p.x_display = x
  p.y_display = y

  p.last_x = x
  p.last_y = y
  p.timer = 1
  p.level = 15
  p.remove = false
  p.redraw = true
  
  return p
end 

function pixel:update(display)
  self.timer = self.timer + 1
  if self.timer == SCREEN_REFRESH_DENOMINATOR then
    self.level = self.level - 1
    self.timer = 1
    self.redraw = true
  end
  if self.level <= 0 then
    self.remove = true  
  elseif self.level > 0 and self.redraw == true then
    local lb = lorenz.get_boundary()
    if display == true then
      if (self.last_x>lb[1] and self.last_x<lb[1]+lb[3] and self.last_y>lb[2] and self.last_y<lb[2]+lb[4]) then
        -- screen.level(0)
        -- screen.pixel(self.last_x,self.last_y)
        -- screen.stroke()
      end
    end

    local x_offset = params:get("x_offset")
    local y_offset = params:get("y_offset")
    local x_scale = params:get("x_scale")
    local y_scale = params:get("y_scale")

    
    self.x_display = ((self.x*x_scale)+x_offset)+(CENTER_X)
    self.y_display = ((self.y*y_scale)+y_offset)+(CENTER_Y)
    local x = self.x_display
    local y = self.y_display
    if (x>lb[1] and x<lb[1]+lb[3] and y>lb[2] and y<lb[2]+lb[4]) then
      -- if (x>lb[1] and x<lb[1]+lb[3] and y>lb[2] and y<lb[2]+lb[4]) then
      self.last_x = x
      self.last_y = y
      if display == true then
        screen.level(self.level)
        screen.pixel(x,y)
        screen.stroke()
      end
    end
    self.redraw = false
  end
end

--------------------------------
-- lorenz 
--------------------------------

lorenz = {
  origin = {0.01,0.5,0},
  sigma = 2.333,
  -- sigma = 10,
  rho = 28,
  beta = 4/3,
  -- beta = 3/2,
  -- beta = 8/3,
  state = {0.01,0,0},
  steps = 1,
  -- keep td < 0.05l
  dt = 0.015,
  -- dt = 0.001,
  first = 0,
  second = 0,
  third = 0,
  x_map = 0,
  y_map = 0,
  boundary = {51,5,104,55}
  -- boundary = {51,5,74,55}
}

function lorenz.init()
  lorenz.x_map = lorenz.first
  lorenz.y_map = lorenz.second
end

-- lorenz.weigths = {{1,0,0}, {0,1,0}, {0,0,1}, {0.33,0.33,0}}
lorenz.weigths = {{1,0,0}, {0,1,0}, {0,0,1}, {2.0,1.0,1.0}}

function lorenz:process(steps,dt)
  steps = steps or self.steps
  dt = dt or self.dt
  for i=1,steps do
    local dx = self.sigma*(self.state[2]-self.state[1])
    local dy = self.state[1]*(self.rho-self.state[3])-self.state[2]
    local dz = self.state[1]*self.state[2]-self.beta*self.state[3]
    self.state[1] = self.state[1]+dx*dt
    self.state[2] = self.state[2]+dy*dt
    self.state[3] = self.state[3]+dz*dt
  end
end

function lorenz.get_boundary()
  
  local rows = #sound_controller.sectors
  local cols = #sound_controller.sectors[rows]
  local x = lorenz.boundary[1]
  local y = lorenz.boundary[2]
  local w = sound_controller.sectors[1][1].w*cols
  local h = sound_controller.sectors[1][1].h*rows
  local boundary = {x,y,w-2,h-2}
  return boundary
end

function lorenz:reset()
  for i=1,#pixels,1 do pixels[i] = nil end
  screen:clear()
  -- for i=1,3 do self.state[i] = self.origin[i] end
end

lorenz.display = function(display)
  -- screen.move(42,1)
  pixels.update(display) 
end

lorenz.update = function()
  local xyz = {}
  for i=1,4 do
    local sum = 0
    for j=1,3 do
      xyz[j] = lorenz.weigths[i][j]*lorenz.state[j]
      sum = sum+lorenz.weigths[i][j]*lorenz.state[j]  
    end
  end

  lorenz.first = math.floor(xyz[1])
  lorenz.second = math.floor(xyz[2])
  lorenz.third = math.floor(xyz[3])

  -- lorenz.x_map = lorenz.first
  -- lorenz.y_map = lorenz.second
  -- lorenz.x_map = params:get("x_input")
  -- lorenz.y_map = params:get("y_input")
  -- print("lorenz.first",lorenz.first)
  local x_input = params:get("x_input")      
  if x_input == 1 then lorenz.x_map = lorenz.first 
  elseif x_input == 2 then lorenz.x_map = lorenz.second
  elseif x_input == 3 then lorenz.x_map = lorenz.third 
  end

  local y_input = params:get("y_input")      
  if y_input == 1 then lorenz.y_map = lorenz.first 
  elseif y_input == 2 then lorenz.y_map = lorenz.second
  elseif y_input == 3 then lorenz.y_map = lorenz.third 
  end

  local x = (lorenz.x_map) 
  local y = (lorenz.y_map) 

  -- screen.level(3)
  -- screen.aa(0)
  if lorenz.x_map~=0 and lorenz.y_map ~= 0 then
  -- if x~=64 + x_offset and y~=32 +  y_offset then
  -- if x~=64 and y~=32 then
  --   screen.move(x,y)
  --   screen.pixel(x,y)
    -- local num_pixels = pixels and #pixels+1 or 1
    -- print()
    local xy_exists = false
    for i=1,#pixels,1 do
      local prev_x = pixels[i].x
      local prev_y = pixels[i].y
      if prev_x == x and prev_y == y then 
        xy_exists = true
      end
    end
    if xy_exists == false then
      local px = pixel:new(x,y)
      pixels[#pixels+1] = px
    end
  end


    -- local outputs = 10*(sum+25)/80 - 5
    -- output[i].volts = 10*(sum+25)/80 - 5
end

-- input[1].change = function(s)
--   lorenz:reset()
-- end

-- input[2].stream = function(volts)
--   lorenz.dt = math.exp((volts-1)/3)/1000-0.00005
-- end

--[[
function init()
  lorenz:reset()
  -- input[1].mode('change', 1,0.1,'rising')
  -- input[2].mode('stream',0.001)
  clock.run( function()
    while true do
      lorenz:process()
      update()
      clock.sleep(0.001)
    end
  end)
end
]]

return lorenz