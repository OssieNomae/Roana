----- Module / Class / Object Table -----------
local Module = require(script.Parent:WaitForChild("TagBase")).new()

----- Public Variables -----
Module.Indexes = {"deprecated"}

----- Public Methods -----
function Module:Run(Item, Input, Comment)
	table.insert(Item.tags, Enum.CompletionItemTag.Deprecated)
end

return Module