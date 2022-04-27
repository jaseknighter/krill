local quant_sector ={}
quant_sector.__index = quant_sector


function quant_sector:new(x,y,w,h,row,col)
  local qs={}
  setmetatable(qs, quant_sector)

  qs.x = x -- x
  qs.y = y -- y
  qs.w = w -- width
  qs.h = h -- height
  qs.row = row -- row id
  qs.col = col -- col id
  return qs
end

function quant_sector:display(fill)
  local level = fill == true and 0 or math.ceil(5 * gui_level)
  screen.level(level)
  screen.move(self.x,self.y)
  screen.rect(self.x,self.y,self.w,self.h)
  screen.stroke()
  if fill == true then
    screen.fill()
  end
end

local sound_controller = {}

sound_controller.random_div_div = 1

function sound_controller:init(rows,cols)
  sound_controller.sectors={}
  local lb = lorenz.boundary
  local q_width =  math.floor(lb[3]-lb[1])
  local q_height = math.floor(lb[4]-lb[2])
  for i=1,rows,1 do
    sound_controller.sectors[i]={}
    for j=1,cols,1 do
      local w = q_width/cols
      local h = q_height/rows
      local x = lb[1]+((j-1)*w)
      local y = lb[2]+((i-1)*h)
      local row = i
      local col = j
      sound_controller.sectors[i][j]=quant_sector:new(x,y,w,h,row,col)
      
      if i==1 and j==1 then 
        sound_controller.x = x
        sound_controller.y = y
      elseif i==rows and j==cols then 
        sound_controller.w = x + w - sound_controller.x
        sound_controller.h = y + h - sound_controller.y
      end
    end
  end
end

function sound_controller:display(fill)
  for i=1,#sound_controller.sectors,1 do
    for j=1,#sound_controller.sectors[i],1 do
      sound_controller.sectors[i][j]:display(fill)
    end
  end
end

function sound_controller:get_dimensions()
  local x = sound_controller.x
  local y = sound_controller.y
  local w = sound_controller.w
  local h = sound_controller.h
  return {x=x,y=y,w=w,h=h}
end

sound_controller.active_pixels = {}
function sound_controller:get_active_sector()
  local active = pixels[pixels.active]
  local x=active.x_display
  local y=active.y_display
  for i=1,#sound_controller.sectors,1 do
    for j=1,#sound_controller.sectors[i],1 do
      local s = sound_controller.sectors[i][j]
      if x>s.x and x<s.x+s.w and y>s.y and y<s.y+s.h then
        return {col=i,row=j}
      end
    end
  end

end

function sound_controller.play_engine(note)
  -- engine.note_off()
  engine.note_on(note,1)
end

function sound_controller.note_on(note_tab,mode)
  if initializing == false and play_enabled == true then
    -- note_tab.pitch = util.clamp(note_tab.pitch,1,#notes)
    if params:get("quantize") == 2 then          
      note_tab.pitch = fn.quantize(note_tab.pitch)
    end
    
    params:set("active_note",note_tab.pitch)
    
    if mode==1 or (params:get("vjd_div_asn_engine1") == note_tab.div_id or params:get("vjd_div_asn_engine2") == note_tab.div_id) then
      sound_controller.play_engine(note_tab.pitch)
    end

    if params:get("output_midi") == 2 then
      ext.note_on(1,note_tab, "midi",mode)
    end
    -- ext.note_on(1,fn.deep_copy(value_tab),1,1,"sequencer", "jf")
    if params:get("output_jf") == 2 then
      ext.note_on(1,note_tab, "jf",mode)
    end 
    if params:get("output_crow1") == 2 then
      ext.note_on(1,note_tab, "crow",mode)
    end
    if params:get("output_wsyn") == 2 then
      ext.note_on(1,note_tab, "wsyn",mode)
    end
    if params:get("output_wdel_ks") == 2 then
      ext.note_on(1,note_tab, "wdel_ks",mode)
    end
  end
end


sound_controller.sleepy_timing = false
function sound_controller.play_krill_note(value)
  if sound_controller.sleepy_timing == false then
    local sleepy_time = (((rise+fall)*(params:get("env_scalar")/100) * lorenz_sample_val)) * (math.random()) 
    sound_controller.sleepy_timing=true
    clock.sleep(0.05+sleepy_time)
    local notes_per_octave = fn.get_num_notes_per_octave()
    local num_octaves = #sound_controller.sectors
    local num_notes = notes_per_octave * num_octaves 
    local note = math.floor(util.linlin(0,2,1,num_notes,math.random()*2))
    note = (note)+midi_pitch_offset - (notes_per_octave*3)
    local note_tab = {
      pitch = note,
      level = params:get("env_max_level"),
      mode = 1
    }

    sound_controller.note_on(note_tab,1)
    sound_controller.sleepy_timing=false
  end
end

function sound_controller:play_vuja_de_note(div_id)
  local note_to_play = vuja_de:get_note(div_id)

  local note_tab = {
    pitch = note_to_play,
    level = params:get("env_max_level"),
    mode = 1,
    div_id = div_id
  }

  -- local mode
  -- if params:get("vuja_de_engine_mode"..div_id) == 1 then 
  --   mode = params:get("engine_mode")
  --   engine.engine_mode(mode-1)
  -- elseif params:get("vuja_de_engine_mode"..div_id) == 2 then 
  --   mode = 1
  -- else
  --   mode = 2
  -- end
  -- engine.engine_mode(mode-1)

  sound_controller.note_on(note_tab,2)
end

return sound_controller