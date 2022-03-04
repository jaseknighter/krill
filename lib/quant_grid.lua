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
  screen.level(2)
  screen.move(self.x,self.y)
  screen.rect(self.x,self.y,self.w,self.h)
  screen.stroke()
  screen.update()
  -- print(1)
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

function quant_grid:display_sectors()
  for i=1,#quant_grid.sectors,1 do
    for j=1,#quant_grid.sectors[i],1 do
      quant_grid.sectors[i][j]:display()
    end
  end
end

return quant_grid