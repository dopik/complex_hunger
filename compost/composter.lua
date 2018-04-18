local function update_formspec(pos, runtime_percent)
	local meta = minetest.get_meta(pos)
	
	minetest.chat_send_all(runtime_percent)
	
	local formspec = 
		"size[8,7.5]"..
		"list[context;input;0.5,0;1,1;4]"..
		"list[context;input;0,1;2,2]"..
		"list[context;output;4,1;2,2]"..
		"list[current_player;main;0,3.5;8,4]"..
		"listring[current_player;main]"..
		"listring[context;input]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"image[2.5,1.5;1,1;compost_arrow_bg.png^[lowpart:"..
		(100 *runtime_percent)..":compost_arrow.png^[transformR270]"
			
	meta:set_string("formspec", formspec)
end

local function compost_on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local timer = minetest.get_node_timer(pos)
		
	local src_stack
	local i = 1
	while i <= 4 do
		src_stack = inv:get_stack("input", i)
		i = i +1
		if src_stack:get_count() > 0 then
			i = 5
		end
	end
	
	local src_time = compost.output[src_stack:get_name()] or 1
	local src_totaltime = src_time *src_stack:get_count() or 0
	local runtime = meta:get_float("runtime") or 0
	local fuel = meta:get_int("fuel") or 0
	
	minetest.chat_send_all("Ich mach was")
	minetest.chat_send_all(fuel)
	minetest.chat_send_all(runtime)
	minetest.chat_send_all(src_totaltime)
	minetest.chat_send_all(src_time)
	
	
	runtime = math.min(runtime +math.min(fuel, elapsed), src_totaltime)
	fuel = fuel - math.min(fuel, elapsed, src_totaltime)
	
	if runtime >= src_time then
		local amount = math.floor(runtime /src_time)
		local result_stack = ItemStack("compost:mulch "..amount)
		runtime = runtime - amount *compost.output[src_stack:get_name()]
		
		local overflow = inv:add_item("output", result_stack)
		if overflow:get_count() > 0 then
			amount = amount -overflow:get_count()
			fuel = fuel + overflow:get_count() *compost.output[overflow:get_name()]
			runtime = 0
			result_stack:set_count(amount)
		end
		src_stack:set_count(result_stack:get_count())
		inv:remove_item("input", src_stack)
	end
	
	meta:set_int("fuel", fuel)
	
	if inv:is_empty("input") or not inv:room_for_item("output", ItemStack("compost:mulch 1")) then
		runtime = 0
		timer:stop()
	else
		timer:start(1)
	end
	meta:set_float("runtime", runtime)
		
	update_formspec(pos, runtime /src_time)
end

minetest.register_node("compost:composter",{
	description = "Composter",
	tiles = {
		"compost_machine_top.png",
		"compost_machine_bottom.png",
		"compost_machine_right.png",
		"compost_machine_left.png",
		"compost_machine_bottom.png",
		"compost_machine_front.png"
		},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {oddly_breakable_by_hand=2, cracky=3, dig_immediate=1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.4375, 0.5, 0.5, 0.5}, 
			{-0.5, -0.5, 0.375, -0.4375, 0.4375, 0.4375}, 
			{-0.5, -0.5, 0.3125, -0.4375, 0.375, 0.375},
			{-0.5, -0.5, 0.25, -0.4375, 0.3125, 0.3125}, 
			{-0.5, -0.5, 0.1875, -0.4375, 0.25, 0.25},
			{-0.5, -0.5, 0.125, -0.4375, 0.1875, 0.1875},
			{-0.5, -0.5, 0.0625, -0.4375, 0.125, 0.125}, 
			{-0.5, -0.5, 0, -0.4375, 0.0625, 0.0625}, 
			{-0.5, -0.5, -0.0625, -0.4375, 0, 0}, 
			{-0.5, -0.5, -0.125, -0.4375, -0.0625, -0.0625},
			{-0.5, -0.5, -0.1875, -0.4375, -0.125, -0.125}, 
			{-0.5, -0.5, -0.25, -0.4375, -0.1875, -0.1875}, 
			{-0.5, -0.5, -0.3125, -0.4375, -0.25, -0.25}, 
			{-0.5, -0.5, -0.5, -0.4375, -0.3125, -0.3125}, 
			{-0.5, -0.5, -0.5, 0.5, -0.3125, -0.4375}, 
			{0.4375, -0.5, 0.375, 0.5, 0.4375, 0.4375}, 
			{0.4375, -0.5, 0.3125, 0.5, 0.375, 0.375}, 
			{0.4375, -0.5, 0.25, 0.5, 0.3125, 0.3125}, 
			{0.4375, -0.5, 0.1875, 0.5, 0.25, 0.25}, 
			{0.4375, -0.5, 0.125, 0.5, 0.1875, 0.1875}, 
			{0.4375, -0.5, 0.0625, 0.5, 0.125, 0.125},
			{0.4375, -0.5, 0, 0.5, 0.0625, 0.0625}, 
			{0.4375, -0.5, -0.0625, 0.5, 0, 0},
			{0.4375, -0.5, -0.125, 0.5, -0.0625, -0.0625}, 
			{0.4375, -0.5, -0.1875, 0.5, -0.125, -0.125}, 
			{0.4375, -0.5, -0.25, 0.5, -0.1875, -0.1875}, 
			{0.4375, -0.5, -0.3125, 0.5, -0.25, -0.25}, 
			{0.4375, -0.5, -0.5, 0.5, -0.3125, -0.3125}, 
			{-0.4375, -0.5, -0.4375, 0.4375, -0.3125, 0.4375}, 
			{-0.5, -0.3125, -0.125, 0.5, -0.125, 0.5}, 
			{-0.4375, -0.5, 0.125, 0.4375, 0.0625, 0.4375}, 
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.4375, 0.5, 0.5, 0.5}, 
			{-0.5, -0.5, 0.375, -0.4375, 0.4375, 0.4375}, 
			{-0.5, -0.5, 0.3125, -0.4375, 0.375, 0.375},
			{-0.5, -0.5, 0.25, -0.4375, 0.3125, 0.3125}, 
			{-0.5, -0.5, 0.1875, -0.4375, 0.25, 0.25},
			{-0.5, -0.5, 0.125, -0.4375, 0.1875, 0.1875},
			{-0.5, -0.5, 0.0625, -0.4375, 0.125, 0.125}, 
			{-0.5, -0.5, 0, -0.4375, 0.0625, 0.0625}, 
			{-0.5, -0.5, -0.0625, -0.4375, 0, 0}, 
			{-0.5, -0.5, -0.125, -0.4375, -0.0625, -0.0625},
			{-0.5, -0.5, -0.1875, -0.4375, -0.125, -0.125}, 
			{-0.5, -0.5, -0.25, -0.4375, -0.1875, -0.1875}, 
			{-0.5, -0.5, -0.3125, -0.4375, -0.25, -0.25}, 
			{-0.5, -0.5, -0.5, -0.4375, -0.3125, -0.3125}, 
			{-0.5, -0.5, -0.5, 0.5, -0.3125, -0.4375}, 
			{0.4375, -0.5, 0.375, 0.5, 0.4375, 0.4375}, 
			{0.4375, -0.5, 0.3125, 0.5, 0.375, 0.375}, 
			{0.4375, -0.5, 0.25, 0.5, 0.3125, 0.3125}, 
			{0.4375, -0.5, 0.1875, 0.5, 0.25, 0.25}, 
			{0.4375, -0.5, 0.125, 0.5, 0.1875, 0.1875}, 
			{0.4375, -0.5, 0.0625, 0.5, 0.125, 0.125},
			{0.4375, -0.5, 0, 0.5, 0.0625, 0.0625}, 
			{0.4375, -0.5, -0.0625, 0.5, 0, 0},
			{0.4375, -0.5, -0.125, 0.5, -0.0625, -0.0625}, 
			{0.4375, -0.5, -0.1875, 0.5, -0.125, -0.125}, 
			{0.4375, -0.5, -0.25, 0.5, -0.1875, -0.1875}, 
			{0.4375, -0.5, -0.3125, 0.5, -0.25, -0.25}, 
			{0.4375, -0.5, -0.5, 0.5, -0.3125, -0.3125}, 
			{-0.4375, -0.5, -0.4375, 0.4375, -0.3125, 0.4375}, 
			{-0.5, -0.3125, -0.125, 0.5, -0.125, 0.5}, 
			{-0.4375, -0.5, 0.125, 0.4375, 0.0625, 0.4375}, 
		}
	},
	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		
		local inv = minetest.get_meta(pos):get_inventory()
		
		return inv:is_empty("input") and inv:is_empty("output")
	end,
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "Composter (owned by "..placer:get_player_name()..")")
		
		inv:set_size("input", 5)
		inv:set_size("output", 4)
		timer:start(0.1)
		
		inv:set_stack("input", 1, ItemStack("default:dirt"))
		inv:set_stack("input", 2, ItemStack("default:stone"))
		inv:set_stack("input", 3, ItemStack("default:cobble"))
		inv:set_stack("input", 4, ItemStack("default:glass"))
		inv:set_stack("input", 5, ItemStack("default:dirt_with_grass"))
		
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)		
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		if listname == "input" and index == 5 and compost.input[stack:get_name()] then
			return stack:get_count()
		elseif listname == "input" and index <= 4 and compost.output[stack:get_name()] then
			return stack:get_count()
		else
			return 0
		end
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		
		if listname == "input" and index == 5 then
			meta:set_int("fuel", stack:get_count() *compost.input[stack:get_name()])
			inv:set_stack(listname, index, ItemStack(""))
		end
		
		timer:start(1)
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.get_meta(pos):get_float("runtime") then
			local timer = minetest.get_node_timer(pos)
			timer:start(1)
		end

		return stack:get_count()
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if from_list == to_list then
			if minetest.get_meta(pos):get_float("runtime") then
				local timer = minetest.get_node_timer(pos)
				timer:start(1)
			end
			
			return stack:get_count()
		else
			return 0
		end
	end,
	on_timer = compost_on_timer
})

minetest.register_node("compost:mulch",{
	description = "Mulch",
	tiles = {"compost_mulch.png"},
	groups = {crumbly = 3, soil = 1},
	drop = "default:dirt 1",
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		
		meta:set_float("nutrients",100)
	end
})