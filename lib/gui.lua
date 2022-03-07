local gui = {}

local lb = lorenz.boundary
active_menu = 1
active_sub_menu = 1
active_sub_menu_label = ""
active_sub_menu_value = ""

menu_map = {
  -- lv (lorenz view)
  {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"},
  -- {"x_input","y_input","x_offset","y_offset","xy_scale","x_scale","y_scale"},
  -- lp (lorenz params)
  {"origin1","origin2","origin3","sigma","rho","beta","state1","state2","state3","steps","dt"},
  -- krl (krell mode)
  {"krell","rand"},
  -- rnd (random mode)
  {"krell","rand"},
}

function update_menu_display()
  param_name = menu_map[active_menu][active_sub_menu]
  if param_name then
    param = params:lookup_param(param_name)
    active_sub_menu_label = param.name
    if param.options then
      active_sub_menu_value = param.options[param.selected]
    elseif param.min > 0 and param.min < 1 then
      active_sub_menu_value = fn.round_decimals (param.value, 4, "down")
    else
      active_sub_menu_value = param.value
    end
  else
    print("gui.lua:34 no param name!!!???")
  end
end
--------------------------
-- encoders and keys
--------------------------
function enc(n, d)
  update_menu_display()
  if initializing == false and gui_level == 1 then
    if n==1 then
      active_menu =  util.clamp(active_menu+d,1,2)
      screen.clear()
      update_menu_display()
    elseif n==2 then
      local new_active_sub_menu = util.clamp(active_sub_menu+d,1,#menu_map[active_menu])
      if new_active_sub_menu ~= active_sub_menu then
        screen.clear()
        active_sub_menu = new_active_sub_menu
        update_menu_display()
      end
    elseif n== 3 then
      if param.options then --option param
        params:set(param_name,params:get(param_name)+d)
      elseif param.range then -- number param
        params:set(param_name,params:get(param_name)+d)
      else -- taper param
        local new_d
        
        if param.max < 1 then 
          new_d = params:get(param_name)+(d*0.0001)
        else
          new_d = params:get(param_name)+(d*0.1)
        end

        -- local new_d = params:get(param_name)+(d*param.min)
        params:set(param_name,new_d)
      end
      update_menu_display()
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
function gui:display()
  -- screen.aa(0)

  -- display menu items
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-5,lb[4]-15)
  screen.stroke()
  screen.font_size(8)

  screen.level(math.floor(gui_level*(active_menu == 1 and 10 or 3)))
  screen.move(3,lb[2]+8)
  screen.text("lzv")
  
  screen.level(math.floor(gui_level*(active_menu == 2 and 10 or 3)))
  screen.move(18,lb[2]+8)
  screen.text("lzp")
  
  -- screen.level(math.floor(gui_level*(active_menu == 2 and 10 or 3)))
  -- screen.move(32,lb[2]+8)
  -- screen.text("mod")

  -- display menu sub items
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-10,10)
  screen.stroke()
  screen.move(3,lb[2]+21)
  screen.level(math.floor(gui_level*10))
  screen.text(active_sub_menu_label)

  -- display sub item value
  screen.move((lb[1]-5)/2,45)
  screen.font_size(10)
  screen.text_center(active_sub_menu_value)
  --[[
    "x_input","y_input","x_offset","y_offset","x_scale","y_scale"
  ]]


  screen.stroke()
end

return gui