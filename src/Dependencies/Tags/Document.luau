----- Module / Class / Object Table -----------
local Module = require(script.Parent:WaitForChild("TagBase")).new()

----- Private Methods -----
local function GetRobloxLink(Text: string): string?
	return string.match(Text, "(https?://[a-zA-Z0-9%-]+%.?roblox%.com[^%s]*)")
end

----- Public Variables -----
Module.Indexes = {"document"}

----- Public Methods -----
function Module:Run(Item, Input, Comment)
	if not Input then return end
	
	-- Hopefully we can get support for hyperlinking...
	Item.learnMoreLink = GetRobloxLink(Input) -- only roblox.com domains are allowed
end

return Module