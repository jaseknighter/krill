local vuja_de = {}
vuja_de.__index = vuja_de

function vuja_de:new()
  local vd={}
  setmetatable(vd, vuja_de)


  vd.seq = s{60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60}

  return vd
end

function vuja_de:display()

end

function vuja_de:update_length()
  self.seq.length = params:get("loop_length")
end

-- from MI Marbles: https://mutable-instruments.net/modules/marbles/manual/
-- From 7 o’clock to 12 o’clock, this probability goes from 0 (completely random) to 1 (locked loop).
-- At 12 o’clock, the module is thus stuck in a loop, because it never generates fresh random data. In this case, the illuminated pushbuttons [F] and [G] blink.
-- From 12 o’clock to 5 o’clock, the probability of randomly jumping within the loop goes from 0 to 1.
-- At 5 o’clock, the module thus plays random permutations of the same set of decisions/voltages.
function vuja_de:get_note(div_id)
  self.prob = params:get("vuja_de_prob")

  local new_prob = math.random()
  local active_sector=sound_controller:get_active_sector()
  if active_sector and self.prob <= 0 and new_prob > math.abs(tonumber(self.prob)/10) then
    local octave =  active_sector.row - 1
    local note =    active_sector.col
    local doo_param = params:lookup_param("vuja_de_oct_offset"..div_id)
    local doo_options = doo_param.options
    local div_oct_offset = doo_options[params:get("vuja_de_oct_offset"..div_id)]
    local notes_per_octave = fn.get_num_notes_per_octave()
    
    local next_note = (((octave+div_oct_offset)*notes_per_octave)+note)+(params:get("root_note")-1)
    -- print("active_sector.row, active_sector.col,octave,next_note,div_oct_offset",active_sector.row, active_sector.col,octave, next_note,div_oct_offset)
    local next_seq_ix = util.clamp(self.seq.ix+1,1,self.seq.length)
    self.seq[next_seq_ix] = next_note
  elseif self.prob > 0 and new_prob > tonumber(self.prob)/10 then
    -- local next_seq_ix = util.clamp(self.seq.ix+1,1,self.seq.length)
    local next_seq_ix = util.clamp(math.ceil(new_prob*self.seq.length),1,self.seq.length)
    self.seq:select(next_seq_ix)
  end
  
  
  return self.seq()
end

return vuja_de