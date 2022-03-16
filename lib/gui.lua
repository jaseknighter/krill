local gui = {}

local lb = lorenz.boundary
active_menu = 1
active_sub_menu = 1
active_sub_menu_label = ""
active_sub_menu_value = ""


-- menu_map = {"lzv","lzp","mod","xy","vd"}
-- menu_map = {"mod","lzv","lzp","xy","vd"}
menu_map = {"eng","scr","lrz"}

sub_menu_map_krell = {
  -- lv (lorenz view)
  {"engine_mode","env_scalar","rise_time","fall_time"},
  {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"},
  {"lz_speed","origin1","origin2","origin3","sigma","rho","beta","state1","state2","state3","steps","dt"},
}


sub_menu_map_vuja_de = {
  -- lv (lorenz view)
  {"engine_mode","env_scalar","rise_time","fall_time","loop_length","vuja_de_prob"},
  {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"},
  {"lz_speed","origin1","origin2","origin3","sigma","rho","beta","state1","state2","state3","steps","dt"},
}

sub_menu_map = sub_menu_map_krell

function update_menu_display()
  clock.sleep(0.01)
  if active_menu < 4 then
    -- screen.clear()
    --clear sub-menu value text areas
    screen.level(0)
    screen.rect(1,18,41,10)
    screen.fill()

    screen.level(0)
    screen.rect(1,30,45,28)
    screen.fill()

    
    if active_menu < 4 then
      param_name = sub_menu_map[active_menu][active_sub_menu]
      param = params:lookup_param(param_name)
      local p_type = params:t(param_name)
      active_sub_menu_label = param.name
      if p_type == 2 then -- options param
        active_sub_menu_value = param.options[param.selected]
      elseif p_type == 1 then -- number param
        active_sub_menu_value = param.value
      elseif p_type == 5  then -- taper param
        local val = params:get(param_name)
        active_sub_menu_value = util.linlin(0,1,param.min,param.max,val)
      end

      if type(active_sub_menu_value) == "number" then
        active_sub_menu_value = fn.round_decimals (active_sub_menu_value, 3, "down")
      end
    end
  end
  -- if active_menu > 3 then
  --   active_sub_menu_label = ""
  --   active_sub_menu_value = ""
  --   screen.level(0)
  --   -- screen.rect(1,19,41,10)
  --   -- screen.fill()
  --   screen.rect(1,30,45,28)
  --   screen.fill()
  --   if active_menu == 5 then
      
  --   end
  -- end
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, d)
  clock.run(update_menu_display)
  if initializing == false and gui_level == 1 then
    if n==1 then
      active_menu =  util.clamp(active_menu+d,1,#menu_map)
      clock.run(update_menu_display)
    elseif n==2 then
      local new_active_sub_menu = util.clamp(active_sub_menu+d,1,#sub_menu_map[active_menu])
      if new_active_sub_menu ~= active_sub_menu then
        active_sub_menu = new_active_sub_menu
        clock.run(update_menu_display)
      end
    elseif n== 3 then
      if param.options then --option param
        params:set(param_name,params:get(param_name)+d)
      elseif param.range then -- number param
        params:set(param_name,params:get(param_name)+d)
      else -- taper param
        local new_d
        local max = param.max and param.max or param.controlspec.maxval
        if max < 1 then 
          new_d = params:get(param_name)+(d*0.0001)
        else
          new_d = params:get(param_name)+(d*0.1)
        end

        -- local new_d = params:get(param_name)+(d*param.min)
        params:set(param_name,new_d)
        clock.run(update_menu_display)

      end
      -- clock.run(update_menu_display)
      -- if d<0 then d=-0.01 else d=0.01 end
      -- params:set("xy_scale",params:get("xy_scale")+d)
    end
  end

  if set_gui_level_clock then
    clock.cancel(set_gui_level_clock)
    set_gui_level_clock = clock.run(gui.set_gui_level)
  elseif set_gui_level_initiated == false then
    set_gui_level_clock = clock.run(gui.set_gui_level)
  end
  

end

function key(n,z)
  if initializing == false then
  end
end

function gui.clear()
  clock.sleep(0.01)
  sound_controller:display(true) 
  screen.clear()

end

function gui.set_gui_level(amt)
  set_gui_level_initiated = true
  local amt = amt and amt*0.75 or 1
  if amt == 1 then
    gui_level = 1
    clock.sleep(3)
  else
    clock.sleep(0.15)
  end
  if amt > 0.2 then
    gui_level = amt
    clock.run(gui.set_gui_level,amt)
  else
    gui_level = 0
    set_gui_level_initiated = false
    if params:get("grid_display") == 2 then
      clock.run(gui.clear)
    end
  end
end


local lz_ix = 1
function gui:display()
  -- screen.aa(0)

  -- display left menu items
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-5,lb[4]-15)
  screen.stroke()
  screen.font_size(8)

  screen.level(math.floor(gui_level*(active_menu == 1 and 10 or 3)))
  screen.move(2,lb[2]+8)
  screen.text(menu_map[1])
  
  screen.level(math.floor(gui_level*(active_menu == 2 and 10 or 3)))
  screen.move(20,lb[2]+8)
  screen.text(menu_map[2])
  
  screen.level(math.floor(gui_level*(active_menu == 3 and 10 or 3)))
  screen.move(36,lb[2]+8)
  screen.text(menu_map[3])

  -- display left menu sub items
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-10,10)
  screen.stroke()
  screen.move(3,lb[2]+21)
  screen.level(math.floor(gui_level*10))
  screen.text(active_sub_menu_label)

  -- display left sub item value
  screen.move((lb[1]-5)/2,45)
  screen.font_size(10)
  screen.text_center(active_sub_menu_value)
  -- print("active_sub_menu_value",active_sub_menu_value)
  --[[
    "x_input","y_input","x_offset","y_offset","x_scale","y_scale"
  ]]

  -- screen.aa(0)
  -- draw right menu
  -- screen.level(math.floor(gui_level*(active_menu == 4 and 10 or 3)))
  -- screen.move(105,lb[2]+8)
  -- screen.font_size(8)
  -- screen.text(menu_map[4])

  -- screen.level(math.floor(gui_level*(active_menu == 5 and 10 or 3)))
  -- screen.move(118,lb[2]+8)
  -- screen.font_size(8)
  -- screen.text(menu_map[5])

  -- draw right xy squggles
  
  if active_menu <= 5 then
    screen.level(10)
    -- screen.rect(106,20,22,15)
    -- screen.stroke()
    if pixels[pixels.active] then
      local x = pixels[pixels.active].x_display
      local y = pixels[pixels.active].y_display
          
      
      gui.draw_lorenz_coords(106,20,20,15,x,"x")
      -- gui.draw_lorenz_coords(106,20,22-2,10-2,lorenz.x_map)
      screen.stroke()
      -- screen.rect(106,40,22,15)
      -- screen.stroke()
      gui.draw_lorenz_coords(106,40,22-2,15-2,y,"y")
      -- gui.draw_lorenz_coords(106,40,22-2,10-2,y)
      -- gui.draw_lorenz_coords(106,40,22-2,10-2,lorenz.y_map)
      screen.stroke()
    end
  else
    screen.level(0)
    -- screen.rect(106,18,22,60)
    screen.fill()
    screen.stroke()
  end

  lz_ix = lz_ix+1
  if lz_ix > 20 then
    -- screen.clear()
    lz_ix = 1
  else
    -- screen.clear()
  end 

end

function gui.draw_lorenz_coords(lx,ly,lw,lh,y,dim)
  -- local x1 = lb[1]
  -- local x2 = lb[1]+lb[3]
  local dims = sound_controller:get_dimensions()

  local x1 = dims.x
  local x2 = dims.x+dims.w
  local y1 = dims.y
  local y2 = dims.y+dims.h
  -- if ly < 40 then print(y_loc,x1,x2,ly,ly+lh,y_loc+((x1+x2)/2)) end
  -- if ly > 20 then print(y_loc,x1,x2,ly,ly+lh,y_loc) end
  -- local y1 = util.linlin(x1,x2,ly,ly+lh,y_loc+((x1+x2)/2))
  local y_loc
  if dim == "x" then
    y_loc = util.linlin(x1,x2,ly,ly+lh,y)
    lz_x = util.linlin(x1,x2,0,1,y)
  else
    y_loc = util.linlin(y1,y2,ly,ly+lh,y)
    lz_y = util.linlin(y1,y2,0,1,y)
    -- print(x1,x2,y1,y2,y,y_loc,lz_y)
  end 
  y_loc = math.floor(y_loc)
  screen.level(0)
  screen.rect(lx+lz_ix,ly,1,lh+1)
  screen.stroke()
  screen.level(10)
  screen.pixel(lx+lz_ix,y_loc)    
end

return gui