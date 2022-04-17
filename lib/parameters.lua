local parameters = {}

function parameters.init()

  --------------------------------
  -- SCALES, NOTES, AND TEMPO
  -- scale: the scale to use
  -- scale length: the number of notes in the scale, centered around the `note_offset`
  -- root note: the lowest note in the scale
  -- note_offset: the note to use as "1" in the sequencer
  --------------------------------

  -- function parameters.play_random_note_offset()
  --   local offset = params:lookup_param("note_offset")
  --   local offset_options = {}
  --   for k,v in pairs(notes) do 
  --     if v then
  --       table.insert(offset_options,MusicUtil.note_num_to_name(v,true))
  --     end
  --   end
  --   offset.options = offset_options
  --   offset.count = #offset_options
  -- end

  params:add_separator("SCALES")
  -- params:add_group("scales and notes",5)

  
  params:add{type = "number", id = "num_octaves", name = "num octs", min=1,max=NUM_OCTAVES_MAX,default=NUM_OCTAVES_DEFAULT,
    action = function(val) 
      fn.build_scale() 
      sound_controller:init(val,fn.get_num_notes_per_octave())
      screen.clear()
      -- parameters.play_random_note_offset()
      -- local sl = params:lookup_param("scale_length")
      -- sl.maxval = fn.get_num_notes_per_octave() * val
  end}

  -- params:add{type = "number", id = "scale_length", name = "scale length",
  --   min = 1, max = max_notes, default = ROOT_NOTE_DEFAULT, 
  --   action = function(val) 
  --     fn.build_scale() 
  --     parameters.play_random_note_offset()
  --     local sl = params:lookup_param("scale_length")
  --     sl.maxval = fn.get_num_notes_per_octave() * 5
  -- end}

  -- params:hide("scale_length")

  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5,
    action = function() 
      fn.build_scale() 
      if initializing == false then 
        -- parameters.play_random_note_offset()
      end
  end}

  
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = ROOT_NOTE_DEFAULT, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() 
      fn.build_scale() 
      -- parameters.play_random_note_offset()
  end}

  params:add{type = "number", id = "note_offset", name = "note offset",
    min = -24, max = 24, default = 0, 
    action = function() 
      fn.build_scale() 
      -- parameters.play_random_note_offset()
  end}

  params:hide("note_offset")

  
  --------------------------------
  -- lorenz params
  --------------------------------
  params:add_separator("LORENZ")
  params:add_group("lorenz view",7)
  -- params:add{
  --   type="control", id = "rotation", name = "rotation",
  --   controlspec=cs.new(-360, 360, 'lin', 1, 0, "",1/720,true),
  --   action=function(x) 
  --     --lorenz:reset()
  --   end
  -- }

  params:add{
    type="option", id = "x_input", name = "x input", options={"first","second","third"},default = 1,
    action=function(x) 
      --lorenz:reset()
    end
  }
  params:add{
    type="option", id = "y_input", name = "y input", options={"first","second","third"},default = 2,
    action=function(x) 
      --lorenz:reset()
    end
  }

  params:add{
    type="number", id = "x_offset", name = "x offset",min=-128, max=128, default = 0,
    action=function(x) 
      -- lorenz:reset()
      screen:clear()
    end
  }
  params:add{
    type="number", id = "y_offset", name = "y offset",min=-64, max=64, default = 0,
    action=function(x) 
      -- lorenz:reset()
      screen:clear()
    end
  }

  params:add{
    type="number", id = "xy_offset", name = "xy offset",min=-64, max=64, default = 0,
    action=function(x) 
      params:set("x_offset",x)
      params:set("y_offset",x)
      -- lorenz:reset()
      screen:clear()
    end
  }

  params:add{
    type="taper", id = "x_scale", name = "x scale",min=0.01, max=10, default = 1,
    action=function(x) 
      -- lorenz:reset()
      screen:clear()
    end
  }
  
  params:add{
    type="taper", id = "y_scale", name = "y scale",min=0.01, max=10, default = 1,
    action=function(x) 
      -- lorenz:reset()
      screen:clear()
    end
  }

  -- params:add{
  --   type="taper", id = "xy_scale", name = "xy scale",min=0.01, max=2, default = 1,
  --   action=function(x) 
  --     -- params:set("x_scale",x)
  --     -- params:set("y_scale",x)
  --     params:set("x_scale",params:get("x_scale") * x)
  --     params:set("y_scale",params:get("y_scale") * x)
  --     -- lorenz:reset()
  --     screen:clear()
  --   end
  -- }


  params:add_group("lorenz weights",16)
  local xyz = {}
  local lz_weights_cs = cs.new(0, 3, 'lin', 0.01, 0, "",0.001)
  for i=1,4 do
    local outs = {"1st","2nd","3rd","sum"}
    local axes = {"x","y","z"}
    local out,axis
    for j=1,3 do
      if j==1 then
        params:add_separator("output: " .. outs[i])
      end
      out=outs[i]
      axis=axes[j]
      local cs = fn.deep_copy(lz_weights_cs)
      cs.default = LORENZ_WEIGHTS_DEFAULT[i][j]
      params:add{
        type="control", id = "lz_weight"..i.."_"..j, name = "w-" .. out..": "..axis.."", controlspec=cs,
        -- type="number", id = "lz_weight"..i.."_"..j, name = "lz weight "..out..": "..axis.."", min=0,max=10,default = LORENZ_WEIGHTS_DEFAULT[i][j],
        action=function(x) 
          lorenz.weigths[i][j] = x
        end
      }
      
    end
  end

  params:add_group("lorenz params",12)
  
  params:add{
    type="number", id = "lz_speed", name = "lz speed", min=0,max=100,default = 80,
    action=function(x) 
      if x==0 then -- set to clock
        lorenz_pattern.division = 1/params:get("clock_tempo")
      else
        local denominator = util.linexp(1,100,1,1000,x)
        lorenz_pattern.division = 1/denominator
      end
      --lorenz:reset()
    end
  }


  params:add{
    type="taper", id = "origin1", name = "origin1",min=0.000, max=20, default = 0.01,
    action=function(x) 
      lorenz.origin[1]=x
      --lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "origin2", name = "origin2",min=0.000, max=20, default = 0.5,
    action=function(x) 
      lorenz.origin[2]=x
      --lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "origin3", name = "origin3",min=0.000, max=20, default = 0.0,
    action=function(x) 
      lorenz.origin[3]=x
      --lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "sigma", name = "sigma",min=0.001, max=10, default = 2.333,
    action=function(x) 
      lorenz.dt=x
      --lorenz:reset()
    end
  }

  params:add{
    type="number", id = "rho", name = "rho",min=1, max=50, default = 28,
    action=function(x) 
      lorenz.rho=x
      --lorenz:reset()
    end
  }

  params:add{
    type="control", id = "beta", name = "beta",
    controlspec=cs.new(0.01,2.0,'lin',0.01,4/3,"",0.01),
    -- ControlSpec.new (min, max, warp, step, default, units, quantum, wrap)
    -- min=0.01, max=2, default = 4/3, 
    action=function(x) 
      lorenz.beta=x
      --lorenz:reset()
    end
  }

  params:add{
    type="control", id = "state1", name = "state1",
    controlspec=cs.new(0.1,2.0,'lin',0.001,4/3,"",0.001),
    -- min=0.000, max=2, default = 0.1,
    action=function(x) 
      lorenz.state[1]=x
      --lorenz:reset()
    end
  }
  
  params:add{
    type="control", id = "state2", name = "state2",
    controlspec=cs.new(0.1,2.0,'lin',0.001,4/3,"",0.001),
    -- min=0.000, max=2, default = 0.0,
    action=function(x) 
      lorenz.state[3]=x
      --lorenz:reset()
    end
  }
  
  params:add{
    type="control", id = "state3", name = "state3",
    controlspec=cs.new(0.1,2.0,'lin',0.001,4/3,"",0.001),
    -- min=0.000, max=2, default = 0.0,
    action=function(x) 
      lorenz.state[3]=x
      --lorenz:reset()
    end
  }
  
  
  params:add{
    type="number", id = "steps", name = "steps",min=1, max=100, default = 1,
    action=function(x) 
      lorenz.steps=x
      --lorenz:reset()
    end
  }
  params:add{
    type="taper", id = "dt", name = "dt",min=0.001, max=0.05, default = 0.015,
    action=function(x) 
      lorenz.dt=x
      --lorenz:reset()
    end
  }

  --------------------------------
  -- quant grid params
  --------------------------------
  params:add_separator("QUANT GRID")
  -- params:add_group("lorenz",19)
  params:add{type = "option", id = "grid_display", name = "grid display",
    options = {"hide","show","always show"}, default = UI_DISPLAY_DEFAULT,
    action = function(x)
      if x == 1 then screen.clear() 
      elseif x == 3 then gui_level = 1
      end 
  end}

  --------------------------------
  -- vuja de params
  --------------------------------
  params:add_separator("VUJA DE")
  -- params:add_group("lorenz",19)

  params:add{type = "number", id = "loop_length", name = "loop len",
  min=1, max=16, default=3,
  action = function(x)

  end}

  params:add{type = "number", id = "vuja_de_prob", name = "vjd div",
  min=-10, max=10, default=-5,
  action = function(x)
  end}

  parameters.setting_patterns = false
  params:add{type = "number", id = "vuja_de_num_divs", name = "vjd num divs",
  min=1, max=VJD_MAX_DIVISIONS, default=3,
  action = function(x)
    -- if parameters.setting_patterns == false then
    --   parameters.setting_patterns = true
      parameters.set_pats(x)
      _menu.rebuild_params()
      -- parameters.setting_patterns = false
    -- end
  end}

  params:add_group("division patterns",12+3+(VJD_MAX_DIVISIONS*3))
  params:add_separator("assignments")
  params:add{type = "number", id = "vjd_div_asn_engine1", name = "engine asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_engine2", name = "engine asn 2", min=1, max=3, default=2}
  params:add{type = "number", id = "vjd_div_asn_midi1", name = "midi asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_midi2", name = "midi asn 2", min=1, max=3, default=2}
  params:add{type = "number", id = "vjd_div_asn_crow1", name = "crow asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_crow2", name = "crow asn 2", min=1, max=3, default=2}
  params:add{type = "number", id = "vjd_div_asn_jf1", name = "jf asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_jf2", name = "jf asn 2", min=1, max=3, default=2}
  params:add{type = "number", id = "vjd_div_asn_wsyn1", name = "wsyn asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_wsyn2", name = "wsyn asn 2", min=1, max=3, default=2}
  params:add{type = "number", id = "vjd_div_asn_wdelkarp1", name = "wdelkarp asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_div_asn_wdelkarp2", name = "wdelkarp asn 2", min=1, max=3, default=2}
  
  params:add_separator("")
  params:add_separator("divisions")


  local vjd_jitter_cs = cs.new(-100, 100, 'lin', 0, 1, "",1)

  for i=1,VJD_MAX_DIVISIONS,1 do
    -- params:add_separator("pattern "..i)
    params:add{ type = "option", id = "pat_lab"..i, name = "---------- division " .. i .. " ----------",  options = {" "}}
    params:add{type = "number", id = "vuja_de_div_numerator"..i, name = "vjd div num"..i,
      min=1, max=VJD_MAX_PATTERN_NUMERATOR, default=1,
      action = function(x)
        vuja_de_patterns[i]:set_division(x/params:get("vuja_de_div_denominator"..i))
    end}

    params:add{type = "number", id = "vuja_de_div_denominator"..i, name = "vjd div den"..i,
      min=1, max=VJD_MAX_PATTERN_DENOMINATOR, default=1,
      action = function(x)
        vuja_de_patterns[i]:set_division(params:get("vuja_de_div_numerator"..i)/x)
    end}

    params:add{type = "number", id = "vuja_de_jitter"..i, name = "vjd jitter"..i,
      min=-100,max=100,default=0,
      -- controlspec=vjd_jitter_cs,
      action = function(x)
    end}

    params:add{type = "option", id = "vuja_de_oct_offset"..i, name = "vjd oct offset"..i,
      options={-4,-3,-2,-1,1,2,3,4}, default=5,
      -- controlspec=vjd_jitter_cs,
      action = function(x)
    end}

    params:add{
      type = "option", id = "vuja_de_engine_mode"..i, name = "vjd eng mode"..i, 
      options = {"def","res","str"},
      default = 1,
      action = function(value) 
    end}
  
    if i>3 then
      params:hide("vuja_de_div_numerator"..i)
      params:hide("vuja_de_div_denominator"..i)
      params:hide("vuja_de_jitter"..i)
      params:hide("vuja_de_oct_offset"..i)
      params:hide("vuja_de_engine_mode"..i)
      params:hide("pat_lab"..i)
      
    end
      
  end

  function parameters.set_pats(num_divs)   
    print("set divs") 
    for i=1,VJD_MAX_DIVISIONS,1 do
      if i>num_divs then
        params:hide("vuja_de_div_numerator"..i)
        params:hide("vuja_de_div_denominator"..i)
        params:hide("pat_lab"..i)
        params:hide("vuja_de_jitter"..i)
        params:hide("vuja_de_oct_offset"..i)
        params:hide("vuja_de_engine_mode"..i)
      else
        params:show("vuja_de_div_numerator"..i)
        params:show("vuja_de_div_denominator"..i)    
        params:show("pat_lab"..i)    
        params:show("vuja_de_jitter"..i)
        params:show("vuja_de_oct_offset"..i)
        params:show("vuja_de_engine_mode"..i)
      end
    end

    if params:get("vjd_div_asn_engine1") > num_divs then 
      params:set("vjd_div_asn_engine1",1)
    end
    if params:get("vjd_div_asn_midi1") > num_divs then 
      params:set("vjd_div_asn_midi1",1)
    end
    if params:get("vjd_div_asn_crow1") > num_divs then 
      params:set("vjd_div_asn_crow1",1)
    end
    if params:get("vjd_div_asn_jf1") > num_divs then 
      params:set("vjd_div_asn_jf1",1)
    end
    if params:get("vjd_div_asn_wsyn1") > num_divs then 
      params:set("vjd_div_asn_wsyn1",1)
    end
    if params:get("vjd_div_asn_wdelkarp1") > num_divs then 
      params:set("vjd_div_asn_wdelkarp1",1)
    end

    if params:get("vjd_div_asn_engine2") > num_divs then 
      params:set("vjd_div_asn_engine2",1)
    end
    if params:get("vjd_div_asn_midi2") > num_divs then 
      params:set("vjd_div_asn_midi2",1)
    end
    if params:get("vjd_div_asn_crow2") > num_divs then 
      params:set("vjd_div_asn_crow2",1)
    end
    if params:get("vjd_div_asn_jf2") > num_divs then 
      params:set("vjd_div_asn_jf2",1)
    end
    if params:get("vjd_div_asn_wsyn2") > num_divs then 
      params:set("vjd_div_asn_wsyn2",1)
    end
    if params:get("vjd_div_asn_wdelkarp2") > num_divs then 
      params:set("vjd_div_asn_wdelkarp2",1)
    end

    local vjd_div_asn_engine1 = params:lookup_param("vjd_div_asn_engine1")
    local vjd_div_asn_midi1 = params:lookup_param("vjd_div_asn_midi1")
    local vjd_div_asn_crow1 = params:lookup_param("vjd_div_asn_crow1")
    local vjd_div_asn_jf1 = params:lookup_param("vjd_div_asn_jf1")
    local vjd_div_asn_wsyn1 = params:lookup_param("vjd_div_asn_wsyn1")
    local vjd_div_asn_wdelkarp1 = params:lookup_param("vjd_div_asn_wdelkarp1")
    vjd_div_asn_engine1.max = num_divs
    vjd_div_asn_midi1.max = num_divs
    vjd_div_asn_crow1.max = num_divs
    vjd_div_asn_jf1.max = num_divs
    vjd_div_asn_wsyn1.max = num_divs
    vjd_div_asn_wdelkarp1.max = num_divs

    local vjd_div_asn_engine2 = params:lookup_param("vjd_div_asn_engine2")
    local vjd_div_asn_midi2 = params:lookup_param("vjd_div_asn_midi2")
    local vjd_div_asn_crow2 = params:lookup_param("vjd_div_asn_crow2")
    local vjd_div_asn_jf2 = params:lookup_param("vjd_div_asn_jf2")
    local vjd_div_asn_wsyn2 = params:lookup_param("vjd_div_asn_wsyn2")
    local vjd_div_asn_wdelkarp2 = params:lookup_param("vjd_div_asn_wdelkarp2")
    vjd_div_asn_engine2.max = num_divs
    vjd_div_asn_midi2.max = num_divs
    vjd_div_asn_crow2.max = num_divs
    vjd_div_asn_jf2.max = num_divs
    vjd_div_asn_wsyn2.max = num_divs
    vjd_div_asn_wdelkarp2.max = num_divs
  end


  -- params:add{type = "number", id = "rest_pats_per_div", name = "rest pats per div"..i.." rest pat",
  --   min=1, max=8, default=1,
  --   action = function(x)
  --     _menu.rebuild_params()
  -- end}

  -- local rppd = params:get("rest_pats_per_div")
  local rppd = 1
  parameters.rest_pattern_formatters = {}

  params:add_group("rest patterns",(VJD_MAX_DIVISIONS)*rppd)
  for i=1,VJD_MAX_DIVISIONS do
    local rest_formatter = function(x)
      -- tab.print(x)
      local ca_id = x.value
      local ca_rs = vuja_de_rest_patterns[i].get_ruleset()
      local ca_rs_string = vuja_de_rest_patterns[i].get_ruleset_string(ca_rs)
      return ca_rs_string .. " ("..ca_id ..")"
    end
    parameters.rest_pattern_formatters[i] = rest_formatter  

    params:add{type = "number", id = "vuja_de_rest"..i, name = "vjd "..i.." rest pat",
      min=0, max=255, default=255,
      formatter=parameters.rest_pattern_formatters[i],
      action = function(x)
        local rs = vuja_de_rest_patterns[i].set_ruleset(x)
        vuja_de_rest_sequins[i] = Sequins{table.unpack(rs)}
    end}  
  
    if i>params:get("vuja_de_num_divs") then
      params:hide("vuja_de_rest"..i)
    else
      params:show("vuja_de_rest"..i)
    end
  end
  

  --------------------------------
  -- inputs/outputs/midi params
  --------------------------------
  params:add_separator("")
  params:add_separator("INPUTS/OUTPUTS")

  -- sequencing_mode
  params:add{
    type = "option", id = "sequencing_mode", name = "seq mode", 
    options = {"krell","vuja de"},
    default = 1,
    action = function(value) 
      sequencing_mode = value
      engine.switch_sequencing_mode(value)
      if sequencing_mode == 1 then
        -- engine.rise_fall(nil,nil)        
        engine.note_on(notes[math.random(15)],2)
      else
        -- engine.note_on(notes[math.random(15)],2)
        -- krell_rise = rise
        -- krell_fall = fall        
      end
      gui.setup_menu_maps()
  end}
  
  --------------------------------
  -- lorenz x/y output params
  --------------------------------


  local lz_xy_min_action_x = function(x) 
    local val = x
    local current_max_value = params:get("lz_x_max")
    if val > current_max_value then 
      val = current_max_value
      params:set("lz_x_min",val)
    end
  end
  
  local lz_min_cs = cs.new(-5, 10, 'lin', 0, 0, "")
  local lz_max_cs = cs.new(-5, 10, 'lin', 0, 5, "")
  local lz_xy_min_action_y = function(x) 
    local val = x
    local current_min_value = params:get("lz_x_min")
    val = util.clamp(val, current_min_value,val)
    if val < current_min_value then 
      val = current_min_value
      params:set("lz_x_max",val)
    end
  end
  
  local lz_xy_max_action_x = function(x) 
    local val = x
    local current_max_value = params:get("lz_y_max")
    if val > current_max_value then 
      val = current_max_value
      params:set("lz_y_min",val)
    end
  end
  
  local lz_xy_max_action_y = function(x) 
    local val = x
    local current_min_value = params:get("lz_y_min")
    val = util.clamp(val, current_min_value,val)
    if val < current_min_value then 
      val = current_min_value
      params:set("lz_y_max",val)
    end
  end

  local lz_division_cs = cs.new(10, 2000, 'exp', 0, 31.25, "",0.001)
  local lz_division_action_x = function(x)
    lorenz_output_pattern_x:set_division(x/1000)
  end
  
  local lz_division_action_y = function(x)
    lorenz_output_pattern_y:set_division(x/1000)
  end

  local lz_slew_cs = cs.new(0, 2000, 'lin', 0, 31.25, "",0.001)
  local lz_slew_action_x = function(x)
    -- lorenz_output_pattern_x:set_division(x)
  end

  local lz_slew_action_y = function(x)
    -- lorenz_output_pattern_y:set_division(x)
  end

  local lz_xy_cs = cs.new(-5, 10, 'lin', 0, 0.01, "",0.001)

  local lorenz_xy_output_param_data = {
    -- {"option","lz_x_quantize","lz x quantize",{"no","yes",1}},
    -- {"option","lz_y_quantize","lz y quantize",{"no","yes",1}},
    {"control","lz_x_division","lz x division (ms)",lz_division_cs,lz_division_action_x},
    {"control","lz_y_division","lz y division (ms)",lz_division_cs,lz_division_action_y},
    {"control","lz_x_slew","lz x slew (ms)",lz_slew_cs,lz_slew_action_x},
    {"control","lz_y_slew","lz y slew (ms)",lz_slew_cs,lz_slew_action_y},
    {"control","lz_x_min","lz x min (volts)",lz_min_cs,lz_xy_min_action_x},
    {"control","lz_x_max","lz x max (volts)",lz_max_cs,lz_xy_min_action_y},
    {"control","lz_y_min","lz y min (volts)",lz_min_cs,lz_xy_max_action_x},
    {"control","lz_y_max","lz y max (volts)",lz_max_cs,lz_xy_max_action_y},
    {"control","lz_x","lorenz x",lz_xy_cs,nil},
    {"control","lz_y","lorenz y",lz_xy_cs,nil},
  }

  params:add_group("lz x/y outputs",#lorenz_xy_output_param_data)

  for i=1, #lorenz_xy_output_param_data,1 do
    local p_data = lorenz_xy_output_param_data[i]
    if p_data[1] == "number" then
      params:add{
        type=p_data[1], id = p_data[2], name=p_data[3] ,min=p_data[4], max=p_data[5], default = p_data[6],
        action=p_data[7]
      }          
    elseif p_data[1] == "control" then
      params:add{
        type=p_data[1], id = p_data[2], name=p_data[3], controlspec=p_data[4], 
        action=p_data[5]
      }          
    elseif p_data[1] == "option" then
      params:add{
        type=p_data[1], id = p_data[2], name=p_data[3] ,options=p_data[4], default=p_data[5], 
        action=p_data[6]
      }          

    end
  end


  -- quantize notes
  params:add{
    type = "option", id = "quantize", name = "quantize notes", 
    options = {"off","on"},
    default = 2,
    action = function(value) 
  end}
    
    
  -- quantize notes
  params:add_group("envelope params",8)


  params:add{
    type="control", id = "env_max_level", name = "env lvl",
    
    controlspec = controlspec.new(0, 10, "lin", 0.1, ENV_MAX_LEVEL_DEFAULT, ""), 
    action=function(x) 
      engine.env_level(x/10)
    end
  }

  params:add{
    type="number", id = "env_scalar", name = "env sclr",min=100, max=2000, default = 100,
    action=function(x) 
      engine.env_scalar(x/100)
    end
  }
  params:add{
    -- type="number", id = "rise_time", name = "rise (ms)",min=100, step="10", max=2000, default = 100,
    type="control", id = "rise_time", name = "rise (ms)",
    controlspec = controlspec.new(1, 2000, "lin", 1, 100, ""), 
    action=function(x) 
      engine.rise_fall(x/1000,0)
      engine.rise_fall(x/1000,params:get("fall_time")/1000)
    end
  }

  params:add{
    -- type="number", id = "fall_time", name = "fall (ms)",min=100, step="10", max=2000, default = 1000,
    type="control", id = "fall_time", name = "fall (ms)",
    controlspec = controlspec.new(100, 2000, "lin", 1, 100, ""), 
    action=function(x) 
      engine.rise_fall(0,x/1000)
      engine.rise_fall(params:get("rise_time")/1000,x/1000)
    end
  }

  params:add{
    type = "control", id = "env_shape", name = "env shp", 
    -- min=-10,max=10, default = ENV_SHAPE_DEFAULT,
    controlspec = controlspec.new(-10, 10, "lin", 1, 0, ""), 
    action = function(value) 
      engine.env_shape(value)
  end}

  params:add_separator("::read only::")

  params:add{
    type = "control", id = "env_pos", name = "env pos", 
    -- min=-10,max=10, default = ENV_SHAPE_DEFAULT,
    controlspec = controlspec.new(0, 1, "lin", 0.0001, 0, "", 0.0001), 
    action = function(value) 
      -- print("env pos param",value)
  end}

  params:add{
    type = "control", id = "env_level", name = "env level", 
    -- min=-10,max=10, default = ENV_SHAPE_DEFAULT,
    controlspec = controlspec.new(0, 1, "lin", 0.0001, 0, "", 0.0001), 
    action = function(value) 
      -- print("env level param",value)
  end}

  --------------------------------
  -- engine (rings & karplus strong) params
  --------------------------------
  function parameters.set_engine_params(param_data)
    for i=1, #param_data,1 do
      local p_data = param_data[i]
      -- print(p_data[1], p_data[2], p_data[3] ,p_data[4], p_data[5], p_data[6])
      params:add{
        type=p_data[1], id = p_data[2], name=p_data[3] ,min=p_data[4], max=p_data[5], default = p_data[6],  
        action=function(x) 
          local base, range, min, max
          if string.find(p_data[2],"_range")~=nil then
            range = x
            base = params:get(param_data[i-1][2])
            min = util.clamp(base-range,0,1)
            max = util.clamp(base+range,0,1)
            local engine_min = engine[p_data[7].."_min"]
            local engine_max = engine[p_data[7].."_max"]
            engine_min(min)
            engine_max(max)
          elseif string.find(p_data[2],"_base")~=nil then
            base = x
            range = params:get(param_data[i+1][2])
            min = util.clamp(base-range,0,1)
            max = util.clamp(base+range,0,1)
            local engine_min = engine[p_data[7].."_min"]
            local engine_max = engine[p_data[7].."_max"]
            engine_min(min)
            engine_max(max)
          else
            local engine_command = engine[p_data[2]]
            engine_command(x)
          end
        end
      }          
    end
  end

    --rings params
    local rings_param_data = {
      {"taper","rings_pos","pos",0,1,0.05},
      {"taper","rings_structure_base","str",0,1,0.2,"rings_structure"},
      {"taper","rings_structure_range","str rng",0,1,0,"rings_structure"},
      {"taper","rings_brightnes_base","brt",0,1,0.3,"rings_brightness"},
      {"taper","rings_brightness_range","brt rng",0,1,0,"rings_brightness"},
      {"taper","rings_damping_base","dmp",0,1,0.675,"rings_damping"},
      {"taper","rings_damping_range","dmp rng",0,1,0,"rings_damping"},
      {"number","rings_poly","poly",1,4,1},
    }
  
  
    params:add_group("rings",#rings_param_data + 3)
  
  params:add{
    type = "number", id = "rings_easter_egg", name = "egg mode", 
    min=0,max=1,default=0,
    action = function(value) 
      engine.rings_easter_egg(value)

      local engine_mode = params:lookup_param("engine_mode")
      if value == 0 then  
        --[[ 
          regular mode:
          0: MODAL_RESONATOR, 
          1: SYMPATHETIC_STRING, 
          2: MODULATED/INHARMONIC_STRING, 
          3: 2-OP_FM_VOICE, 
          4: SYMPATHETIC_STRING_QUANTIZED, 
          5: STRING_AND_REVERB
          --]]
        engine_mode.options = {"res","sstr","mstr","fm","sstrq","strr"}
      else
        --[[
          easter egg mode:
          0: FX_FORMANT, 
          1: FX_CHORUS, 
          2: FX_REVERB, 
          3: FX_FORMANT, 
          4: FX_ENSEMBLE, 
          5: FX_REVERB
        ]]
        engine_mode.options = {"for","chor","rev","for2","ens","rev2"}
      end
      _menu.rebuild_params()
      gui.setup_menu_maps()
  end}

  params:add{
    type = "option", id = "engine_mode", name = "eng mode", 
    options = {"res","sstr","mstr","fm","sstrq","strr"},
    default = 1,
    action = function(value) 
      engine.engine_mode(value-1)
      gui.setup_menu_maps()
  end}


  params:add{
    type = "option", id = "rings_triger_mode", name = "trig mode", 
    options = {"internal","external"},
    default = 1,
    action = function(value) 
      engine.trigger_mode(value-1)
      if value == 1 then
        if params:get("internal_trigger_type") < 3 then
            engine.internal_exciter(0)
        else
          engine.internal_exciter(1)
        end
      else
        engine.internal_exciter(0)
      end
  end}

  params:hide("rings_triger_mode")

  params:add{
    type = "option", id = "internal_trigger_type", name = "trig type", 
    options = {"snare","bass","built-in", "external"},
    default = 1,
    action = function(value) 
      if value < 3 then
        engine.trigger_type(value-1)
        engine.internal_exciter(0)
        params:set("rings_triger_mode",1)
      elseif value == 3 then
        engine.internal_exciter(1)
        params:set("rings_triger_mode",1)
      else
        params:set("rings_triger_mode",2)
        engine.internal_exciter(0)
      end
  end}

  parameters.set_engine_params(rings_param_data)
  
  params:add_group("midi",9)


  -- params:add_separator("midi in")

  -- midi_in_device = {}
  -- params:add{
  --   type = "option", id = "midi_in_device", name = "in device", options = midi_devices, 
  --   min = 1, max = 16, 
  --   -- default = 1, 
  --   action = function(value)
  --     midi_in_device.event = nil
  --     midi_in_device = midi.connect(value)
  --     midi_in_device.event = midi_event
  --   end
  -- }

  -- params:add{
  --   type = "number", id = "midi_in_channel1", name = "midi_in channel1",
  --   min = 1, max = 16, default = midi_in_channel1_default,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_in_command1 = value + 143
  --   end
  -- }
    
  params:add_separator("midi out")

  params:add{type = "option", id = "output_midi", name = "midi notes out",
    options = {"off","on"},
    default = 2,
  }
  
  params:add{
    type = "option", id = "midi_out_device", name = "out device", options = midi_devices,
    default = 1,
    action = function(value) 
      midi_out_device = midi.connect(value-1) 
    end
  }

  params:add{type = "option", id = "play_midi_cc_lz_x", name = "midi lz cc x out",
    options = {"off","on"},
    default = 1,
  }
  params:add{type = "option", id = "play_midi_cc_lz_y", name = "midi lz cc y out",
    options = {"off","on"},
    default = 1,
  }

  params:add{type = "number", id = "play_midi_cc_lz_x_cc", name = "midi lz x cc",
  min=0,max=127,default=100,
  action=function() end
}

params:add{type = "number", id = "play_midi_cc_lz_y_cc", name = "midi lz y cc",
  min=0,max=127,default=101,
  action=function() end
}


  params:add{type = "number", id = "play_midi_cc_lz_x_chan", name = "midi lz x chan",
    min=0,max=16,default=1,
    action=function() end
  }

  params:add{type = "number", id = "play_midi_cc_lz_y_chan", name = "midi lz y chan",
    min=0,max=16,default=2,
    action=function() end
  }

  
  midi_helper.get_midi_devices()


  -- params:add{type = "number", id = "midi_pitch_offset", name = "note offset",
  --   min = 0, max = 100, default = midi_pitch_offset,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_pitch_offset = value
  --   end
  -- }
  -- crow
  params:add_group("crow",4)


  --override the built in crow clock action
  params:set_action("clock_crow_out", function(x)
    --if x>1 then crow.output[x-1].action = "pulse(0.01,8)" end
    norns.state.clock.crow_out = x
    for i=1,4,1 do 
      if i ~= x-1 then
      params:show("output_crow".. i)
      end
    end
    if x>1 then 
      params:hide("output_crow".. x-1)
    end
    _menu.rebuild_params()
  end)
  for i=1,4,1 do
    local c_default
    if i==1 then
      c_default = 2
    elseif i==2 then
      c_default = 3
    elseif i==3 then
      c_default = 6
    elseif i==4 then
      c_default = 7
    end
    params:add{type = "option", id = "output_crow"..i, name = "crow out ".. i .." mode",
      -- options = {"off","on"},
      -- options = {"off","on"},
      options = {"off","lz note","envelope","trigger","gate","lz x voltage", "lz y voltage", "mod matrix"},

      default = c_default,
      action = function(value)
      end
    }
  end
  -- just friends
  params:add_group("just friends",8)
  params:add{type = "option", id = "output_jf", name = "just friends",
    options = {"off","on"},
    default = 2,
    action = function(value)
      if value > 1 then 
        -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.ii.pullup(true)
        crow.ii.jf.mode(value)
      else
        crow.ii.jf.mode(0)
        -- crow.ii.pullup(false)
      end
    end
  }

  params:add{type = "option", id = "jf_mode", name = "just friends mode",
    options = {"mono","poly","port"},
    default = 1,
    action = function(value)
      -- if value == 2 then 
      --   -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
      --   crow.ii.pullup(true)
      --   crow.ii.jf.mode(1)
      -- else 
      --   crow.ii.jf.mode(0)
      --   -- crow.ii.pullup(false)
      -- end
    end
  }


  params:add { type = "number", id = "jf_pitch_interval1", name = "pitch interval 1", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }
  params:add { type = "number", id = "jf_pitch_interval2", name = "pitch interval 2", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }
  params:add { type = "number", id = "jf_pitch_interval3", name = "pitch interval 3", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }
  params:add { type = "number", id = "jf_pitch_interval4", name = "pitch interval 4", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }
  params:add { type = "number", id = "jf_pitch_interval5", name = "pitch interval 5", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }
  params:add { type = "number", id = "jf_pitch_interval6", name = "pitch interval 6", min=-24, max=24, default = 0, 
  -- controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"), 
    action = function(val) 
    end
  }


  params:add_group("w/syn",17)
  w_slash.wsyn_add_params()
  -- w_slash.wsyn_v2_add_params()

  params:add_group("w/del",15)
  w_slash.wdel_add_params()

  params:add_group("w/tape",17)
  w_slash.wtape_add_params()


end

return parameters