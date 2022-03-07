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

function quant_sector:display()
  local level = math.floor(5 * gui_level)
  screen.level(level)
  screen.move(self.x,self.y)
  screen.rect(self.x,self.y,self.w,self.h)
  screen.stroke()
end

local quant_grid = {}

function quant_grid:init(rows,cols)
  quant_grid.sectors={}
  local lb = lorenz.boundary
  local q_width =  math.floor(lb[3]-lb[1]/rows)
  local q_height = math.floor(lb[4]-lb[2]/cols)
  for i=1,rows,1 do
    quant_grid.sectors[i]={}
    for j=1,cols,1 do
      local w = q_width/cols
      local h = q_height/rows
      local x = lb[1]+((j-1)*w)
      local y = lb[2]+((i-1)*h)
      local row = i
      local col = j
      quant_grid.sectors[i][j]=quant_sector:new(x,y,w,h,row,col)
      
    end
  end
end

function quant_grid:display()
  for i=1,#quant_grid.sectors,1 do
    for j=1,#quant_grid.sectors[i],1 do
      quant_grid.sectors[i][j]:display()
    end
  end
end

function quant_grid:get_active_sector(active)
  local x=active.x_display
  local y=active.y_display
  for i=1,#quant_grid.sectors,1 do
    for j=1,#quant_grid.sectors[i],1 do
      local s = quant_grid.sectors[i][j]
      -- print(x,y.."    /    "..s.x,s.y,s.w,s.h)
      if x>s.x and x<s.x+s.w and y>s.y and y<s.y+s.h then
        -- active_sector={i,j}
        -- print(x,s.x,s.w,s.y,s.h)
        return {col=i,row=j}
      end
    end
  end

end

function quant_grid:update_note()
  local active = pixels[pixels.active]
  if active then 
    
    local active_sector=quant_grid:get_active_sector(active)
    if active_sector then
      local octave =  active_sector.row
      local note =    active_sector.col
      -- local note_to_play = notes[note]
      -- local note_to_play = notes[octave*note]
      local note_to_play = (octave*note)+60

      local note_tab = {
        pitch = note_to_play,
        level = 5,
        mode = 1
      }

      
      ext.note_on(1,note_tab, "midi")
      -- ext.note_on(1,fn.deep_copy(value_tab),1,1,"sequencer", "jf")
      -- ext.note_on(1,note_tab, "jf")
      ext.note_on(1,note_tab, "crow")
      ext.note_on(1,note_tab, "wsyn")
      -- ext.note_on(1,note_tab, "wdel_ks")
      
      -- ext.note_on(1,value_tab,1,1,"sequencer", "jf")
    

    end
  end
end
return quant_grid