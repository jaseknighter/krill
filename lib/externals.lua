-- external sounds and outputs

local externals = {}
externals.__index = externals

function externals:new()
  local ext = {}
  ext.index = 1
  setmetatable(ext, externals)
  return ext
end
  

function externals.set_midi_cc(cc,cc_val,cc_channel)
  if midi_out_device then
    midi_out_device:cc (cc, cc_val, cc_channel)
  end
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
  if midi_out_device then
    midi_out_device:note_off(note_num, nil, channel)
  end
end

externals.midi_note_off_beats = function(delay, note_num, channel, voice_id, note_location)
  clock.sync(delay)
  if note_location <= #active_notes then
    table.remove(active_notes, note_location)
  else
    --note location is out of bounds!!!
  end
  if midi_out_device then
    midi_out_device:note_off(note_num, nil, channel)
  end
end

externals.wiggle = function(x,y) 
  local volts3 = util.linlin(0,1,0,5,x)
  crow.output[3].slew = 1/SCREEN_REFRESH_DENOMINATOR
  -- crow.output[3].slew = 1/256
  crow.output[3].volts = volts3
  crow.output[3].execute()
  
  local volts4 = util.linlin(0,1,0,5,y)
  -- print("volts4",volts4)
  crow.output[4].slew = 1/SCREEN_REFRESH_DENOMINATOR
  -- crow.output[4].slew = 1/256
  crow.output[4].volts = volts4
  crow.output[4].execute()

end

