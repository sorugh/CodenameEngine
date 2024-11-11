package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

/**
 * Macro used to add custom fields to classes without having to override the entire file.
 */
class CustomFieldMacro {
	public static function init() {
		var injections:Map<String, Array<Field>> = [
			"lime.utils.AssetLibrary" => [
				{
					name: "tag",
					access: [APublic],
					kind: FVar(macro: funkin.backend.assets.AssetSource),
					pos: (macro null).pos,
				}
			],
		];

		for(lib => injection in injections) {
			for(field in injection) {
				var build = '@:build(macros.CustomFieldMacro.build("${MacroSerializer.run(field)}"))';
				//Sys.println('Injecting $build into $lib');
				Compiler.addGlobalMetadata(lib, build);
			}
		}
	}

	public static function build(fieldData:String) {
		var fields = Context.getBuildFields();
		fields.push(MacroUnserializer.run(fieldData));
		return fields;
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