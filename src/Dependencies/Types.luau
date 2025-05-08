-- Autocomplete Types
export type Request = {
	position: {
		line: number,
		character: number
	},
	textDocument: {
		document: ScriptDocument?,
		script: LuaSourceContainer?
	}
}

export type ResponseItem = {
	label: string,
	kind: Enum.CompletionItemKind?,
	tags: {Enum.CompletionItemTag}?,
	detail: string?,
	documentation: {
		value: string,
	}?,
	overloads: number?,
	learnMoreLink: string?,
	codeSample: string?,
	preselect: boolean?,
	textEdit: {
		newText: string,
		insert: { start: { line: number, character: number }, ["end"]: { line: number, character: number } },
		replace: { start: { line: number, character: number }, ["end"]: { line: number, character: number } },
	}?
}

export type Response = {
	items: { ResponseItem },
}

return nil