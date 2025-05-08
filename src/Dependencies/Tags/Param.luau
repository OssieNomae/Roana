----- Module / Class / Object Table -----------
local Module = require(script.Parent:WaitForChild("TagBase")).new()

----- Public Variables -----
Module.Indexes = {"param"}

----- Public Methods -----
function Module:Run(Item, Input, Comment)
	if not Input then return end
	Item.CustomParam = true
	
	if not Item.CustomReturn then
		Item.detail = "Param: "..Input
	else
		Item.detail = `Param: {Input}\n{Item.detail}`
	end
end

return Module