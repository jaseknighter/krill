-- krill v0.1.0
-- krell for krill.
--
-- llllllll.co/t/XXXXXX
--
-- _norns.screen_export_png("/home/we/dust/krill"..screenshot..".png")

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

globals = include("lib/globals")
lorenz = include("lib/lorenz")
parameters = include("lib/parameters")
sound_controller = include("lib/sound_controller")
midi_helper = include("lib/midi_helper")
w_slash = include("lib/w_slash")
externals = include("lib/externals")
gui = include("lib/gui")
vuja_de = include("lib/vuja_de")


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
        -- local x = pixels[pixels.active].x_display
        -- local y = pixels[pixels.active].y_display
      end
    end,
    division = 1/256, --1/16,
    enabled = true
  }
  
  
  for i=1,VJD_MAX_PATTERNS,1 do
    
    vuja_de_patterns[i]= krill_lattice:new_pattern{
      action = function(t) 
        -- play note from quant grid
        local active = pixels[pixels.active]
        vuja_de:update_length()
        if active and params:get("engine_mode") == 2 then -- vuja de mode
          -- vuja_de:update()
          sound_controller:play_vuja_de_note(i)
        end
      end,
      division = 1/5, --3/1, --1/8, --1/16,
      enabled = false
    }
  end


  clock.run( function()
    while true do

      if norns.menu.status()  == false then
        screen.aa(0)
        if params:get("grid_display") == 2 and gui_level > 0 then 
          sound_controller:display() 
        end
        gui:display()
        -- screen.update()
        screen.aa(1)
        lorenz.display(true)
      else
        lorenz.display(false)
      end


      if lz_x then
        local param_val = util.linlin(0,1,-40,40,lz_x)/10
        local param_val1 = util.linlin(0,1,-50,40,lz_y)/10
        -- if lz_x > 0.1 then params:set("wsyn_pluckylog", 1) end
        
        -- params:set("wsyn_fm_ratio_numerator", param_val)
        -- local rand = math.random(4) == 1 and 1 or 0
        -- if rand == 1 then params:set("wsyn_pluckylog", 1) end
        -- params:set("wsyn_curve", param_val)
        -- params:set("wsyn_ramp", param_val1)
        -- params:set("wsyn_fm_env", param_val1)
      end
      if lz_x then
        -- externals.wiggle(lz_x,lz_y)
      end

      screen.update()
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
  params:set("x_offset",-10)
  params:set("y_scale",0.85)
  print(">>>>>>>>")
  -- params:set("vuja_de_pat_denominator1",8)
  -- params:set("vuja_de_pat_denominator2",8)
  -- params:set("vuja_de_pat_denominator3",8)
  params:set("rise_time",10)
  params:set("fall_time",50)
  params:set("engine_mode",2)
  clock.run(finish_init)
end
function finish_init()
  initializing = false
  clock.sleep(1)
  vuja_de_patterns[1]:start()
  vuja_de_patterns[2]:start()
  vuja_de_patterns[3]:start()
  -- vuja_de_patterns[1].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  -- vuja_de_patterns[2].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  -- vuja_de_patterns[3].division = VDJ_PAT_DEFAULT_NUMERATOR/VDJ_PAT_DEFAULT_DENOMINATOR
  
  params:set("vuja_de_pat_numerator1",VDJ_PAT_DEFAULT_NUMERATOR)
  params:set("vuja_de_pat_denominator1",VDJ_PAT_DEFAULT_DENOMINATOR)
  params:set("vuja_de_pat_numerator2",VDJ_PAT_DEFAULT_NUMERATOR)
  params:set("vuja_de_pat_denominator2",VDJ_PAT_DEFAULT_DENOMINATOR)
  params:set("vuja_de_pat_numerator3",VDJ_PAT_DEFAULT_NUMERATOR)
  params:set("vuja_de_pat_denominator3",VDJ_PAT_DEFAULT_DENOMINATOR+3)
  -- params:set("engine_mode",1)

end

function init_polling()
  -- pitch_poll = poll.set("pitch_poll", function(value)
  --   if note_start == true then
  --     note_start = false
      
  --   end
  -- end)

  next_note_poll = poll.set("next_note_poll", function(value)
    -- sound_controller:play_krill_note(value)


    -- if params:get("engine_mode") == 1 then
    --   sound_controller:play_krill_note(value)
    -- end

    -- note_start = true
    -- print("note_start_poll",rise,fall)l
  end)

  rise_poll = poll.set("rise_poll", function(value)
    -- print("rise done",value)
    prev_rise = rise

    if params:get("engine_mode") == 1 then
      -- sound_controller:play_krill_note(value)
    else
      -- sound_controller:play_vuja_de_note()
    end

    rise = value * params:get("env_scalar")/100
  end)

  fall_poll = poll.set("fall_poll", function(value)
    prev_fall = fall
    fall = value * params:get("env_scalar")/100
    if params:get("engine_mode") == 1 then
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
  next_note_poll:start()
  rise_poll:start()
  fall_poll:start()
end


