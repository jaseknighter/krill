-- cellular automata class
-- from: https://natureofcode.com/book/chapter-7-cellular-automata/

------------------------------
-- notes and todos
-- 
------------------------------
-- local vector = include("nature_of_code/lib/vector")

local cellular_automata = {}
cellular_automata.__index = cellular_automata


-- make a new mover
function cellular_automata:new(initial_cells)

  local ca = {}
  setmetatable(ca, cellular_automata)

  ca.screen_size = vector:new(127,64)
  ca.generations = {}
  ca.cells = {}
  ca.ruleset = {}
  ca.w = 1
  
  -- the ca should keep track of how many generations
  ca.generation = 0
  ca.start_generation = 0
  ca.cells_length = ca.screen_size.x/ca.w
  
  ca.ruleset_length = 8
  
  local center_cell = math.floor(ca.cells_length/2)

  function ca.set_ruleset_table(ruleset_table)
    ca.ruleset = ruleset_table
  end

  local ruleset_table = {1,1,1,1,1,1,1,1}
  -- local ruleset_table = {0,0,0,0,0,0,0,0}
  -- local ruleset_table = {0,1,0,1,1,0,1,0}
  
  ca.digits = {}
  for i=0,9 do ca.digits[i] = string.char(string.byte('0')+i) end
  for i=10,36 do ca.digits[i] = string.char(string.byte('A')+i-10) end

  ca.set_ruleset_table(ruleset_table)
  

  function ca.increment_ruleset(delta)
    print("increment",ca.get_ruleset_id() + delta)
    if (ca.get_ruleset_id() + delta > 0 and 
        ca.get_ruleset_id() + delta < 256) then

      local new_ruleset_id = ca.get_ruleset_id() + delta
      local rs = ca.set_ruleset(new_ruleset_id)
      return rs
    end
  end

  function ca.set_start_generation(delta)
    if ca.start_generation + delta >= 0 then
      ca.start_generation = ca.start_generation + delta
    end
  end
  
  function ca.reset_start_generation()
    ca.start_generation = 0
  end

  function ca.set_initial_cells()
    center_cell = center_cell
    for i=1, ca.cells_length, 1
    do
      if i == center_cell then
        ca.cells[i] = 1
      else 
        ca.cells[i] = 0
      end
    end
  end

  -- unless initial_cells param is provided,
  --initialize the cells with all 0s 
  -- except for the center cell which gets a 1
  if (initial_cells) then
    ca.cells = initial_cells
  else
    ca.set_initial_cells()
  end

  
  function ca.set_size(size)
    ca.w = size  
  end
  
  function ca.get_ruleset()
    return ca.ruleset
  end

  function ca.get_ruleset_string(ruleset)
    local ruleset_string = ""
    for i = 1, #ruleset, 1
      do
        ruleset_string = ruleset_string .. ruleset[i]
      end
      -- print("current ruleset: ", tonumber(tostring(ruleset_string),2), ": ", ruleset_string)
      return ruleset_string
  end
  
  function ca.get_ruleset_id(ruleset)
    local ruleset_string = ""
    for i = 1, ca.ruleset_length, 1
    do
      ruleset_string = ruleset_string .. ca.ruleset[i]
    end
    local id = tonumber(tostring(ruleset_string),2)
    -- print (id)
    return id
  end 
  
  function ca:string_cut(str, start, finish)
    -- print(str,start,finish)
    return string.sub(str, start, finish)
  end

  function ca.number_convert(number, base)
    local s = ""
    repeat
       local remainder = number%base
       s = ca.digits[remainder]..s
       number = (number-remainder)/base
    until number==0
    return s
 end

  function ca.set_ruleset(ruleset_id)
    ca.set_initial_cells()
    ca.reset_start_generation()
    ca.generations = {}
    ca.generation = 0
    local new_ruleset = tostring(ca.number_convert(ruleset_id,2))
    -- print(tostring(#new_ruleset))
    if #new_ruleset < ca.ruleset_length then
      local zeros_to_add = ca.ruleset_length - #new_ruleset 
      for i = 1, zeros_to_add, 1
      do
        new_ruleset = "0" .. new_ruleset
      end
    end
    
    local ruleset_string = ""
    for i = 1, ca.ruleset_length, 1
    do
      ca.ruleset[i] = tonumber(ca:string_cut(new_ruleset, i, i))
      ruleset_string = ruleset_string .. ca.ruleset[i]
    end
    print("using new ruleset: ", tonumber(tostring(ruleset_string),2), ": ", ruleset_string)
    return ca.get_ruleset()
  end
  
  function ca.rules(a, b, c)
    local s = a .. b .. c
    -- print("generation: ", ca.generation)
    
    -- convert binary to decimal
    local index = tonumber(tostring(s),2)
    -- print(">>>>>>>>")
    local rs = ca.ruleset[index + 1]
    rs = rs == nil and 0 or rs
    -- print("rs", rs)
    return rs
  end


  function ca.generate_random_ruleset()
    local ruleset_string = ""
    for i = 1, ca.ruleset_length, 1
    do
      ca.ruleset[i] = math.random(0,1)
      ruleset_string = ruleset_string .. ca.ruleset[i]
    end
    print("using new random ruleset: ", tonumber(tostring(ruleset_string),2), ": ", ruleset_string)
  end
  
  -- function to compute the next generation
  function ca.generate()
    if (#ca.generations < ca.screen_size.y/ca.w + ca.start_generation) then
      local nextgen = {}
      -- fill the nextgen array with 0s for the new values 
      for i=1, ca.cells_length, 1
      do
        nextgen[i] = 0
      end
      
  
      -- local left  = ca.cells[ca.cells_length]
      -- local me    = ca.cells[1]
      -- local right = ca.cells[2]
      -- nextgen[1] = ca.rules(left, me, right)
      
      for i=2, ca.cells_length-1, 1
      do
        left  = ca.cells[i-1]
        me    = ca.cells[i]
        right = ca.cells[i+1]
        nextgen[i] = ca.rules(left, me, right)
        -- print(nextgen[i])
      end

      -- left  = ca.cells[ca.cells_length-1]
      -- me    = ca.cells[ca.cells_length]
      -- right = ca.cells[1]
      -- nextgen[1] = ca.rules(left, me, right)


      table.insert(ca.generations, nextgen)
      ca.cells = nextgen
      
      -- increment the generation counter
      ca.generation = ca.generation + 1
    end
  end
    
  
  function ca.display(shape)
    for i=1, #ca.generations, 1
    do
      if (i >= ca.start_generation) then
        -- ca.set_size(math.random(1,10))
        local cells = ca.generations[i]
        for j=1, ca.cells_length, 1
        do
          if cells[j] == 1 then
            if (shape == "rect" or shape == nil) then
              screen.rect(
                j*ca.w, 
                ca.w*i+10 - (ca.start_generation*ca.w), 
                ca.w, 
                ca.w)
            elseif (shape == "arc") then
              screen.arc(
                j*ca.w, 
                ca.w*i+10 - (ca.start_generation*ca.w), 
                ca.w,
                0,
                degree_to_radian(90))
                screen.stroke()
            end
          end
        end
      end
    end
    
    screen.move(0,10) 
    local ruleset_string = ca.get_ruleset_string(ca.ruleset)
    local ruleset_id = ca.get_ruleset_id(ca.ruleset)
    screen.text("ruleset: " .. ruleset_id .. ": " .. ruleset_string)
  end
  
  
  return ca
  
end

return cellular_automata