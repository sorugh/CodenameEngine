package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

typedef Injection = {
	var access:Array<Access>;
	var type:ComplexType;
	var ?expr:Expr;
}

/**
 * Macro used to add custom fields to classes without having to override the entire file.
 */
class CustomFieldMacro {
	public static function init() {
		var injections:Map<String, Map<String, Injection>> = [
			"lime.utils.AssetLibrary" => [
				"tag" => {
					access: [APublic],
					type: macro: funkin.backend.assets.AssetSource,
					expr: macro null
				}
			],
		];

		for(lib => injection in injections) {
			for(key => value in injection) {
				var params:Array<String> = [
					'"$lib"', '"$key"',
					'"' + MacroSerializer.run(value.access) + '"',
					'"' + MacroSerializer.run(value.type) + '"',
				];
				if(value.expr != null)
					params.push('"' + MacroSerializer.run(value.expr) + '"');

				var build = '@:build(macros.CustomFieldMacro.build(${params.join(", ")}))';
				//Sys.println('Injecting $build into $lib');
				Compiler.addGlobalMetadata(lib, build);
			}
		}
	}

	public static function build(lib:String, fieldName:String, access:String, type:String, ?defaultValue:String) {
		var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null) return fields;
		var cl = clRef.get();

		var key = cl.module;
		var fkey = cl.module + "." + cl.name;

		if(lib != cl.module) {
			return fields;
		}

		var access:Array<Access> = MacroUnserializer.run(access);
		var type:ComplexType = MacroUnserializer.run(type);
		var defaultValue:Expr = MacroUnserializer.run(defaultValue);

		var fields = Context.getBuildFields();

		fields.push({
			name: fieldName,
			access: access,
			kind: FVar(type, defaultValue),
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

class MacroSerializer extends haxe.Serializer {
	public static function run(v:Dynamic) {
		var s = new MacroSerializer();
		s.useEnumIndex = true;
		s.serialize(v);
		return s.toString();
	}

	public override function serialize(v:Dynamic) {
		switch (Type.typeof(v)) {
			case TClass(c):
				if (!(#if neko untyped c.__is_String #else c == String #end)) {
					switch (#if (neko || cs || python) Type.getClassName(c) #else c #end) {
						case #if (neko || cs || python) "haxe.macro.Position" #else c if(Type.getClassName(c) == "haxe.macro.Position") #end:
							buf.add("P");
							var info = Context.getPosInfos(v);
							serialize(info.min);
							serialize(info.max);
							serialize(info.file);
							return;
						default:
					}
				}
			default:
		}
		super.serialize(v);
	}
}

class MacroUnserializer extends haxe.Unserializer {
	public static function run(s:String):Dynamic {
		var u = new MacroUnserializer(s);
		return u.unserialize();
	}

	public override function unserialize():Dynamic {
		var c = get(pos++);
		switch (c) {
			case "P".code:
				var min = unserialize();
				var max = unserialize();
				var file = unserialize();
				var o = Context.makePosition({min: min, max: max, file: file});
				return o;
		}
		pos--;
		return super.unserialize();
	}

}
#end