
-- CombatTag

combat_tag.COMBAT_TAG_TIMER = 30
combat_tag.COMBAT_TAG_LOGIN = 5

local current_time = 0
local storage = minetest.get_mod_storage()

function combat_tag.clear(player)
   if not player or not player:is_player() then
      return
   end

   player:get_meta():set_int("combat_tag_end", 0)
end

-- can be player or TagPlayer entity
function combat_tag.get_tag(player)
   if not player then
       return nil
   end

   local tag_exempt = nil
   local tag_end = 0
   local meta = nil

   if player:is_player() then
       meta = player:get_meta()
       tag_exempt = meta:get("combat_tag_exempt")
       tag_end = meta:get_int("combat_tag_end")
   else
       local ent = player:get_luaentity()
       if not ent or not ent.name == "combattagmt:tagplayer" then
           return nil
       end
       tag_end = ent.time
   end

   if tag_exempt or tag_end <= 0 then
      return nil
   end

   if current_time > tag_end then
      if player:is_player() then
          meta:set_int("combat_tag_end", 0)
      end
      return nil
   else
      return tag_end - current_time
   end
end

function combat_tag.make_exempt(player)
   if not player or not player:is_player() then
      return
   end
   local meta = player:get_meta()
   meta:set_string("combat_tag_exempt", "true")
   meta:set_int("combat_tag_end", 0)
end

function combat_tag.tag(player, length)
   if not player or not player:is_player() or not length then
      return
   end

   local player_tag_end = combat_tag.get_tag(player)
   if not player_tag_end then
      minetest.chat_send_player(
         player:get_player_name(),
         "You've been combat tagged for " .. tostring(length) .. "s."
      )
   end
   local meta = player:get_meta()
   meta:set_int(
      "combat_tag_end",
      current_time + length
   )
   combat_tag.update_hud(player)
end

minetest.register_on_punchplayer(
   function(target, hitter, time_from_last_punch, tool_capabilities, unused_dir, damage)
      if target:is_player() and target:get_hp() > 0 then
         combat_tag.tag(target, combat_tag.COMBAT_TAG_TIMER)
         target:set_nametag_attributes({text=""})
      end

      if hitter:is_player() then
         combat_tag.tag(hitter, combat_tag.COMBAT_TAG_TIMER)
      end
end)

minetest.register_on_joinplayer(function(player)
    local dead_list_str = storage:get_string("dead_list") 
    if not dead_list_str then dead_list_str = "" end

    local dead_list = minetest.deserialize(dead_list_str)
    if not dead_list then 
        dead_list = {}
        storage:set_string("dead_list", minetest.serialize(dead_list))
    end

    -- if table isnt empty, check if player is in it
    if table.maxn(dead_list) > 0 then
        local found = false
        local pindx = 0
        local pname = player:get_player_name()
        for i,name in ipairs(dead_list) do
            -- player tagged entity died, kill em
            if name == pname then
                found = true
                pindx = i
                local pinv = player:get_inventory()
                pinv:set_list("main", {})
                player:set_hp(0, "set_hp")
            end
        end

        -- player died, remove them from the list
        if found then
            table.remove(dead_list, pindx)
            storage:set_string("dead_list",
                minetest.serialize(dead_list))
            return
        end
    end

    local tagtime = combat_tag.COMBAT_TAG_LOGIN
    local pname = player:get_player_name()
    -- check for tag entity
    -- if found for this player, remove and take its tag duration and add it to the default
    for _,obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 1)) do
        local entity = obj:get_luaentity()
        if entity and entity.name == "combattagmt:tagplayer" and 
                entity.playername == pname then
            local timeleft = combat_tag.get_tag(obj)
            if timeleft ~= nil then
                tagtime = tagtime + timeleft
            end
            obj:remove()
            break
        end
    end

    if player:get_hp() > 0 then
        combat_tag.tag(player, tagtime)
    end
end)

local TagPlayer = {
    initial_properties = {
        hp_max = 20,
        is_visible = true,
        static_save = false,
        physical = false,
        collide_with_objects = true,
        visual = "mesh",
        mesh = "character.b3d",
        textures = {"character.png"},
        visual_size = {x=1, y=1},
    },

    playername = "",
    time = 0,
    inv = nil,
    interval = 0,
}


function TagPlayer:on_death(dtime)
    for _,obj in ipairs(self.inv) do
        minetest.add_item(self.object:get_pos(), obj)
    end

    local dead_list = minetest.deserialize(
        storage:get_string("dead_list")) or {}
    table.insert(dead_list, self.playername)
    storage:set_string("dead_list",
        minetest.serialize(dead_list))
end

function TagPlayer:on_step(dtime)
    self.interval = self.interval + dtime
    if self.interval < 1.0 then
        return
    end
    
    local obj = self.object
    if not combat_tag.get_tag(obj) then
        obj:remove()
    end
end


function TagPlayer:on_activate(staticdata, dtime)
    local attribs = minetest.parse_json(staticdata) or {}
    local player = minetest.get_player_by_name(attribs.name)
    local pp = player:get_properties()

    self.playername = attribs.name
    self.time = attribs.time
    self.inv = player:get_inventory():get_list("main")
    self.object:set_properties(pp)

    -- IMPORTANT: makes sure entity doesn't get saved
    self.object:set_properties({
        static_save = false,
        nametag = self.playername,
    })
end

minetest.register_entity("combattagmt:tagplayer", TagPlayer)

local function combatlog_effect(player, time)
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
         max_hear_distance = 30,
         gain = 10.0,
      }
   )

   local ent = minetest.add_entity(
       ppos, 
       "combattagmt:tagplayer",
       minetest.write_json({name=player:get_player_name(), time=time + current_time})
   )
end

minetest.register_on_leaveplayer(function(player)
      local pname = player:get_player_name()
      local tag = combat_tag.get_tag(player)
      if tag then
         if player:get_hp() > 0 then
             combatlog_effect(player, tag)
         end
         combat_tag.clear(player)
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

-- current time is cached once a second second to reduce overhead of checks
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1.0 then
        return
    end
    timer = 0

    current_time = os.time(os.date("!*t"))
end)
