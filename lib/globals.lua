------------------------------
-- global functions
------------------------------

fn = {}

-- utility to clone function (from @eigen)
function fn.clone_function(fn)
  local dumped=string.dump(fn)
  local cloned=load(dumped)
  local i=1
  while true do
    local name=debug.getupvalue(fn,i)
    if not name then
      break
    end
    debug.upvaluejoin(cloned,i,fn,i)
    i=i+1
  end
  return cloned
end


function fn.deep_copy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[fn.deep_copy(orig_key, copies)] = fn.deep_copy(orig_value, copies)
          end
          setmetatable(copy, fn.deep_copy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function fn.get_num_decimal_places(num)
  local num_str = tostring(num)
  if type(num) == "number" and string.find(num_str,"%.") then
    local num_decimals = #num_str - string.find(num_str,"%.")
    return num_decimals
  else
    return nil
  end
end

function fn.constrain_decimals(val_to_constrain, source_val)
  if type(source_val) == "number" then
    local num_decimals = fn.get_num_decimal_places(source_val)
    local constrained_val = fn.round_decimals(val_to_constrain, num_decimals)
    return constrained_val
  else
    return val_to_constrain
  end
end

function fn.round_decimals (value_to_round, num_decimals, rounding_direction)
  local num_decimals = num_decimals and num_decimals or 2
  local rounding_direction = rounding_direction and rounding_direction or "down"
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "down" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.ceil(value_to_round * mult + 0.5) / mult
  end
  return rounded_val
end


function fn.get_table_from_string(str,delimiter)
  local result = {}
  if delimiter then
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
  else
    print("no delimiter")
    return 1
  end
end

function fn.fraction_to_decimal(fraction)
  local fraction_tab = fn.get_table_from_string(fraction,"/")
  if #fraction_tab == 2 then
    return fraction_tab[1]/fraction_tab[2]
  else
    return fraction
  end
end

-- morphing function
-- note: the last two parameters are "private" to the function and don't need to included in the inital call to the function
-- example: `morph(my_callback_function,1,10,2,10,"log")`
function fn.morph(callback,s_val,f_val,duration,steps,shape, id, steps_remaining, next_val)
  local start_val = s_val < f_val and s_val or f_val
  local finish_val = s_val < f_val and f_val or s_val
  local increment = (finish_val-start_val)/steps
  if next_val and steps_remaining < steps then
    local delay = duration/steps
    clock.sleep(delay)
    local return_val = next_val
    if s_val ~= f_val then
      callback(return_val, id)
    else
      callback(s_val, id)
    end
  end
  local steps_remaining = steps_remaining and steps_remaining - 1 or steps 
  
  if steps_remaining >= 0 then
    local value_to_convert
    if next_val == nil then
      value_to_convert = start_val
    elseif s_val < f_val then
      -- value_to_convert = next_val and s_val + ((steps-steps_remaining) * increment) 
      value_to_convert = next_val and start_val + ((steps-steps_remaining) * increment) 
    else
      value_to_convert = next_val and finish_val - ((steps-steps_remaining) * increment) 
    end 

    if shape == "exp" then
      next_val = util.linexp(start_val,finish_val,start_val,finish_val, value_to_convert)
    elseif shape == "log" then
      next_val = util.explin(start_val,finish_val,start_val,finish_val, value_to_convert)
    else
      next_val = util.linlin(start_val,finish_val,start_val,finish_val, value_to_convert)
    end
    clock.run(fn.morph,callback,s_val,f_val,duration,steps,shape, id, steps_remaining,next_val)
  end
end



-- scale/note/quantize functions
SCALE_LENGTH_DEFAULT = 60 
ROOT_NOTE_DEFAULT = 33 --(A0)
NOTE_OFFSET_DEFAULT = 33 --(A0)
scale_names = {}
notes = {}
current_note_indices = {}

for i= 1, #MusicUtil.SCALES do
  table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
end

fn.build_scale = function()
  notes = {}
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), SCALE_LENGTH_DEFAULT)
  -- notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), params:get("scale_length"))
  -- local num_to_add = SCALE_LENGTH_DEFAULT - #notes
  -- local scale_length = params:get("scale_length") and params:get("scale_length") or SCALE_LENGTH_DEFAULT
  -- for i = 1, num_to_add do

  -- local scale_length = SCALE_LENGTH_DEFAULT
  -- for i = 1, scale_length do
  --   table.insert(notes, notes[scale_length])
    -- print("scale",i,)
    -- table.insert(notes, notes[SCALE_LENGTH_DEFAULT - num_to_add])
  -- end
  -- engine.update_scale(table.unpack(notes))
end

fn.get_num_notes_per_octave = function()
  local starting_note = notes[1]
  for i=2,#notes,1 do
    if notes[i]-starting_note < 12 then
      -- do nothing
    else
      return i-1
    end
  end
end

fn.quantize = function(note_num)
  local new_note_num
  for i=1,#notes-1,1 do
    if note_num >= notes[i] and note_num <= notes[i+1] then
      if note_num - notes[i] < notes[i+1] - note_num then
        new_note_num = notes[i]
      else
        new_note_num = notes[i+1]
      end
      break
    end
  end
  if new_note_num == nil then 
    if note_num < notes[1] then 
      new_note_num = notes[1]
    else
      new_note_num = notes[#notes]
    end
  end
  return new_note_num
end

-------------------------------------------
-- global variables
-------------------------------------------
folder_path = norns.state.data .. "krill_data/" 
AUTOSAVE_DEFAULT=2

-- UI_DISPLAY_DEFAULT possible values:
-- 1 = never show grid. only show UI when using encoders
-- 2 = show grid and UI when using encoders
-- 3 = always show grid and UI
UI_DISPLAY_DEFAULT=2
UI_DISPLAY_SQUIGGLES=2

k1_active = false
k2_active = false
k3_active = false
page = 1
CENTER_X = 84
CENTER_Y = 32
blank_pixel = screen.peek(1,1,2,2)
gui_level = UI_DISPLAY_DEFAULT < 3 and 0 or 1
set_gui_level_initiated = false
rise = 1.5
fall = 1.5
NUM_OCTAVES_DEFAULT = 4
NUM_OCTAVES_MAX = 14
midi_pitch_offset = 60
SCREEN_REFRESH_DENOMINATOR = 10
vuja_de_patterns = {}
VJD_MAX_DIVISIONS = 6
VJD_MAX_PATTERN_NUMERATOR = 512
VJD_MAX_PATTERN_DENOMINATOR = 512
VDJ_PAT_DEFAULT_NUMERATOR = 1
VDJ_PAT_DEFAULT_DENOMINATOR = 2
VJD_PAT_DEFAULT_DIVS = {
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
  {"1","1/2","1/4","1/8","1/16","1/32","1/64"},
}
slide="off"
lz_x_val = 0 
lz_y_val = 0 
ENV_MAX_LEVEL_DEFAULT = 10
LORENZ_WEIGHTS_DEFAULT = {{1,0,0}, {0,1,0}, {0,0,1}, {2.0,1.0,1.0}}
sequencing_mode = 2
menu_map = {}
sub_menu_map = {}
midi_devices = {"-----"}
play_enabled = false
MIDI_LZ_X_CC = 100
MIDI_LZ_Y_CC = 101
MIDI_LFO_CC_DEFAULT = 101 
MIDI_LFO_CHANNEL_DEFAULT = 1