externals.note_on = function(voice_id, note_tab, target,mode)
  -- local note_offset = params:get("note_offset") - params:get("root_note")
  local note_tab = fn.deep_copy(note_tab)
  if initializing == false then
    if type(note_tab) == "table" and note_tab.pitch then
      note_tab.pitch = util.clamp(note_tab.pitch,1,#notes)
      if params:get("quantize") == 2 then          
        note_tab.pitch = fn.quantize(note_tab.pitch+7) 
        -- note_tab.pitch = fn.quantize(note_tab.pitch+14) 
      end
      -- print(note_tab.pitch)
    end
    -- if mode == 1 or (params:get("vjd_div_asn_midi1") == note_tab.div_id or params:get("vjd_div_asn_midi2") == note_tab.div_id) then
    if target == "midi" and (mode == 1 or (params:get("vjd_div_asn_midi1") == note_tab.div_id or params:get("vjd_div_asn_midi2") == note_tab.div_id)) then
       externals.midi_note_on(voice_id, note_tab, target)
    end
    -- if mode == 1 or (params:get("vjd_div_asn_crow1") == note_tab.div_id or params:get("vjd_div_asn_crow2") == note_tab.div_id) then
    if target == "crow" and (mode == 1 or (params:get("vjd_div_asn_crow1") == note_tab.div_id or params:get("vjd_div_asn_crow2") == note_tab.div_id)) then
      externals.crow_note_on(voice_id, note_tab, target)
    end
    -- if mode == 1 or (params:get("vjd_div_asn_jf1") == note_tab.div_id or params:get("vjd_div_asn_jf2") == note_tab.div_id) then
    if target == "jf" and (mode == 1 or (params:get("vjd_div_asn_jf1") == note_tab.div_id or params:get("vjd_div_asn_jf2") == note_tab.div_id)) then
       externals.jf_note_on(voice_id, note_tab, target)
    end
    -- if mode == 1 or (params:get("vjd_div_asn_wsyn1") == note_tab.div_id or params:get("vjd_div_asn_wsyn2") == note_tab.div_id) then
    if target == "wsyn" and (mode == 1 or (params:get("vjd_div_asn_wsyn1") == note_tab.div_id or params:get("vjd_div_asn_wsyn2") == note_tab.div_id)) then
       externals.wsyn_note_on(voice_id, note_tab, target)
    end
    -- if mode == 1 or (params:get("vjd_div_asn_wdelkarp1") == note_tab.div_id or params:get("vjd_div_asn_wdelkarp2") == note_tab.div_id) then
    if target == "wdel_ks" and (mode == 1 or (params:get("vjd_div_asn_wdelkarp1") == note_tab.div_id or params:get("vjd_div_asn_wdelkarp2") == note_tab.div_id)) then
       externals.wdel_note_on(voice_id, note_tab, target)
    end
  end
end

-- local envelope_length = envelopes[voice_id].get_env_time()
---------------------------------------
-- MIDI out
---------------------------------------
externals.midi_note_on = function(voice_id, note_tab, target)
  local output_midi = params:get("output_midi")
  
  if (target == "midi" and output_midi == 2) then
    local mode = note_tab.mode and note_tab.mode or 1
    if mode == 1 then -- play_voice
      local channel = note_tab.channel and note_tab.channel or 1
      local pitch = note_tab.pitch
      local velocity = note_tab.level and math.floor(util.linlin(0,10,0,127,note_tab.level)) or 80
      local duration = note_tab.duration and note_tab.duration or (params:get("rise_time")/1000)*(params:get("env_scalar")/100)+(params:get("fall_time")/1000)*(params:get("env_scalar")/100)
      duration = tonumber(duration) and duration or fn.fraction_to_decimal(duration)    
      if midi_out_device then
        midi_out_device:note_on(pitch, velocity, channel)
      end
      table.insert(active_notes, pitch)
      clock.run(externals.midi_note_off_beats, duration, pitch, channel, 1, #active_notes)
    elseif mode == 2 then -- stop/start
      if note_tab.stop_start == 1 then -- stop
        midi_out_device:stop()
      else -- start
        if midi_out_device then
          midi_out_device:start()
        end
      end
    end
  end
end
  
externals.play_midi_cc_lz_xy = function(source,volts)
  local output_midi_x = params:get("play_midi_cc_lz_x")
  local output_midi_y = params:get("play_midi_cc_lz_y")
  local cc_val = math.floor(util.linlin(-5,10,1,127,volts))
  if source == "x" and output_midi_x == 2 then -- lz x output
    local slew = params:get("lz_x_slew")/1000
    local cc = params:get("play_midi_cc_lz_x_cc")
    local ch = params:get("play_midi_cc_lz_x_chan")
    ch = ch > 0 and ch or nil
    if midi_out_device then  
      midi_out_device:cc (cc, cc_val, ch)
    end
    -- print("x",cc_val)
  elseif source == "y" and output_midi_y == 2 then -- lz y output
    local slew = params:get("lz_y_slew")/1000
    local cc = params:get("play_midi_cc_lz_y_cc")
    local ch = params:get("play_midi_cc_lz_y_chan")
    ch = ch > 0 and ch or nil
    if midi_out_device then
      midi_out_device:cc (cc, cc_val, ch)
    end
  end
end


externals.play_midi_cc_mod_matrix = function(cc,cc_val,cc_channel)
  if midi_out_device == nil then
    midi_out_device = midi.connect(params:get("midi_out_device"))
  end

  midi_out_device:cc(cc, math.floor(cc_val), cc_channel)
end

---------------------------------------
--crow
---------------------------------------
function externals.get_envelope_data() 
  local data = {}
  data.segments =	 3
  data.curves   =	 {0,params:get("env_shape"),params:get("env_shape")}
  -- curves   =	 {0,-10,-10},
  data.levels	 =   {0,params:get("env_max_level"),0}

  -- local tempo = params:get("clock_tempo")
  -- local div = vuja_de_pattern1.division
  -- data.times	   =   {0,rise,fall/10}
  data.times	   =   {0,(params:get("rise_time")/1000)*(params:get("env_scalar")/100),(params:get("fall_time")/1000)*(params:get("env_scalar")/100)}
  -- data.times	   =   {0,rise/10,fall/10}
  return data
end
externals.crow_note_on = function(voice_id, note_tab, target)
  
  local asl_generator = function()
    local envelope_data = externals.get_envelope_data()
    local asl_envelope = ""
    for i=2, envelope_data.segments, 1
    do
      local to_env 
      if envelope_data.curves[i] > 0 then to_env = '"expo"'
      elseif envelope_data.curves[i] < 0 then to_env = '"sine"'
      else to_env = '"lin"'
      end
      local to_string
      if i < envelope_data.segments then
        to_string =  "to(" .. 
                        (envelope_data.levels[i]) .. "," ..
                        (envelope_data.times[i]-envelope_data.times[i-1]) .. 
                        "," .. to_env .. 
                        "),"
                        asl_envelope = asl_envelope .. to_string

      elseif i == envelope_data.segments then
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

  -- note, trigger, envelope, gate check
  if (voice_id == 1 and target == "crow") then
    for i=1,4,1 do
      local output_crow = params:get("output_crow"..i)
      if output_crow == 2 then
        local volts = (note_tab.pitch-midi_pitch_offset)/12
        -- local volts = (note_tab.pitch-midi_pitch_offset+24)/12
        crow.output[i].volts = volts 
        crow.output[i]() 
      elseif output_crow == 3 then -- envelope
        local asl_envelope = asl_generator()
        -- print(asl_envelope)
        crow.output[i].action = tostring(asl_envelope)
        crow.output[i]() 
      elseif output_crow == 4 then -- trigger
        time = 0.01 --crow_trigger_2
        level = params:get("env_max_level")
        polarity = 1
        crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        crow.output[2]() 
      elseif output_crow == 5 then -- gate
        local tempo = params:get("clock_tempo")
        local time = (60/tempo)*(rise+fall)
        local level = params:get("env_max_level")
        crow.output[i].volts = level
        gate_off_clock = clock.run(externals.gate_off,time)
        crow.output[i]() 
      end
      crow.output[1].execute()
    end
  end
end


externals.play_crow_lz_xy = function(source,volts)
  for i=1,4,1 do
    local output_crow = params:get("output_crow"..i)
    if source == "x" and output_crow == 6 then -- lz x output
      crow.output[i].slew = params:get("lz_x_slew")/1000
      crow.output[i].volts = volts 
      crow.output[i]() 
    elseif source == "y" and output_crow == 7 then -- lz y output
      crow.output[i].slew = params:get("lz_y_slew")/1000
      crow.output[i].volts = volts 
      crow.output[i]() 
    end
  end
end

---------------------------------------
-- just friends
---------------------------------------
externals.jf_note_on = function(voice_id, note_tab, target)
  local output_jf = params:get("output_jf")
  local jf_mode = params:get("jf_mode")

  if (target == "jf" and output_jf == 2) then
    local pitch = note_tab.pitch
    local level = note_tab.level
    local channel = note_tab.channel and note_tab.channel or 1

    local jf_pitch1 = pitch + params:get("jf_pitch_interval1")
    local jf_pitch2 = pitch + params:get("jf_pitch_interval2")
    local jf_pitch3 = pitch + params:get("jf_pitch_interval3")
    local jf_pitch4 = pitch + params:get("jf_pitch_interval4")
    local jf_pitch5 = pitch + params:get("jf_pitch_interval5")
    local jf_pitch6 = pitch + params:get("jf_pitch_interval6")

    if params:get("quantize") == 2 then          
      jf_pitch1 = jf_pitch1+midi_pitch_offset
      jf_pitch2 = jf_pitch2+midi_pitch_offset
      jf_pitch3 = jf_pitch3+midi_pitch_offset
      jf_pitch4 = jf_pitch4+midi_pitch_offset
      jf_pitch5 = jf_pitch5+midi_pitch_offset
      jf_pitch6 = jf_pitch6+midi_pitch_offset
      jf_pitch1 = fn.quantize(jf_pitch1-midi_pitch_offset)
      jf_pitch2 = fn.quantize(jf_pitch2-midi_pitch_offset)
      jf_pitch3 = fn.quantize(jf_pitch3-midi_pitch_offset)
      jf_pitch4 = fn.quantize(jf_pitch4-midi_pitch_offset)
      jf_pitch5 = fn.quantize(jf_pitch5-midi_pitch_offset)
      jf_pitch6 = fn.quantize(jf_pitch6-midi_pitch_offset)
    end
    
    if jf_mode == 2 then -- note_on poly mode
      crow.ii.jf.play_note((pitch-midi_pitch_offset)/12,level)
    elseif jf_mode == 1 then -- play_voice mono mode
      local channel = channel
      crow.ii.jf.play_voice(channel,(pitch-midi_pitch_offset)/12,level)
    else -- portamento
      crow.ii.jf.pitch(1,(jf_pitch1-midi_pitch_offset)/12)
      crow.ii.jf.pitch(2,(jf_pitch2-midi_pitch_offset)/12)
      crow.ii.jf.pitch(3,(jf_pitch3-midi_pitch_offset)/12)
      crow.ii.jf.pitch(4,(jf_pitch4-midi_pitch_offset)/12)
      crow.ii.jf.pitch(5,(jf_pitch5-midi_pitch_offset)/12)
      crow.ii.jf.pitch(6,(jf_pitch6-midi_pitch_offset)/12)
      -- crow.ii.jf.pitch(channel,(pitch-midi_pitch_offset)/12)
    end
  end
end

---------------------------------------
-- wsyn 
---------------------------------------
externals.wsyn_note_on = function(voice_id, note_tab, target)
  local output_wsyn = params:get("output_wsyn")
  local output_wdel_ks = params:get("output_wdel_ks")

  -- wsyn out
  if (target == "wsyn" and output_wsyn == 2) then

    local env_time = rise+fall
    local lpg_time = util.linlin(0,2,10,0,env_time)-5       
    local lpg_symmetry = util.linlin(0,1,10,0,rise)-5       
    
    params:set("wsyn_lpg_time",lpg_time)
    params:set("wsyn_lpg_symmetry",lpg_symmetry)

    local wsyn_pitch_interval1 = params:get("wsyn_pitch_interval1")
    local wsyn_pitch_interval2 = params:get("wsyn_pitch_interval2")
    local wsyn_pitch_interval3 = params:get("wsyn_pitch_interval3")

    local pitch1 = (note_tab.pitch-midi_pitch_offset + wsyn_pitch_interval1)
    local pitch2 = (note_tab.pitch-midi_pitch_offset + wsyn_pitch_interval2)
    local pitch3 = (note_tab.pitch-midi_pitch_offset + wsyn_pitch_interval3)
    
    if params:get("quantize") == 2 then          
      pitch1 = pitch1+midi_pitch_offset
      pitch2 = pitch2+midi_pitch_offset
      pitch3 = pitch3+midi_pitch_offset
      pitch1 = (fn.quantize(pitch1)-midi_pitch_offset)/12
      pitch2 = (fn.quantize(pitch2)-midi_pitch_offset)/12
      pitch3 = (fn.quantize(pitch3)-midi_pitch_offset)/12
      -- pitch2 = fn.quantize(pitch2) 
      -- pitch3 = fn.quantize(pitch3) 
    end

    -- params:set("wsyn_pluckylog",1)
    crow.send("ii.wsyn.play_voice(" .. 1 .."," .. pitch1 .."," .. 5 .. ")")
    
    -- params:set("wsyn_pluckylog",1)
    crow.send("ii.wsyn.play_voice(" .. 2 .."," .. pitch2 .."," .. 5 .. ")")
    
    -- params:set("wsyn_pluckylog",1)
    -- params:set("wsyn_lpg_time",llpg_time)
    
    crow.send("ii.wsyn.play_voice(" .. 3 .."," .. pitch3 .."," .. 5 .. ")")

  end
end

------------------------------
-- wdel - karplus-strong out
------------------------------
externals.wdel_note_on = function(voice_id, note_tab, target)
  if ( target == "wdel_ks" and output_wdel_ks == 2) then
    local pitch = (note_tab.pitch-midi_pitch_offset)/12
    -- local level = voice_id == 1 and params:get("env_max_level") or params:get("envelope2_max_level") 
    local level = params:get("env_max_level") 
    crow.send("ii.wdel.pluck(" .. level .. ")")
    crow.send("ii.wdel.freq(" .. pitch .. ")")
    params:set("wdel_rate",0)
  end
end
--[[
  slide and gate notes:

  if slide is on, do not bring the note gate to 0

]]

local gate_off_clock
function externals.gate_off(time)
  clock.sleep(time)
  -- if slide == "on" then
    crow.output[2].volts = 0
    crow.output[2].execute()
      -- crow.output[4].volts = 0
    -- crow.output[4].execute()                      
    -- slide = "off"
  -- end
end

function externals.slide_on(time)
  clock.sleep(time)
  slide = "on"
  crow.output[4].volts = 5
  crow.output[4].execute()
  -- clock.run(externals.slide_off,60/(tempo/div)/2)
end

function externals.slide_off(time)
  clock.sleep(time)
  slide = "off"
  crow.output[4].volts = 0
  crow.output[4].execute()
end

return externals
