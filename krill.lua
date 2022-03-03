-- krill v0.1.0
-- krell for krill.
--
-- llllllll.co/t/XXXXXX
--
--[[
engine.kr_start()
engine.kr_env_time(1)
engine.kr_env_shape('log')
engine.kr_rise_fall(0.3,1.1)
engine.kr_rc_fdbk(500)
engine.kr_rc_freq(15000)
engine.kr_env_time(12)
engine.kr_rise_fall(0.01,0.01)
engine.kr_rc_mul(0.3)
engine.kr_rc_a(0.36)
engine.kr_rc_b(0.35)
engine.kr_rc_c(4.7)
engine.kr_rc_h(0.01)
engine.kr_rc_xi(0.5)

]]
-- 
--
--    ▼ instructions below (NEEDS UPDATING!!!!) ▼
--
-- K2 modifies current sequence
-- K3 toggles start/stop
-- K1+E1 selects saved sequence
-- K1+K3 loads saved sequence
-- K1+K2 toggles markov mode
--
-- ///     note mode   \\\
-- E2 selects note
-- E3 changes note
--
-- ///    markov mode   \\\
-- E1 selects markov chain
-- E2 selects transition
-- E3 changes probability

-- lattice_=require("lattice")
-- s=require("sequins")
-- mm=include("acid-test/lib/mm")
-- design=include("acid-test/lib/design")
-- musicutil=require("musicutil")
-- hs=include('lib/halfsecond')

engine.name="Krill"

lorentz = include("lib/lorentz.lua")

-- engine.name="AcidTest"

note_last=nil
fade_text=""
fade_time=0
shift=false
markov_mode=false
sel_note=1
disable_transport=false
chaos_x={}
chaos_y={}

function init()
  clock.run(setup_polling)
end

function setup_polling()
  rise_poll = poll.set("rise_poll", function(value)
    -- print("rise done",value)
    -- table.insert(chaos_x,value)
  end)

  fall_poll = poll.set("fall_poll", function(value)
    -- print("fall done",value)
    -- table.insert(chaos_y,value)
    
  end)

  rc1_sample_poll = poll.set("rc1_sample_poll", function(value)
    print("rc1_sample_poll",value)
    table.insert(chaos_x,value)
    
  end)

  rc2_sample_poll = poll.set("rc2_sample_poll", function(value)
    print("rc2_sample_poll",value)
    table.insert(chaos_y,value)
  end)

  clock.sleep(1)
  polling_start()
  clock.sleep(0.25)
  clock.run(function()
      while true do
        clock.sleep(1/10)
        redraw()
      end
    end)
  engine.kr_start();
  -- engine.kr_env_time(0.5);
end

function polling_start()
  rise_poll:start()
  fall_poll:start()
  rc1_sample_poll:start()
  rc2_sample_poll:start()
end

