-- external sounds and outputs

local externals = {}
externals.__index = externals

function externals:new()
  local ext = {}
  ext.index = 1
  setmetatable(ext, externals)
  return ext
end
  

function externals.set_midi_cc(cc,note_tab,channel)
  midi_out_device:cc (cc, note_tab, channel)
end

externals.midi_note_off = function(delay, note_num, channel, voice_id, note_location)
  local note_off_delay
  if voice_id == 1 then
    note_off_delay = midi_out_envelope_override1 or delay
  elseif voice_id == 2 then
    note_off_delay = midi_out_envelope_override2 or delay
  end
  clock.sleep(note_off_delay)
  if note_location <= #active_notes then
    table.remove(active_notes, note_location)
  end
  midi_out_device:note_off(note_num, nil, channel)
end

externals.midi_note_off_beats = function(delay, note_num, channel, voice_id, note_location)
  clock.sync(delay)
  if note_location <= #active_notes then
    table.remove(active_notes, note_location)
  else
    --note location is out of bounds!!!
  end
  midi_out_device:note_off(note_num, nil, channel)
end

externals.note_on = function(voice_id, note_tab, target)
  
  -- local note_offset = params:get("note_offset") - params:get("root_note")
  -- local note_tab = fn.deep_copy(note_tab)
  -- tab.print(note_tab)
  if initializing == false then
    if type(note_tab) == "table" and note_tab.pitch then
      note_tab.pitch = util.clamp(note_tab.pitch,1,#notes)
      if params:get("quantize") == 2 then          
        note_tab.pitch = fn.quantize(note_tab.pitch)
      end
    end

    
    -- local envelope_length = envelopes[voice_id].get_env_time()

    -- MIDI out
    local output_midi = params:get("output_midi")
    if (target == "midi" and output_midi == 2) then
      local mode = note_tab.mode and note_tab.mode or 1
      if mode == 1 then -- play_voice
        local channel = note_tab.channel and note_tab.channel or 1
        local pitch = note_tab.pitch
        local velocity = note_tab.velocity and note_tab.velocity or 80
        local duration = note_tab.duration and note_tab.duration or 0.25
        duration = tonumber(duration) and duration or fn.fraction_to_decimal(duration)    
        midi_out_device:note_on(pitch, velocity, channel)
        table.insert(active_notes, pitch)
        clock.run(externals.midi_note_off_beats, duration, pitch, channel, 1, #active_notes)
      elseif mode == 2 then -- stop/start
        if note_tab.stop_start == 1 then -- stop
          midi_out_device:stop()
        else -- start
          midi_out_device:start()
        end
      end
    end
    


    local function get_envelope_data() 
      local data = {}
      data.segments =	 3
      data.curves   =	 {0,10,0}
      -- curves   =	 {0,-10,-10},
      data.levels	 =   {0,params:get("env_max_level"),0}
      data.times	   =   {0,rise,fall}
      
      return data
    end

    -- crow out
    local output_crow1 = params:get("output_crow1")
    local output_crow2 = params:get("output_crow2")
    local output_crow3 = params:get("output_crow3")
    local output_crow4 = params:get("output_crow4")

    local asl_generator = function(env_length)
      local envelope_data = get_envelope_data()
      local asl_envelope = ""
      for i=2, envelope_data.segments, 1
      do
        local to_env 
        if envelope_data.curves[i] > 0 then to_env = 'exponential'
        elseif envelope_data.curves[i] < 0 then to_env = 'logarithmic'
        else to_env = 'linear'
        end
        
        local to_string =  "to(" .. 
                          (envelope_data.levels[i]) .. "," ..
                          (envelope_data.times[i]-envelope_data.times[i-1]) .. 
                          "," .. to_env .. 
                          "),"
                          asl_envelope = asl_envelope .. to_string

        if i == envelope_data.segments then
          local to_string = "to(" .. 
                            (envelope_data.levels[i]) .. "," ..
                            (envelope_data.times[i]) .. 
                            -- (env_length-envelope_data.times[i]) .. 
                            "," .. to_env .. 
                            "),"
                            asl_envelope = asl_envelope .. to_string
        end
      end
    
      asl_envelope = "{" .. asl_envelope .. "}"
      return asl_envelope 
    end

    -- clock out check
    if output_crow1 == 5 then 
      crow.output[1]:execute() 
    elseif output_crow2 == 5 then 
      crow.output[2]:execute() 
    elseif output_crow3 == 5 then 
      crow.output[3]:execute() 
    elseif output_crow4 == 5 then 
      crow.output[4]:execute() 
    end

    -- note, trigger, envelope, gate check
    if (voice_id == 1 and target == "crow") and 
       (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4)
    then
      local volts = (note_tab.pitch-60)/12
      crow.output[1].volts = volts 
      if output_crow2 == 2 then -- envelope
        local asl_envelope = asl_generator()
        -- local asl_envelope = asl_generator(params:get("env_length"))
        crow.output[2].action = tostring(asl_envelope)
      elseif output_crow2 == 3 then -- trigger
        local time = 0.01 --crow_trigger_2
        local level = params:get("env_max_level")
        local polarity = 1
        crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_crow2 == 4 then -- gate
        local num_env_controls = #envelope_data.times
        local time = envelope_data.times[num_env_controls]
        -- local time = params:get("envelope1_max_time")
        local level = params:get("env_max_level")
        local polarity = 1
        if (time and level and polarity) then 
          crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        end
      end
      if output_crow2 > 1 then crow.output[2]() end
      crow.output[1].execute()

    end

    -- just friends out 
    local output_jf = params:get("output_jf")
    local jf_mode = params:get("jf_mode")

    if (target == "jf" and output_jf == 2) then
      local pitch = note_tab.pitch
      local level = note_tab.level
      local channel = note_tab.channel and note_tab.channel or 1
      if jf_mode == 1 then -- play_note
        crow.ii.jf.play_note((pitch-60)/12,level)
      elseif jf_mode == 2 then -- play_voice
        local channel = channel
        crow.ii.jf.play_voice(channel,(pitch-60)/12,level)
      else
        crow.ii.jf.pitch(1,(note_tab-60)/12)
      end
    end

    -- wsyn out
    local output_wsyn = params:get("output_wsyn")
    local output_wdel_ks = params:get("output_wdel_ks")

    -- wsyn out
    if (target == "wsyn" and output_wsyn == 2) then
      local pitch = (note_tab.pitch-60)/12
      local velocity = params:get("env_max_level") 
      local voice = voice_id
      crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
    end

    -- wdel - karplus-strong out
    if ( target == "wdel_ks" and output_wdel_ks == 2) then
      local pitch = (note_tab.pitch-60)/12
      -- local level = voice_id == 1 and params:get("env_max_level") or params:get("envelope2_max_level") 
      local level = params:get("env_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end
  end
end

return externals
