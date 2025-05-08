--[[
	License: Licensed under the MIT License
	Version: 1.0.0
	Authors:
		OssieNomae - 2025
	Credits:
		"Custom Function Comments" plugin by Arctic_Vibes
		https://create.roblox.com/store/asset/118937729102831/Custom-Function-Comments

	Roana: Roana is a Roblox studio plugin that enhances user-defined function documentation with Tags and Limited Markdown.
	
	Raona was designed to work with Moonwave styled documentation.
	
	--------------------------------
	
	- bold Text: **Text**
	- italic Text: *Text*
	- superscript: ^Text^
	
	@deprecated
	@document https://create.roblox.com/docs/reference/engine/classes/ScriptEditorService#RegisterAutocompleteCallback
	@param executor (resolve: (...: any) -> (), reject: (...: any) -> (), onCancel: (abortHandler?: () -> ()) -> boolean) -> ()
	@return Promise 
	
	this is supposed to be the code example
	```lua
	local Result = Test(true)
	if not Result then
		Test(true)
	end
	```
]]--

----- Module Settings -----
local FUNCTION_AUTOCOMPLETE_NAME = "Roana_Function"
local Dependencies = script:WaitForChild("Dependencies") -- Folder with the other modules

----- Loaded Services -----
local ScriptEditorService = game:GetService("ScriptEditorService")
local RunService = game:GetService("RunService")

if RunService:IsRunning() then return end -- This plugin doesn't need to run in test mode

----- Types -----
local Types = require(Dependencies:WaitForChild("Types"))

----- Private Variables -----
local Tags = Dependencies:WaitForChild("Tags")

local TagModules = { -- everything with @string whatever
	Deprecated = require(Tags:WaitForChild("Deprecated")),
	Document = require(Tags:WaitForChild("Document")),
	Param = require(Tags:WaitForChild("Param")),
	Return = require(Tags:WaitForChild("Return")),
}

----- Private Methods -----
local function ParseForTags(Text: string, Item: Types.ResponseItem)
	for _,Tag in pairs(TagModules) do
		for _,TargetIndex in pairs(Tag.Indexes) do
			-- Text.."<br>" is added so that the last line is detected in this regex match
			local Index, Input = string.match(Text.."<br>", `@({TargetIndex})%s?(.-)<br>`)
			if not Index then continue end
			
			local NewText = Tag:Run(Item, Input, Text)
			if not NewText then continue end
			
			Text = NewText
		end
	end
	
	-- Bold all tags, even the ones that don't do anything
	Text = string.gsub(Text.."<br>", "@([%w_]+)%s?(.-)<br>", function(Index, Input)
		return `**@{Index}** {Input}<br>` --"**" .. Index .. "** " .. Rest .. "<br>"
	end)
	
	return Text
end

-- We do not process code text because it has barely any difference on roblox studio, and makes the text less readable
local function ParseMarkdown(Text: string)
	-- Helper function to handle escaped markdown
	local function EscapeMarkdown(str: string)
		-- Replace escaped markdown symbols with placeholders
		str = str:gsub("\\%*%*", "##ESCBOLD##")
		str = str:gsub("\\%*", "##ESCITALIC##")
		str = str:gsub("\\%^", "##ESCSUP##")
		return str
	end
	
	-- Helper function to restore escaped markdown
	local function RestoreEscaped(str: string)
		str = str:gsub("##ESCBOLD##", "**")
		str = str:gsub("##ESCITALIC##", "*")
		str = str:gsub("##ESCSUP##", "^")
		return str
	end

	-- Escape backslash sequences first
	Text = EscapeMarkdown(Text)
	-- Process bold Text: ** Text **
	Text = Text:gsub("%*%*([^%*]+)%*%*", "<strong>%1</strong>")
	-- Process italic Text: * Text *
	Text = Text:gsub("%*([^<%*]-)%*", "<em>%1</em>")
	-- Process superscript: ^ Text ^
	Text = Text:gsub("%^([^<%^]-)%^", "<sup>%1</sup>")
	-- Restore escaped sequences
	Text = RestoreEscaped(Text)

	return Text
