-- krill v0.1.0
-- krell for krill.
--
-- llllllll.co/t/XXXXXX
--
-- _norns.screen_export_png("/home/we/dust/krill"..screenshot..".png")

--[[
  notes about installing https://github.com/madskjeldgaard/portedplugins
  
  SOLUTION???
  see: https://llllllll.co/t/tapedeck/51919

    RUN:  `os.execute("cd /tmp && wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz && tar -xvzf PortedPlugins.tar.gz && rm PortedPlugins.tar.gz && sudo rsync -avrP PortedPlugins /home/we/.local/share/SuperCollider/Extensions/")`

]]
--[[
engine.start()
engine.env_time(1)
engine.env_shape('log')
engine.rise_fall(0.3,1.1)
engine.rc_fdbk(500)
engine.rc_freq(15000)
engine.env_time(12)
engine.rise_fall(0.01,0.01)
engine.rc_mul(0.3)
engine.rc_a(0.36)
engine.rc_b(0.35)
engine.rc_c(4.7)
engine.rc_h(0.01)
engine.rc_xi(0.5)

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

engine.name="Krill"

MusicUtil = require "musicutil"
tabutil = require "tabutil"
Lattice = require "lattice"
cs = require "controlspec"
s = require "sequins"
textentry = require "textentry"
fileselect = require "fileselect"
Sequins = require "sequins"

encoders_and_keys = include("lib/encoders_and_keys")
globals = include("lib/globals")
lorenz = include("lib/lorenz")
parameters = include("lib/parameters")
midi_helper = include("lib/midi_helper")
sound_controller = include("lib/sound_controller")
w_slash = include("lib/w_slash")
externals = include("lib/externals")
gui = include("lib/gui")
vuja_de = include("lib/vuja_de")
vector = include("lib/vector")
mod_matrix = include("lib/mod_matrix")
save_load = include("lib/save_load")
cellular_automata = include("lib/cellular_automata")


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
        

initializing = true
function init()
  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)
  
  screen.aa(1)
  lorenz.init()
  parameters.init()
  -- params:set("x_offset",10)
  fn.build_scale()
  
  active_notes = {}
  ext = externals:new(active_notes)

  sound_controller:init(NUM_OCTAVES_DEFAULT,fn.get_num_notes_per_octave())
  lorenz:reset()
  -- input[1].mode('change', 1,0.1,'rising')
  -- input[2].mode('stream',0.001)
  
  krill_lattice = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }
  
  -- mod_matrix_pattern = krill_lattice:new_pattern{
  --   action = function(t) 
  --     if initializing == false then
  --       mod_matrix:process_matrix()
  --     end
  --   end,
  --   division = 1/1, --1/256, 
  --   enabled = true
  -- }
  
  lorenz_pattern = krill_lattice:new_pattern{
    action = function(t) 
      lorenz:process()
      lorenz:update()

      if pixels[pixels.active] then
        local lb = lorenz.get_boundary()
        local lb_sample_min = lb[1]*lb[2]
        local lb_sample_max = lb[3]*lb[4]
        local sample_val = pixels[pixels.active].x_display * pixels[pixels.active].y_display
        sample_val = util.linlin(lb_sample_min,lb_sample_max,0,1,sample_val)
        engine.set_lorenz_sample(sample_val)
      end
    end,
    division = 1/256, --1/16,
    enabled = true
  }
  
  lorenz_output_pattern_x = krill_lattice:new_pattern{
    action = function(t) 
      if pixels[pixels.active] then
        local lb = lorenz.get_boundary()

        local lz_x_min = params:get("lz_x_min")
        local lz_x_max = params:get("lz_x_max")
        local x_val = pixels[pixels.active].x_display
        lz_x_val = util.linlin(lb[1],lb[1]+lb[3],lz_x_min,lz_x_max,x_val)
        ext.play_crow_lz_xy("x",lz_x_val)
        ext.play_midi_cc_lz_xy("x",lz_x_val)
        params:set("lz_x",lz_x_val)
      end
    end,
    division = 1/64,-- 1/256, --1/16,
    enabled = true
  }
  
  lorenz_output_pattern_y = krill_lattice:new_pattern{
    action = function(t) 
      if pixels[pixels.active] then
        local lb = lorenz.get_boundary()
        local lz_y_min = params:get("lz_y_min")
        local lz_y_max = params:get("lz_y_max")
        local y_val = pixels[pixels.active].y_display
        lz_y_val = util.linlin(lb[2],lb[2]+lb[4],lz_y_min,lz_y_max,y_val)
        ext.play_crow_lz_xy("y",lz_y_val)
        ext.play_midi_cc_lz_xy("y",lz_y_val)
        params:set("lz_y",lz_y_val)
      end
    end,
    division = 1/64,-- 1/256, --1/16,
    enabled = true
  }
  
  vuja_de_rest_patterns = {}
  vuja_de_rest_sequins = {}
  -- vuja_de_rest_patterns[1].get_ruleset_id()
  -- vuja_de_rest_patterns[1].get_ruleset(vuja_de_rest_patterns[1].ruleset)
  for i=1,VJD_MAX_DIVISIONS,1 do
    vuja_de_rest_patterns[i] = cellular_automata:new()
    vuja_de_rest_patterns[i].generate()

    local rs = vuja_de_rest_patterns[1].get_ruleset()
    vuja_de_rest_sequins[i] = Sequins{table.unpack(rs)}
    vuja_de_patterns[i]= krill_lattice:new_pattern{
      action = function(t) 
        -- local rs_id = vuja_de_rest_patterns[1].get_ruleset_id()
        -- local rs = vuja_de_rest_patterns[1].get_ruleset()

        -- play note from quant grid
        local active = pixels[pixels.active]
        vuja_de:update_length()
        local rest = vuja_de_rest_sequins[i]() == 0
        -- if rest==true then print("rest",rest) end
        if active and params:get("sequencing_mode") == 2 and rest==false then -- vuja de mode
          sound_controller:play_vuja_de_note(i)
        end
        -- local jitter = params:get("vuja_de_jitter"..i)
        -- local numerator   =   params:get("vuja_de_div_numerator"..i)
        -- local divisor     =   params:get("vuja_de_div_denominator"..i)
        -- if jitter ==0 and  vuja_de_patterns[i].division ~= numerator/divisor then
        --   print("no jitter",i,vuja_de_patterns[i].division == numerator/divisor)
        --   vuja_de_patterns[i].division = numerator/divisor          
        -- end
        -- if jitter ==0 and  vuja_de_patterns[i].division ~= numerator/divisor then
        -- end
        local numerator   =   params:get("vuja_de_div_numerator"..i)
        local divisor     =   params:get("vuja_de_div_denominator"..i)
        local jitter      =   math.floor(params:get("vuja_de_jitter"..i))
        local new_div
        if jitter>=0 then
          new_div = (numerator/divisor)+(math.random(0,jitter)/10000)
        elseif jitter<0 then
          new_div = (numerator/divisor)+(math.random(jitter,0)/10000)
        -- elseif vuja_de_patterns[i].division and numerator/divisor ~= vuja_de_patterns[i].division then
        --   krill_lattice.reset()
        --   new_div = (numerator/divisor)+(math.random(jitter,0)/10000)
        --   print("reset")
        -- else
        --   new_div = (numerator/divisor)
        end
        -- print(jitter,new_div)
        if vuja_de_patterns[i].division then
          vuja_de_patterns[i].division = new_div
        end
      end,
      division = 1/16, --3/1, --1/8, --1/16,
      enabled = false
    }
  end


  clock.run( function()
    while true do
      if initializing == false then
        if norns.menu.status()  == false then
          -- screen.aa(0)
          gui:display()
          -- ca.display()
        else
          lorenz.display(false)
        end
        screen.update()
      end
      clock.sleep(1/SCREEN_REFRESH_DENOMINATOR)
    end
  end)

  
  krill_lattice:start()
  
  vuja_de = vuja_de:new()
  
  
  
  
  
  
  -- params:set("xy_scale",0.9)
  
  -- clock.run(setup_polling)
  init_polling()
  -- engine.env_time(0.5);
  -- clock.run(gui.set_gui_level)
  params:set("x_offset",-7)
  params:set("y_scale",0.85)
  -- params:set("vuja_de_div_denominator1",8)
  -- params:set("vuja_de_div_denominator2",8)
  -- params:set("vuja_de_div_denominator3",8)
  
  -- params:set("midi_out_device",2)
  
  
  clock.run(finish_init)
