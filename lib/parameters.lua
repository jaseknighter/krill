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

  params:add_separator("SCALES, NOTES, AND TEMPO")
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
    type="number", id = "x_offset", name = "x offset",min=-64, max=64, default = 0,
    action=function(x) 
      -- lorenz:reset()
      screen:clear()
    end
  }
  params:add{
    type="number", id = "y_offset", name = "y offset",min=-32, max=32, default = 0,
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


  params:add_group("lorenz params",13)
  
  params:add{
    type="number", id = "lz_speed", name = "lz_speed", min=0,max=100,default = 80,
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
    type="taper", id = "beta", name = "beta",min=0.01, max=2, default = 4/3,
    action=function(x) 
      lorenz.beta=x
      --lorenz:reset()
    end
  }

  params:add{
    type="taper", id = "state1", name = "state1",min=0.000, max=2, default = 0.1,
    action=function(x) 
      lorenz.state[1]=x
      --lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "state2", name = "state2",min=0.000, max=2, default = 0.0,
    action=function(x) 
      lorenz.state[3]=x
      --lorenz:reset()
    end
  }
  
  params:add{
    type="taper", id = "state3", name = "state3",min=0.000, max=2, default = 0.0,
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
  options = {"hide","show"}, default = 2,
  action = function(x)
    if x == 1 then screen.clear() end 
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

  params:add{type = "number", id = "vuja_de_prob", name = "vjd pat",
  min=-10, max=10, default=-5,
  action = function(x)
  end}

  parameters.setting_patterns = false
  params:add{type = "number", id = "vuja_de_num_pats", name = "vjd num patterns",
  min=1, max=VJD_MAX_PATTERNS, default=3,
  action = function(x)
    -- if parameters.setting_patterns == false then
    --   parameters.setting_patterns = true
      parameters.set_pats(x)
      _menu.rebuild_params()
      -- parameters.setting_patterns = false
    -- end
  end}


  params:add_group("vjd pat asgn/div/jit",12+3+(VJD_MAX_PATTERNS*3))
  params:add_separator("assignments")
  params:add{type = "number", id = "vjd_pat_asn_engine1", name = "engine asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_engine2", name = "engine asn 2", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_midi1", name = "midi asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_midi2", name = "midi asn 2", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_crow1", name = "crow asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_crow2", name = "crow asn 2", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_jf1", name = "jf asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_jf2", name = "jf asn 2", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_wsyn1", name = "wsyn asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_wsyn2", name = "wsyn asn 2", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_wdelkarp1", name = "wdelkarp asn 1", min=1, max=3, default=1}
  params:add{type = "number", id = "vjd_pat_asn_wdelkarp2", name = "wdelkarp asn 2", min=1, max=3, default=1}
  
  params:add_separator("")
  params:add_separator("divisions")
  for i=1,VJD_MAX_PATTERNS,1 do
    -- params:add_separator("pattern "..i)
    params:add{ type = "option", id = "pat_lab"..i, name = "---------- pattern " .. i .. " ----------",  options = {" "}}
    params:add{type = "number", id = "vuja_de_pat_numerator"..i, name = "vjd pat num"..i,
      min=1, max=VJD_MAX_PATTERN_NUMERATOR, default=1,
      action = function(x)
        vuja_de_patterns[i]:set_division(x/params:get("vuja_de_pat_denominator"..i))
    end}

    params:add{type = "number", id = "vuja_de_pat_denominator"..i, name = "vjd pat den"..i,
      min=1, max=VJD_MAX_PATTERN_DENOMINATOR, default=1,
      action = function(x)
        vuja_de_patterns[i]:set_division(params:get("vuja_de_pat_numerator"..i)/x)
    end}

    if i>3 then
      params:hide("vuja_de_pat_numerator"..i)
      params:hide("vuja_de_pat_denominator"..i)
      params:hide("pat_lab"..i)
      
    end
      
  end

  function parameters.set_pats(num_pats)    
    for i=1,VJD_MAX_PATTERNS,1 do
      if i>num_pats then
        params:hide("vuja_de_pat_numerator"..i)
        params:hide("vuja_de_pat_denominator"..i)
        params:hide("pat_lab"..i)
      else
        params:show("vuja_de_pat_numerator"..i)
        params:show("vuja_de_pat_denominator"..i)    
        params:show("pat_lab"..i)    
      end
    end

    if params:get("vjd_pat_asn_midi1") > num_pats then 
      params:set("vjd_pat_asn_midi1",1)
    end
    if params:get("vjd_pat_asn_crow1") > num_pats then 
      params:set("vjd_pat_asn_crow1",1)
    end
    if params:get("vjd_pat_asn_jf1") > num_pats then 
      params:set("vjd_pat_asn_jf1",1)
    end
    if params:get("vjd_pat_asn_wsyn1") > num_pats then 
      params:set("vjd_pat_asn_wsyn1",1)
    end
    if params:get("vjd_pat_asn_wdelkarp1") > num_pats then 
      params:set("vjd_pat_asn_wdelkarp1",1)
    end

    if params:get("vjd_pat_asn_midi2") > num_pats then 
      params:set("vjd_pat_asn_midi2",1)
    end
    if params:get("vjd_pat_asn_crow2") > num_pats then 
      params:set("vjd_pat_asn_crow2",1)
    end
    if params:get("vjd_pat_asn_jf2") > num_pats then 
      params:set("vjd_pat_asn_jf2",1)
    end
    if params:get("vjd_pat_asn_wsyn2") > num_pats then 
      params:set("vjd_pat_asn_wsyn2",1)
    end
    if params:get("vjd_pat_asn_wdelkarp2") > num_pats then 
      params:set("vjd_pat_asn_wdelkarp2",1)
    end

    local vjd_pat_asn_midi1 = params:lookup_param("vjd_pat_asn_midi1")
    local vjd_pat_asn_crow1 = params:lookup_param("vjd_pat_asn_crow1")
    local vjd_pat_asn_jf1 = params:lookup_param("vjd_pat_asn_jf1")
    local vjd_pat_asn_wsyn1 = params:lookup_param("vjd_pat_asn_wsyn1")
    local vjd_pat_asn_wdelkarp1 = params:lookup_param("vjd_pat_asn_wdelkarp1")
    vjd_pat_asn_midi1.max = num_pats
    vjd_pat_asn_crow1.max = num_pats
    vjd_pat_asn_jf1.max = num_pats
    vjd_pat_asn_wsyn1.max = num_pats
    vjd_pat_asn_wdelkarp1.max = num_pats

    local vjd_pat_asn_midi1 = params:lookup_param("vjd_pat_asn_midi1")
    local vjd_pat_asn_crow1 = params:lookup_param("vjd_pat_asn_crow1")
    local vjd_pat_asn_jf1 = params:lookup_param("vjd_pat_asn_jf1")
    local vjd_pat_asn_wsyn1 = params:lookup_param("vjd_pat_asn_wsyn1")
    local vjd_pat_asn_wdelkarp1 = params:lookup_param("vjd_pat_asn_wdelkarp1")
    vjd_pat_asn_midi1.max = num_pats
    vjd_pat_asn_crow1.max = num_pats
    vjd_pat_asn_jf1.max = num_pats
    vjd_pat_asn_wsyn1.max = num_pats
    vjd_pat_asn_wdelkarp1.max = num_pats
  end



  
  --------------------------------
  -- resonator params
  --------------------------------

  -- exciter_decay_min
  -- exciter_decay_max
  -- resonator_pos
  -- resonator_resolution
  -- resonator_structure
  -- resonator_brightness_min
  -- resonator_brightness_max
  -- resonator_damping_min
  -- resonator_damping_max
  local resonator_param_data = {
    --Rings params
    -- {"taper","exciter_decay_min","decay_min",0,1,0.1},
    -- {"taper","exciter_decay_max","decay_max",0,1,0.5},
    -- {"taper","resonator_pos","pos",0,1,0.0},
    -- {"taper","resonator_structure","structure",0,1,0.01},
    -- {"taper","resonator_brightness_min","brightness_min",0,1,0.6},
    -- {"taper","resonator_brightness_max","brightness_max",0,1,0.99},
    -- {"taper","resonator_damping_min","damping_min",0,1,0.5},
    -- {"taper","resonator_damping_max","damping_max",0,1,0.5},

    -- rongs params
    {"taper","exciter_decay_min","decay",0,1,0.315},
    {"taper","resonator_structure_min","structure",0,1,0.315},
    {"taper","resonator_brightness_min","brightness",0,1,0.0},
    {"taper","resonator_damping_min","damping",0,1,0.0},
    {"taper","resonator_accent_min","accent",0,1,0.756},
    {"taper","resonator_stretch_min","stretch",0,1,0.339},
    {"taper","resonator_loss_min","loss",0,1,0.307},
    {"taper","resonator_pos","pos",0,1,0.134},
  }

  params:add_separator("resonators")
  params:add_group("resonator",8)

  for i=1, #resonator_param_data,1 do
    local p_data = resonator_param_data[i]
    params:add{
      type=p_data[1], id = p_data[2], name=p_data[3] ,min=p_data[4], max=p_data[5], default = p_data[6],
      action=function(x) 
        local val = x
        -- if string.find(p_data[2],"_min")~=nil then
        --   local current_max_value = params:get(resonator_param_data[i+1][2])
        --   if val > current_max_value then 
        --     val = current_max_value
        --     params:set(p_data[2],val)
        --   end
        -- elseif string.find(p_data[2],"_max")~=nil then
        --   local current_min_value = params:get(resonator_param_data[i-1][2])
        --   val = util.clamp(val, current_min_value,val)
        --   if val < current_min_value then 
        --     val = current_min_value
        --     params:set(p_data[2],val)
        --   end
        -- end
        local engine_command = engine[p_data[2]]
        engine_command(val)
      end
    }          
  end


  --------------------------------
  -- inputs/outputs/midi params
  --------------------------------
  params:add_separator("inputs/outputs")
  -- params:add_group("inputs/outputs",17+14)
  -- params:add{type = "option", id = "output_bandsaw", name = "bandsaw (eng)",
  -- options = {"off","engine", "midi", "engine + midi"},
  -- default = 2,
  -- }

  -- params:add{
  --   type="taper", id = "env_length", name = "env length",min=0.01, max=0.5, default = 0.1,
  --   action=function(x) 
  --   end
  -- }

  params:add{
    type="taper", id = "env_max_level", name = "env max level",min=0, max=10, default = 10,
    action=function(x) 
    end
  }


  -- engine_mode
  params:add{
    type = "option", id = "engine_mode", name = "eng mode", 
    options = {"krell","vuja de"},
    default = 1,
    action = function(value) 
      engine_mode = value
      engine.switch_mode(value)
      if engine_mode == 1 then
        engine.play_note(notes[math.random(15)],2)
        if krell_rise then
          engine.rise_fall(krell_rise,krell_fall)
          krell_rise = nil
          krell_fall = nil
        end
        sub_menu_map = sub_menu_map_krell
      else
        -- engine.play_note(notes[math.random(15)],2)
        krell_rise = rise
        krell_fall = fall
        sub_menu_map = sub_menu_map_vuja_de
      end
  end}

  params:add{
    type="number", id = "env_scalar", name = "env sclr",min=10, max=200, default = 100,
    action=function(x) 
      engine.env_scalar(x/100)
    end
  }

  -- params:add_control("rise_time", "rise time", controlspec.new(10,200,'lin',1,10))
  -- params:set_action("rise_time", function(x) 
  --   engine.rise_fall(x/100,0) 
  -- end )

  -- params:add_control("fall_time", "fall time", controlspec.new(10,200,'lin',1,50))
  -- params:set_action("fall_time", function(x) 
  --   engine.rise_fall(0,x/100) 
  -- end )


  params:add{
    type="number", id = "rise_time", name = "rise time",min=10, max=200, default = 10,
    action=function(x) 
      engine.rise_fall(x/100,0)
    end
  }

  params:add{
    type="number", id = "fall_time", name = "fall time",min=10, max=200, default = 100,
    action=function(x) 
      engine.rise_fall(0,x/100)
    end
  }

  params:add{
    type = "number", id = "env_shape", name = "env shape", 
    min=-10,max=10,
    default = 3,
    action = function(value) 
      engine.env_shape(value)
  end}

  -- midi
  params:add{
    type = "option", id = "quantize", name = "quantize", 
    options = {"off","on"},
    default = 2,
    action = function(value) 
    end}

  params:add_group("midi",8)

  -- params:add{type = "option", id = "midi_engine_control", name = "midi engine control",
  --   options = {"off","on"},
  --   default = 2,
  --   -- action = function(value)
  --   -- end
  -- }

  local midi_devices = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

  params:add_separator("midi in")

  midi_in_device = {}
  params:add{
    type = "option", id = "midi_in_device", name = "in device", options = midi_devices, 
    min = 1, max = 16, default = 1, 
    action = function(value)
      midi_in_device.event = nil
      midi_in_device = midi.connect(value)
      midi_in_device.event = midi_event
    end
  }

  -- params:add{
  --   type = "number", id = "midi_in_channel1", name = "midi_in channel1",
  --   min = 1, max = 16, default = midi_in_channel1_default,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_in_command1 = value + 143
  --   end
  -- }
    
  -- params:add{
  --   type = "number", id = "envelope1_cc_channel", name = "env 1:midi cc channel",
  --   min = 1, max = 16, default = envelope1_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     envelope1_cc_channel = value
  --   end
  -- }

  -- params:add{
  --   type = "number", id = "envelope2_cc_channel", name = "env 2:midi cc channel",
  --   min = 1, max = 16, default = envelope2_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     envelope2_cc_channel = value
  --   end
  -- }

  params:add_separator("midi out")

  params:add{type = "option", id = "output_midi", name = "midi out",
    options = {"off","on"},
    default = 2,
  }

  params:add{
    type = "option", id = "midi_out_device", name = "out device", options = midi_devices,
    default = 1,
    action = function(value) 
      midi_out_device = midi.connect(value) 
    end
  }

  params:add{
    type = "option", id = "midi_note1_mode", name = "midi note 1 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        -- sequencer_controller.refresh_output_control_specs_map()
      end
    end
  }

  params:add{
    type = "option", id = "midi_note2_mode", name = "midi note 2 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        -- sequencer_controller.refresh_output_control_specs_map()
      end
    end
  }

  params:add{
    type = "option", id = "midi_note3_mode", name = "midi note 3 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        -- sequencer_controller.refresh_output_control_specs_map()
      end
    end
  }

  -- params:add{
  --   type = "number", id = "midi_out_channel1", name = "plant 1:midi out channel",
  --   min = 1, max = 16, default = midi_out_channel1,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_out_channel1 = value
  --   end
  -- }
    
  -- params:add{type = "number", id = "midi_out_channel2", name = "plant 2:midi out channel",
  --   min = 1, max = 16, default = midi_out_channel2,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_out_channel2 = value
  --   end
  -- }

  -- params:add{type = "number", id = "midi_pitch_offset", name = "note offset",
  --   min = 0, max = 100, default = midi_pitch_offset,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_pitch_offset = value
  --   end
  -- }

  get_midi_devices()

  -- crow
  params:add_group("crow",4)


  params:add{type = "option", id = "output_crow1", name = "crow out1 mode",
    -- options = {"off","on"},
    options = {"off","on"},
    default = 2,
    action = function(value)
    end
  }

  params:add{type = "option", id = "output_crow2", name = "crow out2 mode",
    options = {"off","envelope","trigger","gate","clock"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.output[2].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow3", name = "crow out3 mode",
    options = {"off","on"},
    default = 2,
    action = function(value)
    end
  }

  params:add{type = "option", id = "output_crow4", name = "crow out4 mode",
    options = {"off","envelope","trigger","gate", "clock"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then 
        crow.output[4].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

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