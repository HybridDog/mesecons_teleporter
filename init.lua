local function pos_to_string(pos)
	return pos.x.." "..pos.y.." "..pos.z
end

local function pos_from_string(p)
	if not p then
		return
	end
	local pos = {}
	local ps = string.split(p, " ")
	for n,i in pairs({"x", "y", "z"}) do
		local num = tonumber(ps[n])
		if type(num) ~= "number" then
			return
		end
		pos[i] = num
	end
	return pos
end

minetest.register_node("mesecons_teleporter:teleporter", {
	description = "Mport",
	tiles = {"default_steel_block.png"},
	groups = {bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[4,5]"..
			"field[1,1;3,0;pos_in;from;${pos_in}]"..
			"field[1,2;3,0;pos_out;to;${pos_out}]"..
			"field[1,3;3,0;text;info;${text}]"..
			"field[1,4;0.7,0;r;radius;${r}]"
		)
		local position = vector.pos_to_string(pos)
		local p = pos_to_string(pos)
		meta:set_string("infotext", "Mport from "..position.." to "..position)
		meta:set_string("pos_in", p)
		meta:set_string("pos_out", p)
		meta:set_string("r", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if pos_from_string(fields.pos_in) then
			meta:set_string("pos_in", fields.pos_in)
		end
		if pos_from_string(fields.pos_out) then
			meta:set_string("pos_out", fields.pos_out)
		end
		local r = tonumber(fields.r)
		if type(r) == "number" then
			meta:set_string("r", math.min(r, 20))
		end
		if fields.text
		and fields.text ~= "" then
			meta:set_string("text", fields.text)
		end
		local pos_in = vector.pos_to_string(pos_from_string(meta:get_string("pos_in")))
		local pos_out = vector.pos_to_string(pos_from_string(meta:get_string("pos_out")))
		local info = meta:get_string("text")
		if info then
			if info ~= "" then
				info = " \""..info.."\""
			end
		else
			info = ""
		end
		meta:set_string("infotext", "Mport"..
			info..
			" from "..pos_in..
			" to "..pos_out
		)
		minetest.log("action", (sender:get_player_name() or "somebody").." did something to Mport at "..vector.pos_to_string(pos))
	end,
	mesecons = {
		effector = {
			action_on = function(pos)
				local meta = minetest.get_meta(pos)
				local p1 = pos_from_string(meta:get_string("pos_in"))
				local p2 = pos_from_string(meta:get_string("pos_out"))
				if not p1
				or not p2 then
					return
				end
				local r = meta:get_string("r") or 1
				local info = meta:get_string("text")
				local player_found
				for _,i in pairs(minetest.get_objects_inside_radius(p1, r)) do
					if i:is_player() then
						minetest.after(0, function(i, p2, info)
							i:moveto(p2)
							if info
							and info ~= "" then
								minetest.chat_send_player(i:get_player_name(), "-!- "..info, true)
							end
						end, i, p2, info)
						player_found = true
					else
						i:setpos(p2)
					end
				end
				if player_found then
					minetest.sound_play("mesecons_teleporter", {pos = p1, gain = 1, max_hear_distance = (r+4)})
				end
			end,
		}
	}
})
