-- //https://github.com/p3r7/osc-cast/blob/main/lib/mod.lua

local mod_matrix = {}

mod_matrix.lookup = {}
mod_matrix.params = {}

mod_matrix.num_inputs=5
mod_matrix.num_outputs=7
mod_matrix.active_input=1
mod_matrix.active_output=1
mod_matrix.active_inputs = {}
mod_matrix.active_outputs = {}
mod_matrix.selecting_param = "in"
mod_matrix.active_pp_option=1
mod_matrix.default_pp_option_selections={1,4,1,1}
mod_matrix.enabled_options={"off","on"}
mod_matrix.level_options={0,1/4,1/2,1,2,10}
mod_matrix.self_mod_options = {"none","inv","rect"}
mod_matrix.relative_mod_options = {"none","and","or"}

--tables to be saved/recalled (for save_load.lua)
mod_matrix.inputs={}
mod_matrix.outputs={}
mod_matrix.patch_points={}


function mod_matrix:init()
  mod_matrix:enrich_param_actions()
end

function mod_matrix:enrich_param_actions()
  for p_id, p_ix in pairs(params.lookup) do
    local p = params.params[p_ix]
    -- if p ~= nil and p.osc_casted == nil then -- edge case where sync issue between `params.lookup` & `params.params`
    if p ~= nil  then -- edge case where sync issue between `params.lookup` & `params.params`
      -- p.osc_casted = true
      p.og_action = fn.clone_function(p.action)
      p.action = function(x)
        -- do something
        p.og_action(x)
        self:process_updated_param(p_ix,p_id,params:get(p_ix))
      end
    end
  end

  table.insert(self.lookup,{name="-------",id=nil})
  for i=1,#params.params,1 do
    local name = params.params[i].name
    local id = params.params[i].id
    local ix = i
    if (   
      -- params.params[i].id ~= nil and 
      params.hidden[i] == false and 
      params.params[i].t ~= 8 and -- text
      -- params.params[i].t ~= 7 and -- group
      params.params[i].t ~= 6 and -- trigger
      params.params[i].t ~= 4 and -- file
      -- params.params[i].t ~= 0 and -- separator
      (id and string.find(id,"pat_lab")) == nil
    ) 
    then

      if params.params[i].t == 7 and #name > 0 then
        table.insert(self.lookup,{name=">>"..name.."<<",id=id})
      elseif params.params[i].t == 0 then
        table.insert(self.lookup,{name="--"..name.."--",id=id})
      else
        table.insert(self.lookup,{name=name,id=id})
        table.insert(self.params,{name=name,id=id,ix=ix})
      end
    end
  end
end

