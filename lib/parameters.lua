local parameters = {}

function parameters.init()

  --------------------------------
  -- SCALES, NOTES, AND TEMPO
  -- scale: the scale to use
  -- scale length: the number of notes in the scale, centered around the `note_offset`
  -- root note: the lowest note in the scale
  -- note_offset: the note to use as "1" in the sequencer
  --------------------------------

  function parameters.update_note_offset()
    local offset = params:lookup_param("note_offset")
    local offset_options = {}
    for k,v in pairs(notes) do 
      if v then
        table.insert(offset_options,MusicUtil.note_num_to_name(v,true))
      end
    end
    offset.options = offset_options
    offset.count = #offset_options
  end

  params:add_separator("SCALES, NOTES, AND TEMPO")
  -- params:add_group("scales and notes",5)

  
  params:add{type = "number", id = "num_octaves", name = "num octaves", min=1,max=7,default=2,
    action = function(val) 
      fn.build_scale() 
      parameters.update_note_offset()
      -- local sl = params:lookup_param("scale_length")
      -- sl.maxval = fn.get_num_notes_per_octave() * val
  end}
  
  -- print(fn.get_num_notes_per_octave(),params:get("num_octaves"))
  -- local max_notes = fn.get_num_notes_per_octave() * params:get("num_octaves")
  -- -- local max_notes = fn.get_num_notes_per_octave() and fn.get_num_notes_per_octave() * 5 or SCALE_LENGTH_DEFAULT

  -- params:add{type = "number", id = "scale_length", name = "scale length",
  --   min = 1, max = max_notes, default = ROOT_NOTE_DEFAULT, 
  --   action = function(val) 
  --     fn.build_scale() 
  --     parameters.update_note_offset()
  --     local sl = params:lookup_param("scale_length")
  --     sl.maxval = fn.get_num_notes_per_octave() * 5
  -- end}

  -- params:hide("scale_length")

  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5,
    action = function() 
      fn.build_scale() 
      if initializing == false then 
        parameters.update_note_offset()
      end
  end}

  
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = ROOT_NOTE_DEFAULT, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() 
      fn.build_scale() 
      parameters.update_note_offset()
  end}

  params:add{type = "number", id = "note_offset", name = "note offset",
    min = -24, max = 24, default = 0, 
    action = function() 
      fn.build_scale() 
      parameters.update_note_offset()
  end}

  params:hide("note_offset")

  --------------------------------
  -- lorenz params
  --------------------------------
  params:add_separator("LORENZ")
  params:add_group("lorenz",19)
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
  -- inputs/outputs/midi params
  --------------------------------
  params:add_separator("inputs/outputs")
  -- params:add_group("inputs/outputs",17+14)
  -- params:add{type = "option", id = "output_bandsaw", name = "bandsaw (eng)",
  -- options = {"off","engine", "midi", "engine + midi"},
  -- default = 2,
  -- }

  -- engine_mode
  params:add{
    type = "option", id = "engine_mode", name = "eng mode", 
    options = {"krell","other"},
    default = 1,
    action = function(value) 
      engine_mode = value
      engine.switch_mode(value)
      if engine_mode == 1 then
        engine.play_note(notes[math.random(15)])
      end
  end}

  params:add{
    type="taper", id = "rise", name = "rise",min=0.01, max=5, default = 1,
    action=function(x) 
      engine.rise_fall(x,0)
    end
  }

  params:add{
    type="taper", id = "fall", name = "fall",min=0.01, max=5, default = 1,
    action=function(x) 
      engine.rise_fall(0,x)
    end
  }

  -- midi
  params:add{
    type = "option", id = "quantize", name = "quantize", 
    options = {"on","off"},
    default = 1,
    action = function(value) 
    end}

  params:add_group("midi",11)

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

  params:add{
    type = "number", id = "midi_in_channel1", name = "midi_in channel1",
    min = 1, max = 16, default = midi_in_channel1_default,
    action = function(value)
      -- all_notes_off()
      midi_in_command1 = value + 143
    end
  }
    
  -- params:add{type = "number", id = "plant2_cc_channel", name = "plant 2:midi in channel",
  --   min = 1, max = 16, default = plant2_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_in_command2 = value + 143
  --   end
  -- }

  params:add{
    type = "number", id = "envelope1_cc_channel", name = "env 1:midi cc channel",
    min = 1, max = 16, default = envelope1_cc_channel,
    action = function(value)
      -- all_notes_off()
      envelope1_cc_channel = value
    end
  }

  params:add{
    type = "number", id = "envelope2_cc_channel", name = "env 2:midi cc channel",
    min = 1, max = 16, default = envelope2_cc_channel,
    action = function(value)
      -- all_notes_off()
      envelope2_cc_channel = value
    end
  }

  -- params:add{
  --   type = "number", id = "water_cc_channel", name = "water:midi cc channel",
  --   min = 1, max = 16, default = water_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     water_cc_channel = value
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

  get_midi_devices()

  -- crow
  params:add_group("crow",6)


  params:add{
    type="taper", id = "env_length", name = "env length",min=0.01, max=0.5, default = 0.1,
    action=function(x) 
    end
  }

  params:add{
    type="taper", id = "env_max_level", name = "env max level",min=0, max=10, default = 10,
    action=function(x) 
    end
  }



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
  params:add_group("just friends",2)
  params:add{type = "option", id = "output_jf", name = "just friends",
    options = {"off","on"},
    default = 2,
    action = function(value)
      if value > 1 then 
        -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      else
        crow.ii.jf.mode(0)
        -- crow.ii.pullup(false)
      end
    end
  }

  params:add{type = "option", id = "jf_mode", name = "just friends mode",
    options = {"mono","poly","port"},
    default = 2,
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


  params:add_group("w/syn",13)
  w_slash.wsyn_add_params()
  -- w_slash.wsyn_v2_add_params()

  params:add_group("w/del",15)
  w_slash.wdel_add_params()

  params:add_group("w/tape",17)
  w_slash.wtape_add_params()


end

return parameters