local save_load = {}
local pset_folder_path  = folder_path .. ".psets/"

function save_load.save_krill_data(name_or_path)
  if name_or_path then
    if os.rename(folder_path, folder_path) == nil then
      os.execute("mkdir " .. folder_path)
      os.execute("mkdir " .. pset_folder_path)
      os.execute("touch" .. pset_folder_path)
    end

    local save_path
    
    if string.find(name_or_path,"/") == 1 then
      local x,y = string.find(name_or_path,folder_path)
      local filename = string.sub(name_or_path,y+1,#name_or_path-4)
      local pset_path = pset_folder_path .. filename
      -- params:write(pset_path)
      save_path = name_or_path
    else
      local pset_path = pset_folder_path .. name_or_path
      -- params:write(pset_path)
      save_path = folder_path .. name_or_path  ..".krl"
    end
    
    -- save mod_matrix_data
    local mod_matrix_data = {}
    mod_matrix_data.inputs                        = fn.deep_copy(mod_matrix.inputs)
    mod_matrix_data.outputs                       = fn.deep_copy(mod_matrix.outputs)
    mod_matrix_data.patch_points                  = fn.deep_copy(mod_matrix.patch_points)
    mod_matrix_data.active_pp_option_selections   = fn.deep_copy(mod_matrix.active_pp_option_selections)
     
    local save_object = {}
    save_object.mod_matrix_data          = mod_matrix_data
    tab.save(save_object, save_path)
    print("saved!")
  else
    print("save cancel")
  end
end

function save_load.remove_krill_data(path)
   if string.find(path, 'krill') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("data found to remove", path)
      os.execute("rm -rf "..path)

      local start,finish = string.find(path,folder_path)

      local data_filename = string.sub(path,finish+1)
      local start2,finish2 = string.find(data_filename,".krl")
      local pset_filename = string.sub(path,finish+1,finish+start2-1)
      local pset_path = pset_folder_path .. pset_filename
      print("pset path found",pset_path)
      os.execute("rm -rf "..pset_path)  
    else
      print("no data found to remove")
    end
  end
end

function save_load.load_krill_data(path)
  krill_data = tab.load(path)
  if krill_data ~= nil then
    print("krill data found", path)
    local start,finish = string.find(path,folder_path)

    local data_filename = string.sub(path,finish+1)
    local start2,finish2 = string.find(data_filename,".krl")
    local pset_filename = string.sub(path,finish+1,finish+start2-1)
    local pset_path = pset_folder_path .. pset_filename
    print("pset path found",pset_path)
    -- load pset
    -- params:read(pset_path)

    -- load mod_matrix data
    local mod_matrix_data = krill_data.mod_matrix_data

    mod_matrix.inputs                       = fn.deep_copy(mod_matrix_data.inputs)
    mod_matrix.outputs                      = fn.deep_copy(mod_matrix_data.outputs)
    mod_matrix.patch_points                 = fn.deep_copy(mod_matrix_data.patch_points)
    mod_matrix.active_pp_option_selections  = fn.deep_copy(mod_matrix_data.active_pp_option_selections)

    print("mod_matrix data is now loaded")
          
 else
    print("no data")
  end
end

-- function save_load.load_krill_data_finish(krill_data)
  -- clock.sleep(1)layer.reset(i) end
-- end

function save_load.init()

  params:add_separator("DATA MANAGEMENT")
  params:add_group("krill data",5)

  params:add{
    type="option", id = "autosave", name="autosave" ,options={"off","on"}, default=AUTOSAVE_DEFAULT, 
    action=function() end
  }          

  params:add_trigger("save_krill_data", "> SAVE KRILL DATA")
  params:set_action("save_krill_data", function(x) textentry.enter(save_load.save_krill_data) end)

  params:add_trigger("overwrite_krill_data", "> OVERWRITE KRILL DATA")
  params:set_action("overwrite_krill_data", function(x) fileselect.enter(folder_path, save_load.save_krill_data) end)

  params:add_trigger("remove_krill_data", "< REMOVE KRILL DATA")
  params:set_action("remove_krill_data", function(x) fileselect.enter(folder_path, save_load.remove_krill_data) end)

  params:add_trigger("load_krill_data", "> LOAD KRILL DATA" )
  params:set_action("load_krill_data", function(x) fileselect.enter(folder_path, save_load.load_krill_data) end)

  -- params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  -- params:set_action("remove_plant_from_garden", function(x) 
  --   local saved_sequins = tab.load(saved_sequins_path) or {"no plants planted"}
  --   listselect.enter(saved_sequins, save_load.remove_plant_from_garden) 
  -- end)

end

return save_load
