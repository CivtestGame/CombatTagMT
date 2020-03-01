
-- CombatTag

local COMBAT_TAG_TIMER = 30

function combat_tag.get_tag(player)
   local meta = player:get_meta()
   local tag_end = meta:get_int("combat_tag_end")
   if tag_end == 0 then
      return nil
   end

   local current_time = os.time(os.date("!*t"))
   if current_time > tag_end then
      return nil
   else
      return tag_end - current_time
   end
end

function combat_tag.tag(player, length)
   local player_tag_end = combat_tag.get_tag(player)
   if not player_tag_end then
      minetest.chat_send_player(
         player:get_player_name(),
         "You've been combat tagged for " .. tostring(length) .. "s."
      )
   end
   local meta = player:get_meta()
   -- meta:mark_as_private("combat_tag_end")
   meta:set_int(
      "combat_tag_end",
      os.time(os.date("!*t")) + length
   )
end

minetest.register_on_punchplayer(
   function(target, hitter, time_from_last_punch, tool_capabilities, unused_dir, damage)
      if target:get_hp() == 0 then
         return
      end
      if minetest.is_player(target) then
         combat_tag.tag(target, COMBAT_TAG_TIMER)
      end
      if minetest.is_player(hitter) then
         combat_tag.tag(hitter, COMBAT_TAG_TIMER)
      end
end)

minetest.register_on_joinplayer(function(player)
      if player:get_hp() > 0 then
         combat_tag.tag(player, 5)
      end
end)

local function combatlog_effect(player)
   local ppos = player:get_pos()

   local offset = 0

   for i = 0, 10, 1 do
      offset = offset + 0.1
      local neopos = vector.new(
         ppos.x + math.random(-0.1, 0.1),
         ppos.y + offset,
         ppos.z + math.random(-0.1,0.1)
      )
      minetest.add_particle({
            pos = neopos,
            velocity = {
               x = math.random(-0.2, 0.2),
               y = math.random(-0.2, 0.2),
               z = math.random(-0.2, 0.2)
            },
            acceleration = { x = 0, y =-0.25, z = 0 },
            expirationtime = 5,
            size = 4,
            collisiondetection = true,
            vertical = false,
            texture = "^[colorize:#dd2222"
      })
   end
   minetest.sound_play(
      "tnt_explode",
      {
         pos = ppos,
         max_hear_distance = 100,
         gain = 10.0,
      }
   )
end

minetest.register_on_leaveplayer(function(player)
      local pname = player:get_player_name()
      if combat_tag.get_tag(player) then
         combatlog_effect(player)
         player:set_hp(0) -- RIP
      end
end)

minetest.register_chatcommand(
   "ct",
   {
      description = "Displays the sender's combat tag duration.",
      params = "",
      func = function(name)
         local player = minetest.get_player_by_name(name)
         if not player then
            return false
         end
         local tag = combat_tag.get_tag(player)
         if tag then
            minetest.chat_send_player(
               name, "You are combat tagged for another "
                  .. tostring(tag) .. "s."
            )
         else
            minetest.chat_send_player(name, "You are not combat tagged.")
         end
         return true
      end
   }
)
