----- Module / Class / Object Table -----------
local Module = require(script.Parent:WaitForChild("TagBase")).new()

----- Public Variables -----
Module.Indexes = {"return"}

----- Public Methods -----
function Module:Run(Item, Input, Comment)
	if not Input then return end
	Item.CustomReturn = true
	
	if not Item.CustomParam then
		Item.detail = ""
	else
		Item.detail ..= "\n"
	end
	
	Item.detail ..= "Return: "..Input
end

return Module