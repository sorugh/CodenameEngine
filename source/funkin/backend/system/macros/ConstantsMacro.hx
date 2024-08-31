package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ConstantsMacro {
	#if macro
	static function build() {
		var fields = Context.getBuildFields();

		var resetFields:Array<Expr> = [];
		var lazyFields:Array<Expr> = [];
		for(field in fields) {
			switch(field.kind) {
				case FVar(t, e):
					resetFields.push(macro $i{field.name} = ${e});

					var hasLazy = false;
					for(meta in field.meta) {
						if(meta.name == ":lazy") {
							hasLazy = true;
							break;
						}
					}

					if(hasLazy) {
						lazyFields.push(macro $i{field.name} = ${e});
						field.kind = FVar(t, null);
					}
				default:
			}
		}

		fields.push({
			name: "reset",
			pos: Context.currentPos(),
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				ret: null,
				expr: macro {
					$b{resetFields}
				}
			})
		});

		fields.push({
			name: "init",
			pos: Context.currentPos(),
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				ret: null,
				expr: macro {
					$b{lazyFields}
				}
			})
		});

		return fields;
	}
	#end
}