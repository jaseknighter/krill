-- krill v1.0.1 @jaseknighter
-- chaotic sequencer, MI Rings engine, and mod matrix
--
-- llllllll.co/t/54975
--
-- 
--
--    ▼ basic instructions  ▼
--
-- K1+E1 toggles sequencer/mod matrix
--
-- ///   sequencer mode   \\\
-- E1 select menu
-- E2 select param
-- E3 change param value
-- K2+E3 coarse value change 
--
-- ///    mod matrix (mm)  \\\
-- E1 select menu
-- K2+K3 clear patchpoint
--
-- ///    mm: row/col   \\\
-- E2 select row
-- E3 select col
--
-- ///    mm: in/out   \\\
-- E2/E3 select input/output
-- K2+E2 fast input navigation
-- K2+E3 fast output navigation
--
-- ///    mm: other menus   \\\
-- E2 select param
-- E3 +/- param value
-- K2+E3 coarse +/- param value
--
-- see docs for more details
--   


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
  -- lorenz:clear()
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
  
  vuja_de_rthm_patterns = {}
  vuja_de_rthm_sequins = {}
  -- vuja_de_rthm_patterns[1].get_ruleset_id()
  -- vuja_de_rthm_patterns[1].get_ruleset(vuja_de_rthm_patterns[1].ruleset)
  for i=1,VJD_MAX_DIVISIONS,1 do
    vuja_de_rthm_patterns[i] = {}
    vuja_de_rthm_sequins[i] = {}
    vuja_de_rthm_sequins[i].active_rthm_pattern = 1
    for j=1,3,1 do
      vuja_de_rthm_patterns[i][j] = cellular_automata:new()
      vuja_de_rthm_patterns[i][j].generate()

      -- local rs = vuja_de_rthm_patterns[1].get_ruleset()
      local rs = vuja_de_rthm_patterns[i][j].get_ruleset()
      vuja_de_rthm_sequins[i][j] = Sequins{table.unpack(rs)}
      
    end
    vuja_de_patterns[i]= krill_lattice:new_pattern{
      action = function(t) 
        local active_rthm_pat = vuja_de_rthm_sequins[i].active_rthm_pattern
        -- play note from quant grid
        local active = pixels[pixels.active]
        vuja_de:update_length()
        local rthm = vuja_de_rthm_sequins[i][active_rthm_pat]() == 0
        params:set("vjd rthm active"..i, rthm == true and 2 or 1)
        if active and params:get("sequencing_mode") == 2 and rthm==false then -- vuja de mode
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
        if norns.menu.status() == false then
          gui:display()
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
  params:set("env_scalar",100)
  params:set("rise_time",10)
  params:set("fall_time",150)

  params:set("engine_mode",2)
  params:set("rings_pos",0.5)
  params:set("rings_structure_base",0.5)
  params:set("rings_structure_range",0.5)
  params:set("rings_brightness_base",0.75)
  params:set("rings_damping_base",0.25)
  params:set("rings_damping_range",0.6)
  params:set("rings_poly",4)
  params:set("internal_trigger_type",2)
  params:set("internal_trigger_type",1)
  params:set("vuja_pat_defaults1",4)
  params:set("rise_time",150)
  params:set("fall_time",100)

  params:set("1lfo_freq",1)
  params:set("sequencing_mode",2)
  params:set("sequencing_mode",1)
  clock.run(gui.update_menu_display)
  play_enabled = true
end

function init_polling()

  next_note_poll = poll.set("next_note_poll", function(value)
    if params:get("sequencing_mode") == 1 then
      clock.run(sound_controller.play_krill_note,value)
    end
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
    prev_rise = rise
    rise = value * params:get("env_scalar")/100
  end)

  fall_poll = poll.set("fall_poll", function(value)
    engine.note_off(1)
    prev_fall = fall
    fall = value * params:get("env_scalar")/100
  end)


  function adjust_engine_pitch(note)
    engine.adjust_engine_pitch(note)
  end

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