end

-- Process line breaks based on whitespace
local function ProcessLineBreaks(Text: string)
	-- Look for consecutive line breaks and preserve them (double line breaks)
	Text = Text:gsub("<br>%s*<br>", "##KEEPBREAK##")
	-- Remove line breaks with preceding whitespace and any trailing whitespace
	Text = Text:gsub("%s+<br>%s*", " ")
	-- Restore preserved line breaks
	Text = Text:gsub("##KEEPBREAK##", "<br><br>")
	
	return Text
end

local function CountLeadingTabs(Line)
	return #(Line:match("^(%s*)") or "")
end

local function UnindentCodeBlock(Text: string): string
	local Lines = {}
	for Line in Text:gmatch("([^\n]*)\n?") do
		table.insert(Lines, Line)
	end
	
	local MinIndent
	for _, Line in ipairs(Lines) do
		if Line:match("%S") then  -- skip empty lines
			local Tabs = CountLeadingTabs(Line)
			if MinIndent == nil or Tabs < MinIndent then
				MinIndent = Tabs
			end
		end
	end

	local Neutralized = {}
	for _, Line in ipairs(Lines) do
		local Pattern = "^" .. string.rep("\t", MinIndent or 0)
		table.insert(Neutralized, (Line:gsub(Pattern, "")))
	end

	return table.concat(Neutralized, "\n")
end
	

local function ProcessCodeSample(Comment: string, Item: Types.ResponseItem)
	local Split = string.split(Comment, "```")
	local CodeSample = Split[2]
	if CodeSample then
		-- Remove trialing breaks after ``` split
		CodeSample = CodeSample:gsub("^%w+<br>.", "")
		CodeSample = CodeSample:gsub("^%w+\n.", "")
		
		-- Add trailing tab before ``` split for consistancy when copying sample code
		local Trailing = Split[1]:match("([ \t]+)$")
		local Count = Trailing and #Trailing or 0
		CodeSample = string.rep("\t", Count)..CodeSample

		CodeSample = CodeSample:gsub("<br>([ \t]*)", function(Whitespace)
			return "\n"..Whitespace
		end)
		
		-- Remove any remaining <br> tags
		CodeSample = CodeSample:gsub("<br>", "\n")
		CodeSample = UnindentCodeBlock(CodeSample)
		
		Item.codeSample = CodeSample:match("(.-)%s*$") -- Trim preceding whitespace
		
		if Split[3] and string.len(Split[3]) > 1 then
			Comment = Split[1]..Split[3]
		else
			Comment = Split[1]
		end
		Comment = Comment:gsub("<br>%s*$", "") -- Remove trailing Break + Whitespace
	end
	
	return Comment
end

----- Connections -----
ScriptEditorService:RegisterAutocompleteCallback(FUNCTION_AUTOCOMPLETE_NAME, 10, function(Request: Types.Request, Response: Types.Response)
	for _,Item in Response.items do
		-- Prevent processing items that aren't functions, are official api functions, or don't have a comment to parse
		if Item.kind ~= Enum.CompletionItemKind.Function then continue end
		if Item.learnMoreLink ~= "" then continue end
		if not Item.documentation or Item.documentation.value == "" then continue end
		
		-- Remove surrounding <p>..</p> tags for processing
		local Comment = Item.documentation.value:sub(4, -5)
		
		Comment = ParseForTags(Comment, Item)
		Comment = ProcessCodeSample(Comment, Item)
		Comment = ProcessLineBreaks(Comment)
		
		-- Side Note: These aren't integral to the comment (?) but are nonetheless present in every comment
		Item.documentation.value = `<p>{ParseMarkdown(Comment)}</p>`
	end
	
	return Response
end)

plugin.Unloading:Connect(function()
	ScriptEditorService:DeregisterAutocompleteCallback(FUNCTION_AUTOCOMPLETE_NAME)
end)