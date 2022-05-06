local gui = {}

local squiggle_ix = 1
local squiggle_width = 15
local lb = lorenz.boundary

function gui.setup_menu_maps()


  local lrz_params = {"lz_speed","rho","beta"}
  local outs = {"first","second","third","sum"}
  local axes = {"x","y","z"}
  for i=1,4 do
    local out=outs[i]
    for j=1,3 do
      local axis=axes[j]
      local lzw="lz_weight"..i.."_"..j
      table.insert(lrz_params,lzw)
    end  
  end

  function gui.vjd_rthms()
    return {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"}
  end


  local eng_params = {"rings_easter_egg","engine_mode","internal_trigger_type","frequency_slew","enable_frequency_slew","rings_pos",
                "rings_structure_base","rings_structure_range",
                "rings_brightness_base","rings_brightness_range",
                "rings_damping_base","rings_damping_range",
                "rings_poly"}

  local lfo_params = {}
  for i=1,2,1 do
    
    table.insert(lfo_params,i .. "lfo")
    table.insert(lfo_params,i .. "lfo_shape")
    table.insert(lfo_params,i .. "lfo_depth")
    table.insert(lfo_params,i .."offset")
    table.insert(lfo_params,i .. "lfo_freq")
  end
    
  gui.sub_menu_map_krell = {
    {"sequencing_mode","env_active","env_scalar","rise_time","fall_time","env_max_level","env_shape","num_octaves"},
    {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"},
    lrz_params,
    lfo_params,
    eng_params,
  }

  local vjd_seq_options = {"sequencing_mode","env_active","env_scalar","rise_time","fall_time","env_max_level","env_shape","num_octaves","loop_length","vuja_de_prob"}
  for i=1,params:get("vuja_de_num_divs"),1 do
    table.insert(vjd_seq_options,"vuja_pat_defaults"..i)
  end
  gui.sub_menu_map_vuja_de = {
    vjd_seq_options,
    -- gui.vjd_rthms(),
    {"x_input","y_input","x_offset","y_offset","x_scale","y_scale"},
    lrz_params,
    lfo_params,
    eng_params,
  }

  menu_map = {"seq","scr","lrz","lfo","eng"}
  if sequencing_mode == 1 then
    sub_menu_map = gui.sub_menu_map_krell
  else
    -- menu_map = {"seq","rst","scr","lrz","res"}
    sub_menu_map = gui.sub_menu_map_vuja_de
  end

  for i=1,#menu_map,1 do
    for j=1,#gui.sub_menu_map_vuja_de[i] do
      
      local param_name = gui.sub_menu_map_vuja_de[i][j]
      local p = params:lookup_param(param_name)
      if p.og_action_menu_map == nil then
        p.og_action_menu_map = fn.clone_function(p.action)
        p.action = function(x)
          -- do something
          p.og_action_menu_map(x)
          if norns.menu.status()  == false and page == 1 then
            clock.run(gui.update_menu_display)
          end
        end
      end
    end
  end
end

function gui.init()

  active_menu = 1
  -- active_sub_menu = {1,1,1,1}
  active_sub_menu = {1,1,1,1,1}
  active_sub_menu_label = ""
  active_sub_menu_value = ""

  gui.updating_menu_display = false

  gui.setup_menu_maps()

end

function gui.update_menu_display()
  if gui.updating_menu_display == false then
    gui.updating_menu_display = true
    clock.sleep(0.01)

    screen.level(0)
    screen.rect(0,1,48,15)
    screen.fill()

    screen.level(0)
    screen.rect(1,18,41,10)
    screen.fill()

    screen.level(0)
    screen.rect(1,30,45,28)
    screen.fill()

    
    if type(sub_menu_map[active_menu]) == "table" then
      param_name = sub_menu_map[active_menu][active_sub_menu[active_menu]]
      param = params:lookup_param(param_name)
      local p_type = params:t(param_name)
      active_sub_menu_label = param.name
      if p_type == 2 then -- options param
        active_sub_menu_value = param.options[param.selected]
      elseif p_type == 1 then -- number param
        active_sub_menu_value = param.value
      elseif p_type == 3  then -- control param
        local val = params:get(param_name)
        active_sub_menu_value = val
      elseif p_type == 5  then -- taper param
        local val = params:get(param_name)
        active_sub_menu_value = util.linlin(0,1,param.min,param.max,val)
      end

      if type(active_sub_menu_value) == "number" then
        active_sub_menu_value = fn.round_decimals (active_sub_menu_value, 3, "down")
      end
    else
      print("vjd_rthms")
    end
    gui.updating_menu_display = false
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
    if params:get("grid_display") ~= 3 then gui_level = amt end 
    clock.run(gui.set_gui_level,amt)
  else
    if params:get("grid_display") ~= 3 then
      gui_level = 0
    end
    set_gui_level_initiated = false
    if params:get("grid_display") == 2 then
      clock.run(gui.clear)
    end
  end
end

function gui:display()
  if page == 1 then
    gui:display_lorenz()
  else 
    -- screen.clear()
    screen.font_size(8)
    lorenz.display(false)
    mod_matrix:display_mod_matrix()
  end
end

function gui:display_lorenz()
  -- print("disp")
  screen.aa(0)
  -- if params:get("grid_display") > 1 and gui_level > 0 then 
    -- sound_controller:display() 
  -- end

  -- display left menu 
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-5,lb[4]-19)
  screen.stroke()
  screen.font_size(8)

  if #menu_map > 3 and active_menu <= 3 then
    screen.rect(lb[1]-11,lb[2]+10,6,0)
    screen.rect(lb[1]-4,lb[2]+3,0,7)
  elseif #menu_map > 3 then
    screen.rect(1,lb[2]+10,6,0)
    screen.rect(1,lb[2]+3,0,7)
  end

  screen.level(math.floor(gui_level*(active_menu == 1 and 10 or 3)))
  screen.move(2,lb[2]+8)
  local text1 = active_menu < 4 and menu_map[1] or menu_map[(active_menu-2)]
  screen.text(text1)
  
  screen.level(math.floor(gui_level*(active_menu == 2 and 10 or 3)))
  screen.move(18,lb[2]+8)
  local text2 = active_menu < 4 and menu_map[2] or menu_map[(active_menu-1)] 
  screen.text(text2)
  
  screen.level(math.floor(gui_level*(active_menu >= 3 and 10 or 3)))
  screen.move(32,lb[2]+8)
  local text3 = active_menu < 4 and menu_map[3] or menu_map[(active_menu)]
  screen.text(text3)

  -- display left menu sub items
  screen.level(math.floor(gui_level*3))
  screen.move(1,lb[2]+14)
  screen.rect(1,lb[2]+14,lb[1]-8,11)
  screen.stroke()
  screen.move(3,lb[2]+21)
  screen.level(math.floor(gui_level*10))
  screen.text(active_sub_menu_label)

  -- display left sub item value
  screen.move((lb[1]-5)/2,45)
  screen.font_size(10)
  screen.text_center(active_sub_menu_value)

  -- draw squggles
  screen.level(10)
  if pixels[pixels.active] and UI_DISPLAY_SQUIGGLES == 2 then
    -- draw lorenz x/y squiggles 
    local lz_x_display = pixels[pixels.active].x_display
    local lz_y_display = pixels[pixels.active].y_display
    gui.draw_squiggles(105,0,19,10,lz_x_display,"lzx",squiggle_ix)
    gui.draw_squiggles(105,16,19,10,lz_y_display,"lzy",squiggle_ix)

    -- draw lfo squiggles
    if mod_matrix.lfo[1].slope then
      gui.draw_squiggles(105,32,19,10,mod_matrix.lfo[1].slope,"lfo1",squiggle_ix)
      gui.draw_squiggles(105,49,19,10-2,mod_matrix.lfo[2].slope,"lfo2",squiggle_ix)  
    end
  end

  squiggle_ix = squiggle_ix+1
  if squiggle_ix > squiggle_width then
    squiggle_ix = 1
  end 

  screen.aa(0)
  if params:get("grid_display") > 1 and gui_level > 0 then 
    sound_controller:display() 
  end

  screen.aa(1)
  lorenz.display(true)
end

function gui.draw_squiggles(lx,ly,lw,lh,squiggle_y,squiggle_type,ix)
  local sc_dims = sound_controller:get_dimensions()

  local x1 = sc_dims.x
  local x2 = sc_dims.x+sc_dims.w
  local y1 = sc_dims.y
  local y2 = sc_dims.y+sc_dims.h
  local y_loc
  if squiggle_type == "lzx" then
    y_loc = util.linlin(x1,x2,ly,ly+lh,squiggle_y)
  elseif squiggle_type == "lzy" then
    y_loc = util.linlin(y1,y2,ly,ly+lh,squiggle_y)
  else
    y_loc = util.linlin(0,1,ly,ly+lh,squiggle_y)
  end 
  y_loc = math.floor(y_loc)
  screen.level(0)
  screen.rect(lx+ix,ly-2,1,lh+4)
  screen.stroke()
  screen.level(10)
  screen.pixel(lx+ix,y_loc)    
  -- draw label
  screen.aa(0)
  screen.move(x2,ly+lh+4)
  -- screen.move(105,lb[2]+8)
  screen.stroke()
  screen.level(math.floor(gui_level*3))
  -- screen.level(10)
  screen.font_size(8)
  -- screen.text(squiggle_type)
  screen.text_rotate(x2+lw,ly,squiggle_type,90)
  screen.stroke()
  
end



return gui