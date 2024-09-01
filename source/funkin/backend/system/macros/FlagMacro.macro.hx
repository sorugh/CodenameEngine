package funkin.backend.system.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

using haxe.macro.Tools;

class FlagMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		var clRef = Context.getLocalClass();
		if (clRef == null)
			return fields;

		var cl = clRef.get();

		var resetExprs:Array<Expr> = [];
		var parserExprs:Array<Expr> = [];

		for (field in fields) {
			var skip = false;
			for(meta in field.meta) {
				if(meta.name == ":bypass") {
					skip = true;
					break;
				}
			}

			if(skip) continue;

			switch (field.kind) {
				case FVar(type, expr):
					if(expr == null)
						Context.error('Flags must be initialized', field.pos);
					switch(expr.expr) {
						case EConst(CIdent("true")) | EConst(CIdent("false")):
							type = macro: Bool;
						default:
							if(type == null)
								Context.error('Flags must have a type', field.pos);
					}

					var parser:Expr = null;
					var customCheck:Expr = null;

					switch(type) {
						case macro: Array<TrimmedString>:
							field.kind = FVar(macro: Array<String>, expr);
							parser = macro value.split(",").map((e) -> e.trim());
						case macro: Array<String>:
							parser = macro value.split(",");
						case macro: Array<Bool>:
							parser = macro value.split(",").map((e) -> {
								e = e.trim();
								e == "true" || e == "t" || e == "1";
							});
						case macro: Int:
							parser = macro Std.parseInt(value);
						case macro: String:
							parser = macro value;
						case macro: Bool:
							parser = macro value == "true" || value == "t" || value == "1";
						case TPath({name: "Allow", pack: [], params: params}):
							final NONE = 0;
							final STRING = 1;
							final INT = 2;
							var chosenType = NONE;

							var values:Array<String> = [];

							for(param in params) {
								switch(param) {
									case TPExpr(e):
										switch(e.expr) {
											case EConst(CString(s, kind)):
												if(chosenType != NONE && chosenType != STRING)
													Context.error("Flags Allow<> can only have one type", field.pos);
												chosenType = STRING;

												values.push(s);
											case EConst(CInt(num)):
												if(chosenType != NONE && chosenType != INT)
													Context.error("Flags Allow<> can only have one type", field.pos);
												chosenType = INT;

												values.push(num);
											default:
												Context.error("Flags Allow<> unknown type", field.pos);
										}
									default:
										Context.error("Flags must be either a Bool, Int, String, Array<String>, Array<Bool> or Array<TrimmedString>", field.pos);
								}
							}

							if(chosenType == NONE)
								Context.error("Flags Allow<> must have a type", field.pos);

							var errorMessage = 'Flags ${field.name} must be one of ${values.join(", ")}';

							var checkExpr = macro value == $v{values.shift()};
							for(v in values)
								checkExpr = macro $checkExpr || value == $v{v};

							if(chosenType == STRING) {
								parser = macro value;
								field.kind = FVar(macro: String, expr);
							}
							else if(chosenType == INT) {
								parser = macro Std.parseInt(value);
								field.kind = FVar(macro: Int, expr);
							} else {
								field.kind = FVar(macro: Any, expr);
							}

							customCheck = macro @:mergeBlock {
								if(name == $v{field.name}) {
									if($checkExpr)
										$i{field.name} = $parser;
									else
										throw $v{errorMessage};
									return true;
								}
							}

						case TPath({name: "Array", pack: []}):
							Context.error('Flags cannot be an Array that isnt a String or Bool or TrimmedString', field.pos);
						case TPath({name: "Map", pack: []}):
							Context.error('Flags cannot be a Map<K, V>', field.pos);
						default:
							Context.error("Flags must be either a Bool, Int, String, Array<String>, Array<Bool> or Array<TrimmedString>", field.pos);
					}

					if(parser == null) {
						Context.error("Flags must be either a Bool, Int, String, Array<String>, Array<Bool> or Array<TrimmedString>", field.pos);
						continue;
					}

					resetExprs.push(macro $i{field.name} = ${expr});

					// parse(name: String, value: String)

					if(customCheck != null) {
						parserExprs.push(customCheck);
					} else {
						parserExprs.push(macro @:mergeBlock {
							if(name == $v{field.name}) {
								$i{field.name} = $parser;
								return true;
							}
						});
					}
				default:
					// nothing
			}
		}

		fields.push({
			name: "reset",
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				expr: macro $b{resetExprs},
				ret: macro: Void
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		fields.push({
			name: "parse",
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "name", type: macro: String}, {name: "value", type: macro: String}],
				expr: macro {
					@:mergeBlock $b{parserExprs};

					return false;
				},
				ret: macro: Bool
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		//var printer = new haxe.macro.Printer();
		//trace(printer.printField(fields[fields.length - 2]));
		//trace(printer.printField(fields[fields.length - 1]));

		return fields;
	}
}