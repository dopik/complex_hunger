--[[
	Place recipes at the bottom of this file.
	
	compost.register_recipe({type, itemname, amount})
		* type = <"fuel"|"item">
			+ "fuel" : plantstuff to be composted
			+ "item" : dirtitems that are converted to mulch
		* itemname = name of the item for the recipe
		* amount = time that the item composts for/ needs to be composted for
--]]

compost.register_recipe = function(tbl)
	if not (tbl.type and tbl.itemname and tbl.amount) then
		return
	end
	
	if tbl.type == "fuel" then
		compost.input[tbl.itemname] = tbl.amount
	elseif tbl.type == "item" then
		compost.output[tbl.itemname] = tbl.amount
	end
end

compost.register_recipe({type = "fuel", itemname = "default:apple", amount = 60})

compost.register_recipe({type = "item", itemname = "default:dirt", amount = 90})