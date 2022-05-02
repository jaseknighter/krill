--------------------------
-- encoders and keys
--------------------------
local last_page = 1
function enc(n, d)
  clock.run(gui.update_menu_display)
  param_name = sub_menu_map[active_menu][active_sub_menu[active_menu]]
  if n== 1 and initializing == false and k1_active == true then
    page = util.clamp(page+d,1,2)
    if (last_page == 2 and page == 1) or (last_page == 1 and page == 2) then
      mod_matrix:start_stop_scrolling()
    end
    last_page = page
    screen.clear()
  elseif page == 1 and initializing == false and gui_level == 1 then
    if n==1 and k1_active == false then
      active_menu =  util.clamp(active_menu+d,1,#menu_map)
      clock.run(gui.update_menu_display)
    elseif n==2 then
      local new_active_sub_menu = util.clamp(active_sub_menu[active_menu]+d,1,#sub_menu_map[active_menu])
      if new_active_sub_menu ~= active_sub_menu[active_menu] then
        active_sub_menu[active_menu] = new_active_sub_menu
        clock.run(gui.update_menu_display)
      end
    elseif n== 3 then
      
      local p_type = params:t(param_name)
      local param = params:lookup_param(param_name)
      if p_type == 2 then --option param
        params:set(param_name,params:get(param_name)+d)
      elseif p_type == 1 then -- number param
        d = k2_active == true and d*10 or d
        params:set(param_name,params:get(param_name)+d)
      elseif p_type == 3 then -- control param
        d = k2_active == true and d*10 or d
        local new_d = params:get(param_name)+(d*param.controlspec.step)
        -- local new_d = params:get(param_name)+(d*param.controlspec.step)
        params:set(param_name,new_d)
        -- print("p_type,new_d",p_type,new_d,d,param.controlspec.step)
      elseif p_type == 5 then -- taper param
        d = k2_active == true and d*10 or d
        local new_d
        local max = param.max and param.max or param.controlspec.maxval
        if max < 1 then 
          new_d = params:get(param_name)+(d*0.001)
        else
          new_d = params:get(param_name)+(d*0.01)
        end

        -- local new_d = params:get(param_name)+(d*param.min)
        params:set(param_name,new_d)
        clock.run(gui.update_menu_display)

      end
      -- clock.run(gui.update_menu_display)
      -- if d<0 then d=-0.01 else d=0.01 end
      -- params:set("xy_scale",params:get("xy_scale")+d)
    end
  
  elseif page == 2 and initializing == false then
    mod_matrix.enc(n,d)
    screen.clear()
  end
  
  if page == 1 then 
    if set_gui_level_clock then
      clock.cancel(set_gui_level_clock)
      set_gui_level_clock = clock.run(gui.set_gui_level)
    elseif set_gui_level_initiated == false then
      set_gui_level_clock = clock.run(gui.set_gui_level)
    end
  end
  
  
end

function key(n,z)
  -- if initializing == false then
  -- end
  if n == 1 then
    if z == 0 then k1_active = false else k1_active = true end
  elseif n == 2 then
    if z == 0 then k2_active = false else k2_active = true end
  end
  if k1_active == false then
    if page==2 then
      mod_matrix.key(n,z)
      screen.clear()
    end
  end
  
end

