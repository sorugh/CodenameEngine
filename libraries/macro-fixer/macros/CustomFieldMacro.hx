package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Compiler;

using StringTools;

/**
 * Macro used to add custom fields to classes without having to override the entire file.
 */
class CustomFieldMacro {
	public static function init() {
		Compiler.addGlobalMetadata("lime.utils", '@:build(macros.CustomFieldMacro.build("lime.utils.AssetLibrary", "tag", "funkin.backend.assets.AssetSource"))');
	}

	// TODO: Add support for default values
	public static function build(lib:String, fieldName:String, type:String) {
		var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null) return fields;
		var cl = clRef.get();

		var key = cl.module;
		var fkey = cl.module + "." + cl.name;

		if(lib != cl.module) {
			return fields;
		}

		var fields = Context.getBuildFields();

		fields.push({
			name: fieldName,
			access: [APublic],
			kind: FVar(getTPath(type)),
			pos: Context.currentPos()
		});

		return fields;
	}

	public static function getTPath(type:String) {
		var arr = type.split(".");
		return TPath({
			pack: arr.slice(0, arr.length - 1),
			name: arr[arr.length - 1]
		});
	}
}
#end