end

function finish_init()
  mod_matrix:init()
  save_load.init()
  gui.init()
  if params:get("autosave") == 2 then
    save_load.load_krill_data(folder_path.."autosave.krl")
  end  
  params:set("internal_triger_type",2)
  
  initializing = false
  clock.sleep(1)
  vuja_de_patterns[1]:start()
  vuja_de_patterns[2]:start()
  vuja_de_patterns[3]:start()
  -- vuja_de_patterns[1].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  -- vuja_de_patterns[2].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  -- vuja_de_patterns[3].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  
  params:set("vuja_de_div_numerator1",1)
  params:set("vuja_de_div_denominator1",8)
  params:set("vuja_de_div_numerator2",1)
  params:set("vuja_de_div_denominator2",2)
  params:set("vuja_de_div_numerator3",1)
  params:set("vuja_de_div_denominator3",2)
  params:set("vjd_div_asn_engine2",1)
  -- params:set("vuja_de_div_numerator3",VDJ_PAT_DEFAULT_NUMERATOR)
  -- params:set("vuja_de_div_denominator3",VDJ_PAT_DEFAULT_DENOMINATOR)
  clock.run(gui.update_menu_display)
  -- engine.rise_fall(rise,fall)        
  -- engine.play_note(notes[math.random(15)],2)
  params:set("sequencing_mode",2)
  params:set("env_scalar",100)
  params:set("rise_time",10)
  params:set("fall_time",150)
  -- params:set("sequencing_mode",1)
  
