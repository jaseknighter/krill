-- //https://github.com/p3r7/osc-cast/blob/main/lib/mod.lua

-- todo: fix mappings when input/output spans positive & negative for types other than control
          -- note: see how controlspec maping/unmaping appears to address this????

local mod_matrix              = {}
mod_matrix.lookup             = {}
mod_matrix.params             = {}
mod_matrix.num_gui_sectors    = 5
mod_matrix.active_input       = 1
mod_matrix.active_output      = 1
mod_matrix.active_input_val   = ""
mod_matrix.active_output_val  = ""
mod_matrix.active_inputs      = {}
mod_matrix.active_outputs     = {}
mod_matrix.selecting_param    = "in"

-- pp options
mod_matrix.active_pp_option=1
mod_matrix.active_crow_pp_option=1
mod_matrix.active_midi_pp_option=1
-- mod_matrix.default_pp_option_selections={1,101,1}  -- set level (2nd value) to 1
mod_matrix.default_pp_option_selections={1,11,1}      -- set level (2nd value) to 0.1
mod_matrix.enabled_options={"off","on"}
mod_matrix.level_options={}
mod_matrix.level_range_options={}

-- mod_matrix.input_labels = {"a","b","c","d","e"}
mod_matrix.input_labels = {"a","b","c","d"}
mod_matrix.output_labels = {1,2,3,4,5,6,7}
mod_matrix.num_inputs=#mod_matrix.input_labels
mod_matrix.num_outputs=#mod_matrix.output_labels

mod_matrix.pressing = false
mod_matrix.setting_scrolling_input = false
mod_matrix.setting_scrolling_output = false

for i=0,1000 do
  table.insert(mod_matrix.level_options,i*0.01)
end

for i=0,1000 do
  table.insert(mod_matrix.level_range_options,i*0.01)
end

-- mod_matrix.self_mod_options = {"none","inv","rect"}
-- mod_matrix.relative_mod_options = {"none","and","or"}

-- crow output options
mod_matrix.active_crow_output_option=1
mod_matrix.default_crow_option_selections={1,3,1} -- crow enabled, crow output, crow_slew
mod_matrix.crow_enabled_options={"off","on"}
mod_matrix.crow_output_options={1,2,3,4}

mod_matrix.crow_slew_options={}
for i=0,2000 do
  table.insert(mod_matrix.crow_slew_options,i)
end

-- midi output options
mod_matrix.active_midi_output_option=1
mod_matrix.default_midi_option_selections={1,1,1} -- midi enabled, midi cc, midi channel
mod_matrix.midi_cc_enabled_options={"off","on"}
mod_matrix.midi_cc_options={}
for i=1,127 do
  table.insert(mod_matrix.midi_cc_options,i)
end
mod_matrix.midi_channel_options={}
for i=1,16 do
  table.insert(mod_matrix.midi_channel_options,i)
end

--tables to be saved/recalled (for save_load.lua)
mod_matrix.inputs={}
mod_matrix.outputs={}
mod_matrix.patch_points={}




------------------------
--lfo setup
------------------------


-- for lib/hnds
mod_matrix.lfo = include("lib/hnds")

mod_matrix.lfo_types = {"sine", "square", "s+h"}
mod_matrix.lfo_index = nil






------------------------
-- mod_matrix init
------------------------

function mod_matrix:init()
  mod_matrix.lfo.init()
  mod_matrix:enrich_param_actions()
end
 

function mod_matrix:enrich_param_actions()
  for p_id, p_ix in pairs(params.lookup) do
    local p = params.params[p_ix]
    -- if p ~= nil and p.osc_casted == nil then -- edge case where sync issue between `params.lookup` & `params.params`
    if p ~= nil  then -- edge case where sync issue between `params.lookup` & `params.params`
      -- p.osc_casted = true
      p.og_action_mod_matrix = fn.clone_function(p.action)
      p.action = function(x)
        -- do something
        p.og_action_mod_matrix(x)
        self:process_updated_param(p_id)
        -- self:process_updated_param(p_ix,p_id,params:get(p_ix))
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
      elseif params.params[i].t == 0 and name ~= "" then
        table.insert(self.lookup,{name="--"..name.."--",id=id})
      elseif name ~= "" then
        table.insert(self.lookup,{name=name,id=id})
        table.insert(self.params,{name=name,id=id,ix=ix})
      end
    end
  end
