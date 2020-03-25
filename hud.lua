
local tag_hud_title = {}
local tag_hud_bg = {}
local tag_hud_bar = {}

local X_OFFSET_SPACE = -180

function combat_tag.remove_hud(player)
   local pname = player:get_player_name()

   local _
   _ = tag_hud_title[pname] and player:hud_remove(tag_hud_title[pname])
   _ = tag_hud_bg[pname] and player:hud_remove(tag_hud_bg[pname])
   _ = tag_hud_bar[pname] and player:hud_remove(tag_hud_bar[pname])

   tag_hud_title[pname] = nil
   tag_hud_bg[pname] = nil
   tag_hud_bar[pname] = nil
end

minetest.register_on_leaveplayer(function(player)
      combat_tag.remove_hud(player)
end)

function combat_tag.update_hud(player)
   local pname = player:get_player_name()

   local tag = combat_tag.get_tag(player)
   local max_tag = combat_tag.COMBAT_TAG_TIMER

   if not tag then
      combat_tag.remove_hud(player)
      return
   end

   local bg_idx = tag_hud_bg[pname]
   local title_idx = tag_hud_title[pname]
   local bar_idx = tag_hud_bar[pname]

   if not bg_idx then
      local bg_new_idx = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 1, y = 0.5},
            offset    = {x = X_OFFSET_SPACE, y = -80},
            text      = "combattagmt_hud_bg.png",
            scale     = { x = 1, y = 1},
            alignment = { x = 1, y = 0 },
      })
      tag_hud_bg[pname] = bg_new_idx
   end

   local tagtext = "Combat Tag (" .. tostring(tag) .. ")"

   if not title_idx then
      local title_new_idx = player:hud_add({
            hud_elem_type = "text",
            text      = tagtext,
            position  = {x = 1, y = 0.5},
            offset    = {x = -90, y = -99},
            alignment = -1,
            scale     = { x = 50, y = 10},
            number    = 0xEE0000,
      })
      tag_hud_title[pname] = title_new_idx
   else
      player:hud_change(title_idx, "text", tagtext)
   end

   local percent = tag / max_tag

   if not bar_idx then
      local new_bar_idx = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 1, y = 0.5},
            offset    = {x = -170, y = -68},
            text      = "combattagmt_hud_bar.png",
            scale     = { x = percent, y = 1},
            alignment = { x = 1, y = 0 },
      })
      tag_hud_bar[pname] = new_bar_idx
   else
      player:hud_change(bar_idx, "scale", { x = percent, y = 1})
   end

end

local timer = 0
minetest.register_globalstep(function(dtime)
      timer = timer + dtime
      if timer < 0.25 then
         return
      end
      timer = 0

      for pname,_ in pairs(tag_hud_title) do
         local player = minetest.get_player_by_name(pname)
         if player then
            combat_tag.update_hud(player)
         else

         end
      end
end)