end

function init_polling()
  -- pitch_poll = poll.set("pitch_poll", function(value)
  --   if note_start == true then
  --     note_start = false
      
  --   end
  -- end)

  next_note_poll = poll.set("next_note_poll", function(value)
    -- sound_controller:play_krill_note(value)


    -- if params:get("sequencing_mode") == 1 then
    --   sound_controller:play_krill_note(value)
    -- end

    -- note_start = true
    -- print("note_start_poll",rise,fall)l
  end)

  env_pos_poll = poll.set("env_pos_poll", function(value)
    if initializing == false then
      params:set("env_pos",value)
    end
  end)

  env_level_poll = poll.set("env_level_poll", function(value)
    if initializing == false then
      -- print("level", value)
      params:set("env_level",value)
    end
  end)

  rise_poll = poll.set("rise_poll", function(value)
    -- print("rise done",value)
    prev_rise = rise

    if params:get("sequencing_mode") == 1 then
      -- sound_controller:play_krill_note(value)
    else
      -- sound_controller:play_vuja_de_note()
    end

    rise = value * params:get("env_scalar")/100
  end)

  fall_poll = poll.set("fall_poll", function(value)
    -- print("fall done",value)
    
    prev_fall = fall
    fall = value * params:get("env_scalar")/100
    if params:get("sequencing_mode") == 1 then
      sound_controller:play_krill_note(value)
    else
      -- sound_controller:play_vuja_de_note()
    end

    -- crow.output[2].volts = 0
    -- crow.output[2].execute()
  end)

  function play_engine(note)
    engine.play_note(note,1)
  end

  -- pitch_poll:start()
  -- next_note_poll:start()
  next_note_poll:start()
  env_pos_poll:start()
  env_level_poll:start()
  rise_poll:start()
  fall_poll:start()
end

function cleanup()
  if params:get("autosave") == 2 then
    save_load.save_krill_data("autosave")
  end
end