end

function mod_matrix.clear_row_col(input_row,output_col)
  mod_matrix.inputs[input_row] = 1
  mod_matrix.outputs[output_col] = 1
end

function mod_matrix.enc(n, d)
  mod_matrix.active_input_val        = ""
  mod_matrix.active_output_val       = "" 
  mod_matrix.active_output_crow_val  = "" 
  mod_matrix.active_output_midi_val  = "" 
  mod_matrix:display_params()
  if n==1 then
    mod_matrix.active_gui_sector = util.clamp(mod_matrix.active_gui_sector+d,1,mod_matrix.num_gui_sectors)
  elseif n==2 then
    if mod_matrix.active_gui_sector == 1 or k1_active then
      mod_matrix.active_input = util.clamp(mod_matrix.active_input+d,1,mod_matrix.num_inputs)
    elseif mod_matrix.active_gui_sector == 2 then
      if mod_matrix.selecting_param == "in" then
        local input = mod_matrix.inputs[mod_matrix.active_input]
        if k2_active then
          local found_separator_sub_menu = false
          while found_separator_sub_menu == false do
            local input_name = mod_matrix.lookup[input].name
            input =  util.wrap(input+d,1,#mod_matrix.lookup)
            input_name = mod_matrix.lookup[input].name
            -- if string.find(input_name,"%-%-") ~= nil or string.find(input_name,">>") ~= nil then
            if string.find(input_name,">>") ~= nil then
              print("input separator: ",input_name)
              found_separator_sub_menu = true
            end
          end
        else
          input =  util.wrap(input+d,1,#mod_matrix.lookup)
        end
        mod_matrix.inputs[mod_matrix.active_input] = input
        for i=1,#mod_matrix.output_labels do
          if mod_matrix.patch_points[mod_matrix.active_input][i] then
            mod_matrix.patch_points[mod_matrix.active_input][i].enabled = 1
          end
        end
      end
      mod_matrix.selecting_param = "in"
    elseif mod_matrix.active_gui_sector == 3 then
      mod_matrix.active_pp_option = util.clamp(mod_matrix.active_pp_option+d,1,#mod_matrix.default_pp_option_selections)
    elseif mod_matrix.active_gui_sector == 4 then
      mod_matrix.active_crow_pp_option = util.clamp(mod_matrix.active_crow_pp_option+d,1,#mod_matrix.default_crow_option_selections)
    elseif mod_matrix.active_gui_sector == 5 then
      mod_matrix.active_midi_pp_option = util.clamp(mod_matrix.active_midi_pp_option+d,1,#mod_matrix.default_midi_option_selections)
    end
  elseif n==3 then
    if mod_matrix.active_gui_sector == 1 or k1_active then
      mod_matrix.active_output = util.clamp(mod_matrix.active_output+d,1,mod_matrix.num_outputs)
    elseif mod_matrix.active_gui_sector == 2 then
      if mod_matrix.selecting_param == "out" then
        local output = mod_matrix.outputs[mod_matrix.active_output]  
        if k2_active then
          local found_separator_sub_menu = false
          while found_separator_sub_menu == false do
            local output_name = mod_matrix.lookup[output].name
            output =  util.wrap(output+d,1,#mod_matrix.lookup)
            output_name = mod_matrix.lookup[output].name
            if string.find(output_name,">>") ~= nil then
            -- if string.find(output_name,"%-%-") ~= nil or string.find(output_name,">>") ~= nil then
              print("output separator: ",output_name)
              found_separator_sub_menu = true
            end
          end
        else
          output =  util.wrap(output+d,1,#mod_matrix.lookup)
        end
        mod_matrix.outputs[mod_matrix.active_output] = output
        for i=1,#mod_matrix.input_labels do
          if mod_matrix.patch_points[i] and mod_matrix.patch_points[i][mod_matrix.active_output] then
            mod_matrix.patch_points[i][mod_matrix.active_output].enabled = 1
          end
        end
      end
      mod_matrix.selecting_param = "out"
    else
      if k2_active then d = d*10 end
      if mod_matrix.active_gui_sector == 3 then 
        local option_num = mod_matrix.active_pp_option 
        local pp_values = mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output]
        if option_num == 1 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled = util.clamp(pp_values.enabled+d,1,#mod_matrix.enabled_options)
        elseif option_num == 2 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].level = util.clamp(pp_values.level+d,1,#mod_matrix.level_options)
        elseif option_num == 3 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].level_range = util.clamp(pp_values.level_range+d,1,#mod_matrix.level_range_options)
        --   mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].self_mod = util.clamp(pp_values.self_mod+d,1,#mod_matrix.self_mod_options)
        -- elseif option_num == 4 then
        --   mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].relative_mod = util.clamp(pp_values.relative_mod+d,1,#mod_matrix.relative_mod_options)
        end
      elseif mod_matrix.active_gui_sector == 4 then -- crow options
        local option_num = mod_matrix.active_crow_pp_option 
        local pp_values = mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output]
        if option_num == 1 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].crow_enabled = util.clamp(pp_values.crow_enabled+d,1,#mod_matrix.crow_enabled_options)
        elseif option_num == 2 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].crow_output = util.clamp(pp_values.crow_output+d,1,#mod_matrix.crow_output_options)
        elseif option_num == 3 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].crow_slew = util.clamp(pp_values.crow_slew+d,1,#mod_matrix.crow_slew_options)
        end
      elseif mod_matrix.active_gui_sector == 5 then -- midi options
        local option_num = mod_matrix.active_midi_pp_option 
        local pp_values = mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output]
        if option_num == 1 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].midi_cc_enabled = util.clamp(pp_values.enabled+d,1,#mod_matrix.midi_cc_enabled_options)
        elseif option_num == 2 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].midi_cc = util.clamp(pp_values.midi_cc+d,1,#mod_matrix.midi_cc_options)
        elseif option_num == 3 then
          mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].midi_channel = util.clamp(pp_values.midi_channel+d,1,#mod_matrix.midi_channel_options)
        end
      end
    end
end
end

function mod_matrix.key(n,z)
  mod_matrix.active_input_val        = ""
  mod_matrix.active_output_val       = "" 
  mod_matrix.active_output_crow_val  = "" 
  mod_matrix.active_output_midi_val  = "" 

  if z==0 and n==2 and k2_active == false then
    if mod_matrix.active_gui_sector < 4 then
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled           =  1
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled           =  1
    elseif mod_matrix.active_gui_sector == 4 then
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].crow_enabled      =  1
    else
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].midi_cc_enabled   =  1
    end
  elseif z==0 and n==3 and k3_active == false then
    if mod_matrix.active_gui_sector < 4 then
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].enabled           =  2
    elseif mod_matrix.active_gui_sector == 4 then
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].crow_enabled      =  2
    else
      mod_matrix.patch_points[mod_matrix.active_input][mod_matrix.active_output].midi_cc_enabled   =  2
    end
  end

  if n == 1 then
    if z == 0 then 
      k1_active = false 
      mod_matrix.pressing = false
    else 
      mod_matrix.pressing = true
      k1_active = true
      -- mod_matrix:delay_key_press("k1_active",true,mod_matrix.pressing,true)
    end
  end
  if n == 2 then
    if z == 0 then 
      k2_active = false 
      mod_matrix.pressing = false
    else 
      if k3_active then
        mod_matrix.clear_row_col(mod_matrix.active_input,mod_matrix.active_output)
      end
      mod_matrix.pressing = true
      clock.run(mod_matrix.delay_key_press,"k2_active",true,mod_matrix.get_pressing,true)
    end
  end
  
  if n == 3 then
    if z == 0 then 
      k3_active = false 
      mod_matrix.pressing = false
    else 
      if k2_active then
        mod_matrix.clear_row_col(mod_matrix.active_input,mod_matrix.active_output)
      end

      mod_matrix.pressing = true
      clock.run(mod_matrix.delay_key_press,"k3_active",true,mod_matrix.get_pressing,true)
    end
  end
end

function mod_matrix.get_pressing()
  return mod_matrix.pressing
end

function mod_matrix.delay_key_press(delay_prop,delay_value,checker_func,checker_value)
  clock.sleep(0.5)
  if checker_func() == checker_value then
    if delay_prop == "k1_active" then
       k1_active = delay_value
    elseif delay_prop == "k2_active" then
      k2_active = delay_value
    elseif delay_prop == "k3_active" then
      k3_active = delay_value
    end
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

function mod_matrix:process_updated_param(id)
  local active_input_val  = ""
  local active_output_val = ""
  local active_output_crow_val = ""
  local active_output_midi_val = ""
  for i=1,self.num_inputs,1 do
    -- local input = self.inputs[i]
    for j=1,self.num_outputs,1 do
      -- local output = self.outputs[j] 
      if self.patch_points[i] then
        if self.patch_points[i][j] then
          -- print(mod_matrix.active_input,mod_matrix.active_output)

          local enabled     =   self.patch_points[i][j].enabled == 2 or
                                self.patch_points[i][j].crow_enabled or
                                self.patch_points[i][j].midi_cc_enabled == 2 
          if enabled then
            local pp_input_id    =   mod_matrix.inputs[i] 
            local pp_output_id   =   mod_matrix.outputs[j] 
            local input_id       = mod_matrix.lookup[pp_input_id].id
            local output_id      = mod_matrix.lookup[pp_output_id].id
            if (input_id == id) then    
              local input        = params:lookup_param(input_id)
              
              --get min/max/current val
              local input_obj = mod_matrix:get_param_props(input)
                              
              --mod matrix out
              if self.patch_points[i][j].enabled == 2 then
                -- print("in/out",input_id, output_id)
                local output           = params:lookup_param(output_id)
                local output_obj       = mod_matrix:get_param_props(output)
                
                local new_output_value
                
                if output_obj.type == 3 then --unmap input vals for control input params
                  input_obj.val = params:lookup_param(output_id).controlspec:unmap(input_obj.val)
                end 

                if output_obj.type == 3 then --map output vals for control output params
                  local mapper_index = util.linlin(input_obj.min,input_obj.max,0,1,input_obj.val)
                  new_output_value = output.controlspec:map(mapper_index)
                else
                  new_output_value = util.linlin(input_obj.min,input_obj.max,output_obj.min,output_obj.max,input_obj.val)
                end
                
                local pp_level         = self.patch_points[i][j].level
                pp_level               = mod_matrix.level_options[pp_level]
                local pp_level_range   = self.patch_points[i][j].level_range
                pp_level_range         = mod_matrix.level_options[pp_level_range]
                local random_range     = util.linlin(0,1,-1,1,math.random())*pp_level_range
                pp_level = pp_level + random_range
                new_output_value = new_output_value * pp_level
                
                if output_obj.type == 1 or output_obj.type == 2 then
                  new_output_value = fn.round_decimals(new_output_value, 0)
                end
                new_output_value = fn.constrain_decimals(new_output_value, params:get(output_id))
                new_output_value = util.clamp(new_output_value,output_obj.min,output_obj.max)            
                
                if mod_matrix.active_input==i and mod_matrix.active_output==j then
                  active_input_val   = input_obj.val
                  active_output_val  = new_output_value
                end
                -- print("output_id,new_output_value",output_id,new_output_value)
                params:set(output_id,new_output_value)
                
              end
              --crow out
              if self.patch_points[i][j].crow_enabled == 2 then
                local output    = self.patch_points[i][j].crow_output
                local volts     = util.linlin(input_obj.min,input_obj.max,-5,10,input_obj.val)
                local slew      = self.patch_points[i][j].crow_slew/1000
                local pp_level  = self.patch_points[i][j].level
                pp_level = mod_matrix.level_options[pp_level]
                volts = volts * pp_level
                volts = util.clamp(volts,-5,10)
                mod_matrix.crow_output(output, volts, slew)
                active_output_crow_val = volts
              end
              
              --midi out
              if self.patch_points[i][j].midi_cc_enabled == 2 then
                local cc = self.patch_points[i][j].midi_cc
                local midi_channel = self.patch_points[i][j].midi_channel
                local cc_val = util.linlin(input_obj.min,input_obj.max,1,127,input_obj.val)
                local pp_level = self.patch_points[i][j].level
                pp_level = mod_matrix.level_options[pp_level]
                local cc_val = cc_val * pp_level
                externals.play_midi_cc_mod_matrix(cc,cc_val,midi_channel)
                active_output_midi_val = math.floor(cc_val)
              end
            end
          end
        end
      end
    end
  end
  mod_matrix.active_input_val        = active_input_val         ~= "" and active_input_val        or mod_matrix.active_input_val
  mod_matrix.active_output_val       = active_output_val        ~= "" and active_output_val       or mod_matrix.active_output_val
  mod_matrix.active_output_crow_val  = active_output_crow_val   ~= "" and active_output_crow_val  or mod_matrix.active_output_crow_val
  mod_matrix.active_output_midi_val  = active_output_midi_val   ~= "" and active_output_midi_val  or mod_matrix.active_output_midi_val
end


-------------------------------------------
--- mod matrix crow output
-------------------------------------------
function mod_matrix.crow_output(output, volts,slew)
  if params:get("output_crow"..output)~=10 then
    params:set("output_crow"..output,10) 
  end
  crow.output[output].volts = volts 
  crow.output[output].slew = slew 
  crow.output[output].execute() 
end
-------------------------------------------
--- mod matrix gui
-------------------------------------------

function mod_matrix:start_stop_scrolling()
  if self.scrolling_input then 
    self.scrolling_input:scr_start_stop_metro()
    self.scrolling_output:scr_start_stop_metro()
  end
end
----------------------------
-- gui sectors:
--    2 = row/column selection
--    3 = inputs/output selection
--    3 = patch point options
--    4 = crow options
--    5 = midi options
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
  elseif self.active_gui_sector == 3 then
    text = "pp opt"
  elseif self.active_gui_sector == 4 then
    text = "crow"
  else 
    text = "midi"
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

  local pp = self.patch_points[self.active_input][self.active_output]
  local crow_enabled = pp and pp.crow_enabled
  local midi_cc_enabled = pp and pp.midi_cc_enabled
  
  if pp == nil or (crow_enabled == nil or midi_cc_enabled == nil) then
    -- main patch point options
    local enabled     = mod_matrix.default_pp_option_selections[1]
    local level       = mod_matrix.default_pp_option_selections[2]
    local level_range = mod_matrix.default_pp_option_selections[3]
    -- local self_mod  = mod_matrix.default_pp_option_selections[3]
    -- local relative_mod  = mod_matrix.default_pp_option_selections[4]
    self.patch_points[self.active_input][self.active_output] = {
      enabled        =    enabled,          -- options: off, on
      level          =    level,            
      level_range    =    level_range,      
      -- self_mod       =    self_mod,       -- options: none,invert,rectify
      -- relative_mod   =    relative_mod,   -- options: none, and, or
    }

    
  
    -- crow patch point options
    local enabled  = mod_matrix.default_crow_option_selections[1]
    local output  = mod_matrix.default_crow_option_selections[2]
    local slew  = mod_matrix.default_crow_option_selections[3]
    self.patch_points[self.active_input][self.active_output].crow_enabled  =   enabled
    self.patch_points[self.active_input][self.active_output].crow_output   =   output
    self.patch_points[self.active_input][self.active_output].crow_slew     =   slew
    
    -- midi patch point options
    local enabled   = mod_matrix.default_midi_option_selections[1]
    local cc        = mod_matrix.default_midi_option_selections[2]
    local channel   = mod_matrix.default_midi_option_selections[3]
    
    self.patch_points[self.active_input][self.active_output].midi_cc_enabled  =   enabled
    self.patch_points[self.active_input][self.active_output].midi_cc          =   cc
    self.patch_points[self.active_input][self.active_output].midi_channel     =   channel
  end

    

end


function mod_matrix.init_scrolling_text_input(self,input)
  clock.sleep(0.2)
  if self.scrolling_input then
    self.scrolling_input.free_metro()
  end
  self.scrolling_input = scroll_text:new(self.lookup[input].name)    
  self.scrolling_input.init()
end

function mod_matrix.init_scrolling_text_output(self,output)
  clock.sleep(0.2)
  if self.scrolling_output then
    self.scrolling_output.free_metro()
  end
  self.scrolling_output = scroll_text:new(self.lookup[output].name)    
  self.scrolling_output.init()
end

function mod_matrix:display_params()
  local input = self.inputs[self.active_input]
  local output = self.outputs[self.active_output]

  if self.prev_input == nil or (self.prev_input and self.prev_input ~= input) then
    if self.scrolling_input_init_clock and self.scrolling_input_init_clock > 0 then clock.cancel(self.scrolling_input_init_clock) end
    self.scrolling_input_init_clock = clock.run(mod_matrix.init_scrolling_text_input,self,input)
  end
  
  if self.prev_output == nil or (self.prev_output and self.prev_output ~= output) then
    if self.scrolling_output_init_clock and self.scrolling_output_init_clock > 0 then clock.cancel(self.scrolling_output_init_clock) end
    self.scrolling_output_init_clock = clock.run(mod_matrix.init_scrolling_text_output,self,output)
  end
    
  self.prev_input  = input
  self.prev_output = output
  if self.lookup[input] and self.lookup[output] then
    local input_text  = ""
    local output_text = ""
    
    if self.active_gui_sector == 2 then
      input_text  = "in: "  .. self.lookup[input].name
      output_text = "out: " .. self.lookup[output].name
    elseif self.scrolling_input and self.scrolling_output then
      input_text  = "in: "  .. self.scrolling_input.get_text()
      output_text = "out: " .. self.scrolling_output.get_text()
    end
    
    -- clear the input/output labels
    screen.level(0)
    screen.move(15,50)
    screen.rect(15,49,50,12)
    screen.move(15,60)
    screen.rect(15,57,50,12)
    screen.fill()
    screen.stroke()

    screen.move(60,50)
    screen.rect(60,49,70,12)
    screen.move(60,60)
    screen.rect(60,57,70,12)
    screen.fill()
    screen.stroke()
  
    if self.active_gui_sector ~= 2 then
      screen.level(5)
      input_text = string.sub(input_text,1,15)
      output_text = string.sub(output_text,1,15)
      screen.move(5,54)
      screen.text(input_text)
      screen.move(72,54)
      screen.text(output_text)
      screen.move(5,62)
      local in_val = ""
      in_val = type(mod_matrix.active_input_val) == "number" and fn.round_decimals(tonumber(mod_matrix.active_input_val),3) or mod_matrix.active_input_val
      screen.text("in val: " .. in_val)
      screen.move(72,62)
      if self.active_gui_sector < 4 then
        screen.text("out val: " .. mod_matrix.active_output_val)
      elseif self.active_gui_sector == 4 then
        screen.text("out val: " .. mod_matrix.active_output_crow_val)
      elseif self.active_gui_sector == 5 then
        screen.text("out val: " .. mod_matrix.active_output_midi_val)
      end
    elseif self.selecting_param == "in" then
      screen.level((self.active_gui_sector == 2 and self.lookup[input].name and self.lookup[input].id) and 15 or 10)
      screen.move(5,54)
      screen.text(input_text)
      screen.move(5,62)
      local in_val = ""
      in_val = type(mod_matrix.active_input_val) == "number" and fn.round_decimals(tonumber(mod_matrix.active_input_val),3) or mod_matrix.active_input_val
      screen.text("in val: " .. in_val)
    else
      screen.level((self.active_gui_sector == 2 and self.lookup[output].name and self.lookup[output].id) and 15 or 10)
      screen.move(5,54)
      screen.text(output_text)
      screen.move(5,62)
      local out_val = ""
      out_val = type(mod_matrix.active_output_val) == "number" and fn.round_decimals(tonumber(mod_matrix.active_output_val),3) or mod_matrix.active_output_val
      screen.text("out val: " .. out_val)
    end
  end
end

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
    screen.text(mod_matrix.input_labels[i])
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
    screen.text(mod_matrix.output_labels[i])
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
      local dot_level
      if self.patch_points[i] and self.patch_points[i][j] then
        
        local enabled
        if mod_matrix.active_gui_sector < 4 then
          enabled = self.patch_points[i][j].enabled == 2
        elseif mod_matrix.active_gui_sector == 4 then
          enabled = self.patch_points[i][j].crow_enabled == 2
        else
          enabled = self.patch_points[i][j].midi_cc_enabled == 2
        end

        if enabled and self.active_input == i and self.active_output == j then 
          level = 15
          dot_level = 0
        elseif enabled then
          level = 5
          dot_level = 5
        elseif self.active_input == i and self.active_output == j then
          level = 5
          dot_level = 15
        else
          level = 1
        end
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

      if dot_level then
        screen.level(dot_level)
        screen.move(9*(j+1)+51,(9*i)+9)
        screen.circle(9*(j+1)+51,(9*i)+6,1)  
        screen.fill()
        screen.stroke()
      end
    end
  end
end

function mod_matrix:display_patch_point_options()
  local rect_level = self.active_gui_sector >2 and 15 or 5
  screen.level(rect_level)
  screen.move(5,5)
  screen.rect(5,15,47,30)
  screen.stroke()
  
  if self.patch_points[self.active_input] and self.patch_points[self.active_input][self.active_output] then
    pp = self.patch_points[self.active_input][self.active_output]

    if self.active_gui_sector < 4 then
      local enabled   = self.enabled_options[self.patch_points[self.active_input][self.active_output].enabled]
      local level     = self.level_options[self.patch_points[self.active_input][self.active_output].level]
      local level_range     = self.level_options[self.patch_points[self.active_input][self.active_output].level_range]
      -- local self_mod      = self.self_mod_options[self.patch_points[self.active_input][self.active_output].self_mod]
      -- local relative_mod  = self.relative_mod_options[self.patch_points[self.active_input][self.active_output].relative_mod]

      screen.move(8,24)
      screen.level(mod_matrix.active_pp_option == 1 and 15 or 5)
      screen.text("enbl: " .. enabled)
      screen.stroke()
      screen.move(8,32)
      screen.level(mod_matrix.active_pp_option == 2 and 15 or 5)
      screen.text("lvl: " .. level)
      screen.stroke()
      screen.move(8,40)
      screen.level(mod_matrix.active_pp_option == 3 and 15 or 5)
      screen.text("lvlr: " .. level_range)
      screen.stroke()

      screen.move(8,48)
      screen.level(output_value and 15 or 5)
      -- screen.text("rm: " .. relative_mod)
      
      screen.stroke()
    elseif self.active_gui_sector == 4 then -- crow gui
      local enabled   = self.crow_enabled_options[self.patch_points[self.active_input][self.active_output].crow_enabled]
      local output    = self.crow_output_options[self.patch_points[self.active_input][self.active_output].crow_output]
      local slew     = self.crow_slew_options[self.patch_points[self.active_input][self.active_output].crow_slew]
      screen.move(8,24)
      screen.level(mod_matrix.active_crow_pp_option == 1 and 15 or 5)
      screen.text("enbl: " .. enabled)
      screen.stroke()
      screen.move(8,32)
      screen.level(mod_matrix.active_crow_pp_option == 2 and 15 or 5)
      screen.text("out: " .. output)
      screen.stroke()
      screen.move(8,40)
      screen.level(mod_matrix.active_crow_pp_option == 3 and 15 or 5)
      screen.text("slew: " .. slew)
      screen.stroke()
    elseif self.active_gui_sector == 5 then -- midi gui
      local enabled   = self.midi_cc_enabled_options[self.patch_points[self.active_input][self.active_output].midi_cc_enabled]
      local cc        = self.midi_cc_options[self.patch_points[self.active_input][self.active_output].midi_cc]
      local channel   = self.midi_channel_options[self.patch_points[self.active_input][self.active_output].midi_channel]
      screen.move(8,24)
      screen.level(mod_matrix.active_midi_pp_option == 1 and 15 or 5)
      screen.text("enbl: " .. enabled)
      screen.stroke()
      screen.move(8,32)
      screen.level(mod_matrix.active_midi_pp_option == 2 and 15 or 5)
      screen.text("cc: " .. cc)
      screen.stroke()
      screen.move(8,40)
      screen.level(mod_matrix.active_midi_pp_option == 3 and 15 or 5)
      screen.text("ch: " .. channel)
      screen.stroke()
    end
  end
end

return mod_matrix
