-- krill v0.1.0
-- krell for krill.
--
-- llllllll.co/t/XXXXXX
--
-- _norns.screen_export_png("/home/we/dust/krill"..screenshot..".png")

--[[

lfo's thanks to justmat (otis)

engine utilizing v7b1's port of MIRings: https://github.com/v7b1/mi-UGens

notes about installing https://github.com/madskjeldgaard/portedplugins
  
  SOLUTION???
  see: https://llllllll.co/t/tapedeck/51919

    RUN:  `os.execute("cd /tmp && wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz && tar -xvzf PortedPlugins.tar.gz && rm PortedPlugins.tar.gz && sudo rsync -avrP PortedPlugins /home/we/.local/share/SuperCollider/Extensions/")`

  also, see the pedalboard installer script https://github.com/21echoes/pedalboard/blob/0323837f9f4e2a1b82d0ba0da474300578e58180/lib/ui/util/mi_ugens_installer.lua
  also, see okyeron's installer script
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
scroll_text = include("lib/scroll_text")


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
  screen.clear()
  screen.update()

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
        lorenz_sample_val = pixels[pixels.active].x_display * pixels[pixels.active].y_display
        lorenz_sample_val = util.linlin(lb_sample_min,lb_sample_max,0,1,lorenz_sample_val)
        engine.set_lorenz_sample(lorenz_sample_val)
        -- engine.set_lorenz_sample(sample_val + math.random()*(params:get("rise_time")*1000)+params:get("fall_time")*1000)
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

  lfo_output_patterns = krill_lattice:new_pattern{
    action = function(t) 
      if pixels[pixels.active] then
        local lfo_slope1 = mod_matrix.lfo[1].slope
        local lfo_slope2 = mod_matrix.lfo[2].slope

        local lfo1_volts_min = params:get("1lfo_volts_min")
        local lfo1_volts_max = params:get("1lfo_volts_max")
        local lfo2_volts_min = params:get("2lfo_volts_min")
        local lfo2_volts_max = params:get("2lfo_volts_max")

        local lfo_val1 = util.linlin(-1,1,lfo1_volts_min,lfo1_volts_max,lfo_slope1)
        local lfo_val2 = util.linlin(-1,1,lfo2_volts_min,lfo2_volts_max,lfo_slope2)
        ext.play_crow_lfos("1lfo", lfo_val1)
        ext.play_midi_cc_lfos("1lfo", mod_matrix.lfo[1].slope)
        ext.play_crow_lfos("2lfo", lfo_val2)
        ext.play_midi_cc_lfos("2lfo", mod_matrix.lfo[2].slope)
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
        if active and params:get("sequencing_mode") == 2 and rest==false then -- vuja de mode
          sound_controller:play_vuja_de_note(i)
        end

        local numerator   =   params:get("vuja_de_div_numerator"..i)
        local divisor     =   params:get("vuja_de_div_denominator"..i)
        local jitter      =   math.floor(params:get("vuja_de_jitter"..i))
        local new_div
        if jitter>=0 then
          new_div = (numerator/divisor)+(math.random(0,jitter)/10000)
        elseif jitter<0 then
          new_div = (numerator/divisor)+(math.random(jitter,0)/10000)
        end
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
  init_polling()
  params:set("x_offset",-7)
  params:set("y_scale",0.85)
  
  mod_matrix:init()
  save_load.init()
  gui.init()
  if params:get("autosave") == 2 then
    save_load.load_krill_data(folder_path.."autosave.krl")
  end  
  
  initializing = false  clock.run(finish_init)
end

function finish_init()
  clock.sleep(1)

  vuja_de_patterns[1]:start()
  vuja_de_patterns[2]:start()
  vuja_de_patterns[3]:start()
  params:set("vuja_de_div_numerator1",1)
  params:set("vuja_de_div_denominator1",8)
  params:set("vuja_de_div_numerator2",1)
  params:set("vuja_de_div_denominator2",2)
  params:set("vuja_de_div_numerator3",1)
  params:set("vuja_de_div_denominator3",2)
  params:set("vjd_div_asn_engine2",1)
  params:set("sequencing_mode",2)
  params:set("env_scalar",100)
  params:set("rise_time",10)
  params:set("fall_time",150)

  params:set("rings_pos",1)
  -- params:set("rings_structure_base",0.25)
  params:set("rings_brightnes_base",0.25)
  params:set("rings_damping_base",0.25)
  params:set("rings_poly",1)
  params:set("internal_trigger_type",2)
  params:set("internal_trigger_type",1)
  params:set("vuja_pat_defaults1",5)

  params:set("1lfo_freq",1)

  clock.run(gui.update_menu_display)
  play_enabled = true


  -- og_print = fn.clone_function(tab.print)
  -- tab.print = function(x)
  --   -- do something
  --   print("custom print: ")
  --   og_print(x)
  -- end
end

function init_polling()
  -- pitch_poll = poll.set("pitch_poll", function(value)
  --   if note_start == true then
  --     note_start = false
      
  --   end
  -- end)

  next_note_poll = poll.set("next_note_poll", function(value)
    -- sound_controller:play_krill_note(value)


    if params:get("sequencing_mode") == 1 then
      clock.run(sound_controller.play_krill_note,value)
      -- print("sound_controller:play_krill_note()", value)
    end

    -- note_start = true
    -- print("note_start_poll",rise,fall)
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
    engine.note_off(1)
    prev_fall = fall
    fall = value * params:get("env_scalar")/100
    -- local rise_fall = rise/fall
    -- print("rise_fall",rise_fall)

    if params:get("sequencing_mode") == 1 then
      -- sound_controller:play_krill_note()
      -- sound_controller:play_krill_note(rise_fall)
    else
      -- sound_controller:play_vuja_de_note()
    end

    -- crow.output[2].volts = 0
    -- crow.output[2].execute()
  end)

  function play_engine(note)
    -- engine.note_off()
    engine.note_on(note,1)
  end

  function adjust_engine_pitch(note)
    -- engine.note_off()
    engine.adjust_engine_pitch(note)
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