function redraw()
  local rand = math.random()*3+1
  engine.kr_rc_c(rand)
  -- print("redraw",#chaos_x)
  screen.level(15)
  -- if #chaos_x > 1000 then
    -- chaos_x = {}
    -- chaos_y = {}
  -- end
  
  if #chaos_x >= 1 then
    for i=1,#chaos_x,1 do
      local x = math.floor(util.linlin(-1,1,1,128,chaos_x[i]))
      local y = math.floor(util.linlin(-1,1,1,64,chaos_y[i]))
      -- print(x,y)
      screen.move(x,y)
      -- screen.line(x,y)
      screen.pixel(x,y)
      screen.stroke()
    end
    screen.update()
  end
end
-- function init_acit_test()
--   -- setup midi
--   midis={}
--   midi_devices={"none"}
--   midi_default=1
--   for i,dev in pairs(midi.devices) do
--     local name=string.lower(dev.name)
--     if name~="virtual" and midi_default==1 then
--       midi_default=i
--     end
--     name=name:gsub("-","")
--     print("connected to "..name)
--     table.insert(midi_devices,name)
--     midis[name]={
--       last_note=nil,
--       name=name,
--     conn=midi.connect(dev.port)}
--   end

--   scale_names={}
--   for i=1,#musicutil.SCALES do
--     table.insert(scale_names,string.lower(musicutil.SCALES[i].name))
--   end

--   local debounce_sequence_length=0
--   params:add_separator("acid test")
--   params:add_group("sequences",7)
--   params:add{type="number",id="sequence_length",name="sequence length",min=1,max=256,default=16}
--   params:set_action("sequence_length",function(x)
--     debounce_sequence_length=20
--   end)
--   local evolutions={"none","every beat"}
--   for i=2,128 do
--     table.insert(evolutions,"every "..i.." beats")
--   end
--   params:add_option("evolve","evolve",evolutions)
--   params:add{type="option",id="scale_mode",name="scale mode",
--   options=scale_names,default=1}
--   params:add{type="number",id="root_note",name="root note",
--   min=0,max=127,default=60,formatter=function(param) return musicutil.note_num_to_name(param:get(),true) end}
--   params:add{type="number",id="base_note",name="base note",
--   min=0,max=127,default=57-24,formatter=function(param) return musicutil.note_num_to_name(param:get(),true) end}
--   params:add{type="number",id="velocity_spread",name="velocity spread",min=1,max=30,default=5}
--   local division_options={"1/32","1/16","1/12","1/10","1/8","1/4","1/2","1","2"}
--   current_division=1/16
--   params:add_option("division","division",division_options,2)
--   params:set_action("division",function(x)
--     load("current_division="..division_options[x])()
--   end)

--   params:add_group("engine",4)
--   params:add_option("out_engine","engine output",{"no","yes"},midi_default==1 and 2 or 1)
--   params:set_action("out_engine",function(x)
--     params:set("bass vol",x==1 and -96 or -6)
--   end)
--   params:add{type="control",id="bass vol",name="bass vol",controlspec=controlspec.new(-96,0,'lin',1,(midi_default==1 and-6 or-96),'',1/(96)),formatter=function(v)
--     local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
--     return ((val<0) and "" or "+")..val.." dB"
--   end}
--   params:add{type="control",id="kick vol",name="kick vol",controlspec=controlspec.new(-96,-12,'lin',1,-96,'',1/(96-12)),formatter=function(v)
--     local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
--     return ((val<0) and "" or "+")..val.." dB"
--   end}
--   params:add{type="control",id="snare vol",name="snare vol",controlspec=controlspec.new(-96,-12,'lin',1,-96,'',1/(96-12)),formatter=function(v)
--     local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
--     return ((val<0) and "" or "+")..val.." dB"
--   end}

--   params:add_group("crow/jf",2)
--   params:add_option("out_crow","crow output",{"no","yes"})
--   params:add_option("out_crow_jf","crow jf output",{"no","yes"})

--   params:add_group("midi",3+3*4)
--   params:add{type="option",id="midi_out_device",name="midi out device",
--     options=midi_devices,default=midi_default,action=function(x)
--       all_notes_off()
--     end
--   }
--   params:add{type="number",id="midi_out_channel",name="midi out channel",
--     min=1,max=16,default=1,action=function(x)
--       all_notes_off()
--     end
--   }
--   params:add{type="number",id="midi_portamento_cc",name="midi portamento cc",min=1,max=127,default=5}
--   local pdefaults={
--     {74,67,100},
--     {23,0,10},
--     {71,32,68},
--   }
--   pdefaults={
--     {0,67,100},
--     {0,0,10},
--     {0,32,68},
--   }
--   for i=1,3 do
--     params:add{type="number",id="midi_lfo_cc"..i,name="midi lfo "..i.." cc",min=0,max=127,default=pdefaults[i][1]}
--     params:add{type="number",id="midi_lfo_min"..i,name="midi lfo "..i.." min",min=0,max=127,default=pdefaults[i][2]}
--     params:add{type="number",id="midi_lfo_max"..i,name="midi lfo "..i.." max",min=0,max=127,default=pdefaults[i][3]}
--     params:add{type="control",id="midi_lfo_period"..i,name="midi lfo "..i.." period",
--     controlspec=controlspec.new(0.1,60,'lin',0.1,math.random(5,12),'s',0.1/60)}
--   end

--   hs.init()

--   tape_ready=false
--   -- TODO replace this part to use softcut instead
--   -- params:add_file("tapefile","load synced tape","/home/we/dust/audio/")
--   -- params:set_action("tapefile",function(x)
--   --   if x=="/home/we/dust/audio/" or x=="/home/we/dust/audio" then
--   --     do return end
--   --   end
--   --   print("loading tape: "..x)
--   --   audio.tape_play_open(x)
--   --   clock.run(function()
--   --     clock.sleep(1)
--   --     tape_ready=true
--   --   end)
--   -- end)

--   -- initialize lattice
--   lattice=lattice_:new()

--   local tt=-1
--   local last_midi_cc={-1,-1,-1}
--   -- load("foo=1/16")(); print(foo)
--   lattice_pattern=lattice:new_pattern{
--     action=function()
--       if lattice_pattern.division~=current_division then
--         lattice_pattern:set_division(current_division)
--       end
--       tt=tt+1
--       if tt%16==0 and tape_ready then
--         tape_ready=false 
--         audio.tape_play_start()
--       end
--       if tt%8==0 then
--         -- do cc's
--         local t=clock.get_beat_sec()*clock.get_beats()
--         for i=1,3 do
--           if params:get("midi_lfo_cc"..i)>0 then 
--             local ccval=util.linlin(-1,1,params:get("midi_lfo_min"..i),params:get("midi_lfo_max"..i),
--             math.sin(2*3.14159*t/params:get("midi_lfo_period"..i)))
--             ccval=math.floor(util.round(ccval))
--             if ccval~=last_midi_cc[i] then
--               if midis[midi_devices[params:get("midi_out_device")]]~=nil and
--                 midis[midi_devices[params:get("midi_out_device")]].conn~=nil then
--                 midis[midi_devices[params:get("midi_out_device")]].conn:cc(params:get("midi_lfo_cc"..i),ccval)
--               end
--             end
--             last_midi_cc[i]=ccval
--           end
--         end
--         -- engine.acidTest_drum("kick",util.dbamp(params:get("kick vol")),0.0,0.0)
--         -- elseif tt%4==0 then
--         --   engine.acidTest_drum("snare",util.dbamp(params:get("snare vol")),0.0,0.0)
--       end
--       if params:get("evolve")>1 then
--         if tt%(4*params:get("evolve"))==0 then
--           designs[1]:sequence(params:get("sequence_length"),1)
--         end
--       end
--       local v=designs[1].seq()
--       if next(v)==nil then
--         do
--           return
--         end
--       end
--       play(1,v,"bass")
--     end,
--     division=current_division
--   }

--   change_magnitude=0
--   clock.run(function()
--     while true do
--       clock.sleep(1/10)
--       redraw()
--       if change_magnitude>0 then
--         change_magnitude=change_magnitude-5
--       end
--       if debounce_sequence_length>0 then
--         debounce_sequence_length=debounce_sequence_length-1
--         if debounce_sequence_length==0 then
--           designs[1]:sequence(params:get("sequence_length"))
--         end
--       end
--     end
--   end)

--   -- setup designs
--   designs={}
--   for i=1,2 do
--     table.insert(designs,design:new())
--     designs[i]:sequence(params:get("sequence_length"))
--   end

--   -- setup saving and loading
--   params.action_write=function(filename,name)
--     print("write",filename,name)
--     local data={}
--     for _,d in ipairs(designs) do
--       table.insert(data,d:dump())
--     end
--     local fname=filename..".json"
--     local file=io.open(fname,"w+")
--     io.output(file)
--     io.write(json.encode(data))
--     io.close(file)
--   end

--   params.action_read=function(filename,silent)
--     print("read",filename,silent)
--     local fname=filename..".json"
--     local f=io.open(fname,"rb")
--     local content=f:read("*all")
--     f:close()
--     local data=json.decode(content)
--     for i,s in ipairs(data) do
--       designs[i]:load(s)
--     end
--     -- TODO: load latest saved
--   end


--   all_notes_off()

--   redraw()
--   lattice:start()

-- end

-- function all_notes_off()
--   if midis[midi_devices[params:get("midi_out_device")]]==nil then
--     do return end
--   end
--   if midis[midi_devices[params:get("midi_out_device")]].conn~=nil then
--     local m=midis[midi_devices[params:get("midi_out_device")]].conn
--     for j=20,80 do
--       m:note_off(j,nil,params:get("midi_out_channel"))
--     end      
--   end
-- end

-- function clock.transport.start()
--   if disable_transport then
--     do return end
--   end
--   print("transport start")
--   toggle_playing(true)
-- end

-- function clock.transport.stop()
--   if disable_transport then
--     do return end
--   end
--   print("transport stop")
--   toggle_playing(false)
-- end

-- function toggle_playing(on)
--   disable_transport=true
--   clock.run(function()
--     clock.sleep(1)
--     disable_transport=false
--   end)
--   designs[1].seq.ix=0
--   if on~=nil then
--     if on then
--       lattice:hard_restart()
--     else
--       lattice:stop()
--       all_notes_off()
--     end
--     do return end
--   end
--   if lattice.enabled then
--     lattice:stop()
--     all_notes_off()
--   else
--     lattice:hard_restart()
--   end
-- end

-- function cleanup()
--   -- audio.tape_play_stop()
--   -- for _,m in pairs(midis) do
--   --   for j=1,127 do
--   --     if m.conn~=nil then
--   --       m.conn:note_off(j)
--   --     end
--   --   end
--   -- end
-- end

-- function enc(k,d)
--   d=d<0 and-1 or 1
--   if shift then
--     if k==1 then
--       designs[1]:sel_mem(d)
--       fade_msg("seq "..designs[1].memsel)
--     end
--   else
--     if markov_mode then
--       if k==1 then
--         designs[1]:selp_delta(d)
--       elseif k==2 then
--         designs[1]:sel_delta(d)
--       elseif k==3 then
--         designs[1]:val_delta(d)
--       end
--     else
--       if k==1 then
--       elseif k==2 then
--         sel_note=util.clamp(sel_note+d,1,designs[1].seq.length)
--       elseif k==3 then
--         designs[1].seq.data[sel_note].note=util.clamp(designs[1].seq.data[sel_note].note+d,20,120)
--       end
--     end
--   end
-- end

-- function key(k,z)
--   if k==1 then
--     shift=z==1
--     do return end
--   end
--   if shift then
--     if k==3 and z==1 then
--       designs[1]:load_mem()
--       fade_msg("loaded seq "..designs[1].memsel)
--     elseif k==2 and z==1 then
--       markov_mode=not markov_mode
--     end
--   else
--     if k==2 and z==1 then
--       local num_to_change=util.clamp(math.random(1,2)+math.floor(change_magnitude/10),1,params:get("sequence_length"))
--       if num_to_change==params:get("sequence_length") then
--         designs[1]:sequence(params:get("sequence_length"))
--         fade_msg("seq"..(#designs[1].memory).." (all changed)")
--         change_magnitude=change_magnitude+10
--       else
--         designs[1]:sequence(params:get("sequence_length"),num_to_change)
--         fade_msg("seq"..(#designs[1].memory).." ("..num_to_change.." changed)")
--         change_magnitude=change_magnitude+40
--       end
--     elseif k==3 and z==1 then
--       toggle_playing()
--     end
--   end
-- end

-- function fade_msg(s)
--   fade_time=15
--   fade_text=s
-- end

-- function play(i,v,t)
--   local m=midis[midi_devices[params:get("midi_out_device")]]

--   local do_note_off=v.legato==0 -- rest
--   do_note_off=do_note_off or (v.legato==1) -- new note
--   if designs[i].note_last~=nil then
--     do_note_off=do_note_off or (v.legato==2 and designs[i].note_last~=v.note) -- changing note, but hold
--   end
--   if do_note_off then
--     do_note_off=designs[i].note_last
--   else
--     do_note_off=nil
--   end

--   local velocity=math.random(60-params:get("velocity_spread"),60+params:get("velocity_spread"))
--   if v.accent then
--     velocity=velocity+math.random(30-params:get("velocity_spread"),30+params:get("velocity_spread"))
--   end
--   if m~=nil then
--     if v.slide then
--       m.conn:cc(params:get("midi_portamento_cc"),20)
--     else
--       m.conn:cc(params:get("midi_portamento_cc"),0)
--     end
--   end

--   if v.legato==1 or (v.legato==2 and designs[i].note_last~=v.note) then
--     -- new note
--     -- print("note on: "..v.note)
--     -- Audio engine out
--     if params:get("out_engine")==2 then
--       engine["acidTest_"..t](velocity/127*util.dbamp(params:get("bass vol")),v.note,0.0,0.0,v.slide and clock.get_beat_sec()/4 or 0)
--       engine["acidTest_"..t.."_gate"](1)
--     end
--     if params:get("out_crow")==2 then
--       -- add slide
--       crow.output[1].slew=v.slide and clock.get_beat_sec()/4 or 0
--       crow.output[1].volts=(v.note-60)/12
--       crow.output[2].volts=5
--     end
--     if params:get("out_crow_jf")==2 then
--         crow.ii.jf.mode(1)
--         crow.ii.jf.play_note((v.note-60)/12,5)
--     else
--       crow.ii.jf.mode(0)
--     end
--     if m~=nil then
--       m.conn:note_on(v.note,velocity,params:get("midi_out_channel"))
--     end
--     designs[i].note_last=v.note
--   end

--   if do_note_off then
--     -- rest / new note
--     if designs[i].note_last~=nil then
--       if params:get("out_engine")==2 then
--         engine["acidTest_"..t.."_gate"](0)
--       end
--       if params:get("out_crow")==2 then
--         crow.output[2].volts=0
--       end
--       if m~=nil then
--         m.conn:note_off(do_note_off,nil,params:get("midi_out_channel"))
--       end
--       designs[i].note_last=nil
--     end
--   end

-- end

-- function redraw()
--   screen.clear()
--   screen.line_cap("round")
--   if markov_mode then
--     for i=1,2 do
--       designs[1]:draw_matrix()
--     end
--   else
--     screen.aa(0)
--     local note_mm={1000,-1}
--     for i,v in ipairs(designs[1].seq.data) do
--       if v.note>note_mm[2] then
--         note_mm[2]=v.note
--       elseif v.note<note_mm[1] then
--         note_mm[1]=v.note
--       end
--     end
--     local n=designs[1].seq.length
--     local w=math.floor(128/n)
--     local last_n=32
--     for i,v in ipairs(designs[1].seq.data) do
--       local n=math.floor(util.linlin(note_mm[1],note_mm[2],60,4,v.note))
--       if i>1 then
--         screen.level(1)
--         screen.line_width(1)
--         screen.move((i-1)*w-w/2,last_n)
--         screen.line(i*w-w/2,n)
--         screen.stroke()
--       end
--       last_n=n
--     end
--     if designs[1].seq~=nil and designs[1].seq.data~=nil then
--       local n=math.floor(util.linlin(note_mm[1],note_mm[2],60,4,designs[1].seq.data[sel_note].note))
--       screen.level(15)
--       screen.line_width(1)
--       screen.rect((sel_note-1)*w+1,n-3,w,7)
--       screen.fill()
--     end
--     for i,v in ipairs(designs[1].seq.data) do
--       local n=math.floor(util.linlin(note_mm[1],note_mm[2],60,4,v.note))
--       if v.legato>0 then
--         screen.level(i==designs[1].seq.ix and 15 or 5)
--         screen.line_width(v.accent and 4 or 2)
--         screen.move((i-1)*w+(v.legato==1 and 2 or 0),n)
--         screen.line(i*w,n+(v.slide and 3 or 0))
--         screen.stroke()
--       end
--     end
--   end
--   if fade_time>0 then
--     fade_time=fade_time-1
--     screen.move(2,64-2)
--     screen.level(util.clamp(fade_time,0,15))
--     screen.text(fade_text)
--   end
--   screen.update()
-- end
