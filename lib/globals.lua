------------------------------
-- global functions
------------------------------

fn = {}

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

function fn.round_decimals (value_to_round, num_decimals, rounding_direction)
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "up" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
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
SCALE_LENGTH_DEFAULT = 45 
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

  local scale_length = SCALE_LENGTH_DEFAULT
  for i = 1, scale_length do
    table.insert(notes, notes[scale_length])
    -- table.insert(notes, notes[SCALE_LENGTH_DEFAULT - num_to_add])
  end
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

fn.round_decimals = function (value_to_round, num_decimals, rounding_direction)
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "up" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  end
  return rounded_val
end

-------------------------------------------
-- global variables
-------------------------------------------

CENTER_X = 84
CENTER_Y = 32
blank_pixel = screen.peek(1,1,2,2)
gui_level = 0
set_gui_level_initiated = false