function mod_matrix.enc(n, d)
  mod_matrix:display_params()
  if n==1 then
    mod_matrix.active_gui_sector = util.clamp(mod_matrix.active_gui_sector+d,1,3)
  elseif n==2 then
    if mod_matrix.active_gui_sector == 1 then
      mod_matrix.active_input = util.clamp(mod_matrix.active_input+d,1,mod_matrix.num_inputs)
    elseif mod_matrix.active_gui_sector == 2 then
      if mod_matrix.selecting_param == "in" then
        local input = mod_matrix.inputs[mod_matrix.active_input]
        input =  util.wrap(input+d,1,#mod_matrix.lookup)
        mod_matrix.inputs[mod_matrix.active_input] = input
      end
      mod_matrix.selecting_param = "in"
    elseif mod_matrix.active_gui_sector == 3 then
      mod_matrix.active_pp_option = util.clamp(mod_matrix.active_pp_option+d,1,4)
    end
  elseif n==3 then
    if mod_matrix.active_gui_sector == 1 then
      mod_matrix.active_output = util.clamp(mod_matrix.active_output+d,1,mod_matrix.num_outputs)
    elseif mod_matrix.active_gui_sector == 2 then
      if mod_matrix.selecting_param == "out" then
        local output = mod_matrix.outputs[mod_matrix.active_output]  
        output =  util.wrap(output+d,1,#mod_matrix.lookup)
        mod_matrix.outputs[mod_matrix.active_output] = output
      end
      mod_matrix.selecting_param = "out"
    elseif mod_matrix.active_gui_sector == 3 then
      local option_num = mod_matrix.active_pp_option 
      local pp_values = mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output]
      -- tab.print(pp_values)
      if option_num == 1 then
        -- print(pp_values.enabled)
        mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled = util.clamp(pp_values.enabled+d,1,#mod_matrix.enabled_options)
      elseif option_num == 2 then
        mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].level = util.clamp(pp_values.level+d,1,#mod_matrix.level_options)
      elseif option_num == 3 then
        mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].self_mod = util.clamp(pp_values.self_mod+d,1,#mod_matrix.self_mod_options)
      elseif option_num == 4 then
        mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].relative_mod = util.clamp(pp_values.relative_mod+d,1,#mod_matrix.relative_mod_options)
      end
    end
  end
end

function mod_matrix.key(n,z)
  print("key",n,z)
  if n==0 and k==2 then
    mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled = 1
  elseif n==0 and k==3 then
    mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled = 2
  end
end

-------------------------------------------
--- mod matrix process
-------------------------------------------
function mod_matrix:get_param_props(param)
    --types
    -- 1: number
    -- 2: options
    -- 3: control
    -- 5: taper
    local type = param.t
    local val = params:get(param.id)
    local min, max
    -- tab.print(param.controlspec)
    if type == 1 then      -- 1: number
      min = param.min
      max = param.max
    elseif type == 2 then  -- 2: options
      min = 1
      max = param.count
    elseif type == 3 then  -- 3: control
      -- local raw = param.raw
      min = param.controlspec.minval
      max = param.controlspec.maxval
    elseif type == 5 then  -- 5: taper
      min = param.min
      max = param.max
    end     
    return {val=val,min=min,max=max,type=param.t}
end

function mod_matrix:process_updated_param(ix,id,value)
  -- print("process>>>",ix,id,value)

  -- print(id,name,value)
  for i=1,self.num_inputs,1 do
    local input = self.inputs[i]
    for j=1,self.num_outputs,1 do
      local output = self.outputs[j] 
      if self.patch_points[i] then
        if self.patch_points[i][j] then
          if self.patch_points[i][j].enabled == 2 then
            local pp_input_id    =   mod_matrix.inputs[i] 
            local pp_output_id   =   mod_matrix.outputs[j] 
            -- print("pp_input_id,pp_output_id",pp_input_id,pp_output_id)
            local input_id       = mod_matrix.lookup[pp_input_id].id
            local output_id      = mod_matrix.lookup[pp_output_id].id
            if (input_id == id) then
              local input        = params:lookup_param(input_id)
              local output       = params:lookup_param(output_id)
              
              --get min/max/current val
              local input_obj = mod_matrix:get_param_props(input)
              local output_obj = mod_matrix:get_param_props(output)
              local new_output_value = util.linlin(input_obj.min,input_obj.max,output_obj.min,output_obj.max,input_obj.val)
              new_output_value = output_obj.type ==2 and math.floor(new_output_value) or new_output_value
              params:set(output_id,new_output_value)
              -- print("input_value",input_obj.val)
              -- print("output_value",output_id,new_output_value)
              -- print(input_obj.min,input_obj.max,output_obj.min,output_obj.max,input_obj.val)
              -- print(">>>>>>>>>>>>>")
            end
          end
        end
      end
    end
  end
end

--[[
function mod_matrix:process_matrix()
  for i=1,self.num_inputs,1 do
    local input = self.inputs[i]
    for j=1,self.num_outputs,1 do
      local output = self.outputs[j] 
      if self.patch_points[i] then
        if self.patch_points[i][j] then
          if self.patch_points[i][j].enabled == 2 then
            -- print("enabled?",self.patch_points[i][j],self.patch_points[i][j].enabled)
            local pp_input_id    =   mod_matrix.inputs[i] 
            local pp_output_id   =   mod_matrix.outputs[j] 
            -- print("pp_input_id,pp_output_id",pp_input_id,pp_output_id)
            local input_id       = mod_matrix.lookup[pp_input_id].id
            local output_id      = mod_matrix.lookup[pp_output_id].id
            if input_id and output_id then
              local input        = params:lookup_param(input_id)
              local output       = params:lookup_param(output_id)
              --types
              -- 1: number
              -- 2: options
              -- 3: control
              -- 5: taper
              local input_type   = input.t
              local output_type  = output.t
              --get min/max/current val
              tab.print(input)
            end
          end
        end
      end
    end
  end
end
]]

-------------------------------------------
--- mod matrix gui
-------------------------------------------

----------------------------
-- gui sectors:
--    2 = row/column selection
--    3 = inputs/output selection
--    4 = patch point options
----------------------------
mod_matrix.active_gui_sector = 1
function mod_matrix:display_mod_matrix()
  if initializing == false and self.lookup then
    screen.aa(0)
    mod_matrix:display_inputs()
    mod_matrix:display_outputs()
    mod_matrix:display_params()
    mod_matrix:display_patch_points()
    mod_matrix:display_patch_point_options()
    mod_matrix:update_matrix()
  screen.level(15)
  screen.move(8,8)
  local text
  if self.active_gui_sector == 1 then
    text = "row/col"
  elseif self.active_gui_sector == 2 then
    text = "in/out"
  else 
    text = "pp opt"
  end
  screen.text(text)
  screen.stroke()

    screen.update()
  end
end

function mod_matrix:update_matrix()
  if self.inputs[self.active_input] == nil then
    self.inputs[self.active_input] = 1
  end
  if self.outputs[self.active_output] == nil then
    self.outputs[self.active_output] = 1
  end
  if self.patch_points[self.active_input] == nil then
    self.patch_points[self.active_input] = {}
  end
  if self.patch_points[self.active_input][self.active_output] == nil then
    print("add defaults",self.active_input,self.active_output)
    local enabled_mod  = mod_matrix.default_pp_option_selections[1]
    local level_mod  = mod_matrix.default_pp_option_selections[2]
    local self_mod  = mod_matrix.default_pp_option_selections[3]
    local relative_mod  = mod_matrix.default_pp_option_selections[4]
    self.patch_points[self.active_input][self.active_output] = {
      enabled        =    enabled_mod,    -- options: off, on
      level          =    level_mod,      -- options: 0,1/4,1/2,1,2,10
      self_mod       =    self_mod,       -- options: none,invert,rectify
      relative_mod   =    relative_mod,   -- options: none, and, or
    }
  end

    

end

function mod_matrix:display_params()
  local input = self.inputs[self.active_input]
  local output = self.outputs[self.active_output]
  if self.lookup[input] and self.lookup[output] then
    local input_text = "in: " .. self.lookup[input].name
    local output_text = "out: " .. self.lookup[output].name

    if self.active_gui_sector ~= 2 then
      screen.level(5)
      input_text = string.sub(input_text,1,15)
      output_text = string.sub(output_text,1,15)
      screen.move(5,62)
      screen.text(input_text)
      screen.move(72,62)
      screen.text(output_text)
    elseif self.selecting_param == "in" then
      screen.level((self.active_gui_sector == 2 and self.lookup[input].name and self.lookup[input].id) and 15 or 10)
      screen.move(5,62)
      screen.text(input_text)
    else
      screen.level((self.active_gui_sector == 2 and self.lookup[output].name and self.lookup[output].id) and 15 or 10)
      screen.move(5,62)
      screen.text(output_text)
    end
  end
end

local input_labels = {"a","b","c","d","e"}
local output_labels = {1,2,3,4,5,6,7}
function mod_matrix:display_inputs()
  for i=1,self.num_inputs,1 do
    local level
    if self.active_input == i and self.active_gui_sector == 1 then 
      level = 15 
    elseif self.active_input == i then 
      level = 7
    else
      level = 1
    end
    screen.level(level)
    screen.move(8+50,9*(i+1)-1)
    -- screen.circle(5+56,9*(i+1)-3,2)
    screen.text(input_labels[i])
    if self.active_gui_sector == 2 and self.active_input == i and self.selecting_param == "in" then
      -- screen.fill()
    end
    screen.stroke()
  end
end

function mod_matrix:display_outputs()
  for i=1,self.num_outputs,1 do
    local level
    if self.active_output == i and self.active_gui_sector == 1 then 
      level = 15 
    elseif self.active_output == i then 
      level = 7
    else
      level = 1
    end

    screen.level(level)
    screen.move(9*(i+1)+49,8)
    screen.text(output_labels[i])
    -- screen.circle(9*(i+1)+52,6,2)
    if self.active_gui_sector == 2 and self.active_output == i and self.selecting_param == "out" then
      screen.fill()
    end
    screen.stroke()
  end
end

function mod_matrix:display_patch_points()
  for i=1,self.num_inputs,1 do
    local input = self.inputs[i]
    for j=1,self.num_outputs,1 do
      local output = self.outputs[j] 
      
      
      local level
      if self.patch_points[i] and self.patch_points[i][j] and self.patch_points[i][j].enabled == 2 then
        level = 15
      elseif self.active_input == i and self.active_output == j then
        level = 5
      else
        level = 1
      end
      screen.level(level)
      screen.move(9*(j+1)+51,(9*i)+9)
      screen.circle(9*(j+1)+51,(9*i)+6,3)  
      screen.stroke()

      if self.lookup[input] and self.lookup[input].id then
        screen.move(9*(j+1)+51,(9*i)+9)
        screen.arc(9*(j+1)+51,(9*i)+6,3,math.rad(90),math.rad(270))  
        screen.fill()
        screen.stroke()
      end
      if self.lookup[output] and self.lookup[output].id then
        screen.move(9*(j+1)+51,(9*i)+9)
        screen.arc(9*(j+1)+51,(9*i)+6,3,math.rad(270),math.rad(90))  
        screen.fill()
        screen.stroke()
      end
      -- screen.fill()
    end
  end
end

function mod_matrix:display_patch_point_options()
  local rect_level = self.active_gui_sector == 3 and 15 or 5
  screen.level(rect_level)
  screen.move(5,5)
  screen.rect(5,15,45,39)
  screen.stroke()
  
  if self.patch_points[self.active_input] and self.patch_points[self.active_input][self.active_output] then
    pp = self.patch_points[self.active_input][self.active_output]

    local enabled_mod   = self.enabled_options[self.patch_points[self.active_input][self.active_output].enabled]
    local level_mod     = self.level_options[self.patch_points[self.active_input][self.active_output].level]
    local self_mod      = self.self_mod_options[self.patch_points[self.active_input][self.active_output].self_mod]
    local relative_mod  = self.relative_mod_options[self.patch_points[self.active_input][self.active_output].relative_mod]

    screen.move(8,24)
    screen.level(mod_matrix.active_pp_option == 1 and 15 or 5)
    screen.text("enbl: " .. enabled_mod)
    screen.stroke()
    screen.move(8,32)
    screen.level(mod_matrix.active_pp_option == 2 and 15 or 5)
    screen.text("lvl: " .. level_mod)
    screen.stroke()
    screen.move(8,40)
    screen.level(mod_matrix.active_pp_option == 3 and 15 or 5)
    screen.text("sm: " .. self_mod)
    screen.stroke()
    screen.move(8,48)
    screen.level(mod_matrix.active_pp_option == 4 and 15 or 5)
    screen.text("rm: " .. relative_mod)
    screen.stroke()
  end
end

return mod_matrix

