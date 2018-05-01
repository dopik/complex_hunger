local Plant = {}
Plant.__index = Plant

setmetatable(Plant, ,{
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

function Plant.new(pos, meta)
	local self = setmetatable({}, Plant)
	self.pos = pos
	self.meta = meta or minetest.get_meta(pos)
	self.params = minetest.deserialize(self.meta:get_string("plant_params"))
	self.plantname = minetest.get_node(pos).name:sub(1, -2)
	self.st_params = plants[self.plantname]["params"]
	self.heat = minetest.get_heat(pos)
	self.humidity = minetest.get_humidity(pos)
	self.badness = self.meta:get_float("plant_badness")
	self.light = minetest.get_node(pos).param1
	self.drops = plants[self.plantname]["drops"]
	self.growsteps = plants.[self.plantname]["growsteps"]
	self.growstep = minetest.get_node(pos).name:sub(-1, -1)
	return self
end

-- Light
function Plant:get_light()
	return self.light
end

-- Badness
function Plant:get_badness()
	return self.badness
end

function Plant:set_badness(new_val)
	self.badness = new_val
	return true
end

function Plant:change_badness(val_change)
	self.badness = self.badness +val_change
	return true
end

-- Params
function Plant:get_params()
	return self.params
end

function Plant:set_params(new_val)
	self.params = new_val
	return true
end

function Plant:get_plant_param(val_name)
	return self.params[val_name]["min"], self.params[val_name]["max"], self.st_params[val_name]["min"], self.st_params[val_name]["max"]
end

function Plant:set_plant_param(val_name, new_val_min, new_val_max)
	self.params[val_name]["min"], self.params[val_name]["max"] = new_val_min, new_val_max
	return true
end

function Plant:gen_param(val_name)
	local v_cur_min, v_cur_max, v_min, v_max = self:get_plant_param(val_name)
	local rng = math.randomseed(os.time())
	
	v_cur_min = v_cur_min +(-1)^math.floor(rng +1.5) *0.5*math.exp(-15 *(rng -0.5)^2)
	v_cur_max = v_cur_max +(-1)^math.floor(rng +1.5) *0.5*math.exp(-15 *(rng -0.5)^2)
	
	v_cur_min = math.min(math.max(v_cur_min, v_min), v_max)
	v_cur_max = math.min(math.max(v_cur_max, v_min), v_max)
	
	v_cur_min, v_cur_max = math.min(v_cur_min, v_cur_max), math.max(v_cur_min, v_cur_max)
	self:set_plant_param(val_name, v_cur_min, v_cur_max)
	
	return v_cur_min, v_cur_max
end

-- Heat
function Plant:get_heat()
	return self.heat
end

-- Humidity
function Plant:get_humidity()
	return self.humidity
end

-- Drops
function Plant:drop(player)
	local index, stack, free_space
	local stack_paramtable, stack_badnesstable
	local yield = self:get_plant_param("yield")
	local plant_copy
	local params
	local badness
	
	for dropname, amount in pairs(self.drop) do
		index, stack, free_space = plants.functions.find_free_stack(player, dropname)
		stack_paramtable = minetest.deserialize(stack:get_meta():get_string("params"))
		stack_badnesstable = minetest.deserialize(stack:get_meta():get_string("badness"))
		amount = math.floor(amount *yield +0.5)
		amount = math.floor(amount +math.randomseed(os.time()) +0.5)
		
		if index then
			for i = 1, math.min(free_space, amount), 1 do
				plant_copy = Plant(pos)
				
				for k,v in pairs(plant_copy.params) do
					plant_copy:set_plant_param(k, plant_copy:gen_param(k))
				end
				
				stack_paramtable:insert(plant_copy:get_params())
				
				badness = plant_copy:get_plant_param("badness")
				stack_badnesstable:insert(badness)
				
				stack:get_meta():set_string("params", minetest.serialize(stack_paramtable))
				stack:get_meta():set_string("badness", minetest.serialize(stack_badnesstable))
				stack:set_count(stack:get_count() +1)
				
				player:get_inventory():set_stack("main", index, stack)
			end
			
			if free_space -amount < 0 then
				stack = ItemStack(dropname)
				stack_paramtable = {}
				stack_badnesstable = {}
				for i = 1, amount - free_space, 1 do
					plant_copy = Plant(pos)
					for k,v in pairs(plant_copy.params) do
						plant_copy:set_plant_param(k, plant_copy:gen_param(k))
					end
					
					stack_paramtable:insert(plant_copy:get_params())
					
					badness = plant_copy:get_plant_param("badness")
					stack_badnesstable:insert(badness)
				end
				
				stack:get_meta():set_string("params", minetest.serialize(stack_paramtable))
				stack:get_meta():set_string("badness", minetest.serialize(stack_badnesstable))
				stack:set_count(amount - free_space)
				
				stack = player:get_inventory():add_item(stack)
				
				if stack:get_count() > 0 then
					minetest.add_item(self.pos, stack)
				end
			end
		end
	end
end

-- Write meta
function Plant:write_meta()
	self.meta:set_string("plant_params", minetest.serialize(self.params))
	self.meta:set_float("plant_badness", self.badness)
end

-- Grow
function Plant:grow(elapsed)
	if self.growstep == self.growsteps then
		self:change_badness(10)
	end
	
	if self.badness >= 100 then
		minetest.dig_node(self.pos)
		minetest.place_node(self.pos, {name = "plants:rooten_plant"})
		return false
	end
	
	minetest.swap_node(self.pos, {name = self.plantname..(self.growstep +1)})
	local v_time = self:get_plant_param("time")
	elapsed = elapsed -v_time
	
	if elapsed >= v_time then
		return self:grow(elapsed)
	end
	return true
end

-- Helper Functions
function plants.functions.find_free_stack(player, itemname)
	local inv = player:get_inventory()
	local inv_size = inv:get_size("main")
	
	local stack
	for i = 1, inv_size, 1 do
		stack = inv:get_stack("main", i)
		if stack:get_name() == itemname and stack:get_free_space() > 0 then
			return i, stack, stack:get_free_space()
			break
		end
	end
	return false
end

-- Registration Functions
function plants.functions.register_plant(name, growsteps, textures)
	for i = 1, growsteps, i do
		minetest.register_node(name..i,{
			drawtype = "plantlike",
			tiles = textures[i]..".png",
			paramtype = "light",
			drop = "",
			after_dig_node = function(pos, oldnode, oldmetadata, digger)
				local plant = Plant(pos)
				if digger:is_player() then
					plant:drop(digger, oldmeta)
				end
			end,
			on_timer = function(pos, elapsed)
				local plant = Plant(pos)
				
				local v_cur_min_light, v_cur_max_light, v_min_light, v_max_light = plant:get_plant_param("light")
				local light = plant:get_light()
				
				local v_cur_min_heat, v_cur_max_heat = plant:get_plant_param("heat")
				local heat = plant:get_heat()
				
				local v_cur_min_humidity, v_cur_max_humidity = plant:get_plant_param("humidity")
				local humidity = plant:get_humidity()
				
				if heat <= v_cur_min_heat and heat >= v_cur_max_heat
					plant:change_badness(5)
				end
				
				if humidity <= v_cur_min_humidity and humidity >= v_cur_max_humidity
					plant:change_badness(5)
				end
				
				if light <= v_min_light and light >= v_max_light then
					plant:change_badness(10)
				end
					
				plant:write()
				
				local c = true
				if light >= v_cur_min_light and light <= v_cur_max_light then
					c = plant:grow(elapsed)
				end
				
				if c then
					local v_time_min, v_time_max = plant:get_plant_param("time")
					minetest.get_node_timer(pos):start(math.random(math.floor(v_time_min +0.5), math.floor(v_time_max +0.5)))
				end
			end,
		})
	end
end

function plants.functions.register_seed(name, seed_description, texture)
	minetest.register_node(name.."seed",{
		description = seed_description,
		drawtype = "signlike",
		tiles = texture..".png",
		paramtype = "light",
		paramtype2 = "facedir",
		drop = "",
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			local itemmeta = itemstack:get_meta()
			
			local rng = math.floor(itemstack:get_count() *math.randomseed(os.time()) +0.5)
			local params_tbl = minetest.deserialize(itemmeta:get_string("params"))
			local badness_tbl = minetest.deserialize(itemmeta:get_string("badness"))
			local item = params_tbl[rng]
			local badness = badness_tbl[rng]
			params_tbl:remove(rng)
			badness_tbl:remove(rng)
			itemmeta:set_string("params", minetest.serialize(params_tbl))
			itemmeta:set_string("params", minetest.serialize(badness_tbl))
			meta:set_string("params", minetest.serialize(item))
			meta:set_string("params", minetest.serialize(badness))
			
			minetest.get_node_timer(pos):start(5)
		end,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if not (digger or digger:is_player()) then
				return
			end
			
			local index, stack, amount = plants.functions.find_free_stack(digger, name.."seed")
			
			if index then
				local nodeparams = minetest.deserialize(oldmeta:get_string("params"))
				local stackparams = minetest.deserialize(stack:get_meta():get_string("params"))
				local nodebadness = minetest.deserialize(oldmeta:get_string("badness"))
				local stackbadness = minetest.deserialize(stack:get_meta():get_string("badness"))
				
				stackparams:insert(nodeparams)
				stackbadness:insert(nodebadness)
				
				stack:set_count(stack:get_count() +1)
				stack:get_meta():set_string("params", minetest.serialize(stackparams))
				stack:get_meta():set_string("badness", minetest.serialize(stackbadness))
				
				digger:get_inventory():set_stack("main", i, stack)
			end
		end,
		on_timer = function(pos, elapsed)
			minetest.swap_node(pos, {name = name.."1"})
			local timer_min = minetest.deserialize(minetest.get_meta(pos):get_string("params")).time.min
			local timer_max = minetest.deserialize(minetest.get_meta(pos):get_string("params")).time.max
			minetest.get_node_timer(pos):start(math.random(math.floor(timer_min +0.5), math.floor(timer_max +0.5)))
		end,
	})
end

function plants.functions.register_fruit(name, fruit_description, texture)
	local abc = {"A","B","C","D","F"}
	
	for i,n in ipairs(abc) do
		minetest.register_craftitem(name..n,{
			description = fruit_description.." "..n,
			inventory_image = texture..n..".png",
			on_use = function(itemstack, user, pointed_thing)
				hunger.eat(name, i) -- fruchtname, qualität
			end,
		})
	end
end

function plants.functions.register(name, growsteps, plant_textures, seed_description, seed_texture, fruit_description, fruit_texture, droptable, paramtable)
	plants[name] = {}
	plants[name]["params"] = paramtable
	plant[name]["drops"] = droptable
	
	plants.functions.register_plant(name, growsteps, plant_textures)
	plants.functions.register_seed(name, seed_description, seed_texture)
	plants.functions.register_fruit(name, fruit_description, fruit_texture)
end
