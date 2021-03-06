local scroll_text = {}
scroll_text.__index = scroll_text

function scroll_text:new(text_to_scroll)
  local st={}
  setmetatable(st, scroll_text)

  st.scr_step = 1
  st.scr_step_increment = 1
  st.scr_max_length = 10 
  st.text_to_scroll = #text_to_scroll <= st.scr_max_length and  text_to_scroll or "> " .. text_to_scroll .. " "

  if #st.text_to_scroll > st.scr_max_length then
    st.scr_step_metro = metro.init()
  end

  function st.init()
    --startup scrolling metro
    if st.scr_step_metro then
      if #st.text_to_scroll > st.scr_max_length then
        st.scr_step_metro.event = st.scroll
        st:scr_start_stop_metro()
      end
    elseif #st.text_to_scroll > st.scr_max_length then
      print("ERROR: st.scr_step_metro not found, reinit", st.scr_step_metro)
    end
  end

  function st.free_metro()
    if st.scr_step_metro and st.scr_step_metro.id then
      metro.free(st.scr_step_metro.id)
    end
  end
  
  function st.get_text()
    return st.text_to_scroll
  end

  -- function st:copy(obj)
  --     if type(obj) ~= 'table' then return obj end
  --     local res = {}
  --     for k, v in pairs(obj) do res[st:copy(k)] = st:copy(v) end
  --     return res
  -- end

  -- function st:truncate(str, trunc_len, with_ellipses)
  --   if (str ~= nil) then
  --     if (with_ellipses and #str > trunc_len) then
  --       trunc_str = string.sub(str, 0, trunc_len) .. "..."
  --     else 
  --       trunc_str = string.sub(str, 0, trunc_len)
  --     end
  --     return trunc_str
  --   end
  -- end

  -- scroll the text
  function st.scroll()
    if norns.menu.status()  == false then
      st.scr_step = st.scr_step + st.scr_step_increment
      --scroll device name
      local scr_text = ""
      local scr_head = ""
      local scr_tail = ""

      if (#st.text_to_scroll > st.scr_max_length) then
        scr_text = st.text_to_scroll
        scr_head = string.sub(scr_text,1, 1)
        scr_tail = string.sub(scr_text,2)
        scr_text = scr_tail .. scr_head
        st.text_to_scroll = scr_text
      end 
      -- print("scroll_text.text_to_scroll",st.text_to_scroll)
    end
  end

  function st:scr_start_stop_metro()
    if self.scr_step_metro then
      if self.scr_step_metro.is_running then
        self.scr_step_metro:stop()
      else
        self.scr_step = 0
        self.scr_step_metro:start(0.2) 
      end
    end
  end

  -- function st:blink_generator(x)
  --   while true do
  --     clock.sync(1/2)
  --     blinkers[x] = not blinkers[x]
  --     redraw()
  --   end
  -- end

  return st
end

return scroll_text