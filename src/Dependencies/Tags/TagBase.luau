----- Module / Class / Object Table -----------
local Module = {}
local Object = {}
Object.__index = Object

----- Loaded Services -----

----- Util / Modules / Shared -----

----- Types -----
local Types = require(script.Parent.Parent:WaitForChild("Types"))

----- Public Variables -----

----- Public Methods -----
function Module.new()
	local self = setmetatable({}, Object)
	
	self.Indexes = {"test"}
	
	return self
end

----- Public Object Methods -----
-- Return a string to replace the entire comment, this is mostly for cases where you want to modify the comment slightly
function Object:Run(Item: Types.ResponseItem, Text: string, FullComment: string): string?
	print("Tag Base Ran!")
end

----- Private Object Methods -----

return Module