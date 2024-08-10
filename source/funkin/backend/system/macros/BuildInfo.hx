package funkin.backend.system.macros;

using StringTools;

#if macro
class BuildInfo {
	public static function printBuildInfo() {
		if(haxe.macro.Context.defined("display")) return;
		var haxeVersion = haxe.macro.Context.definedValue("haxe");
		Sys.println('--- BUILD INFO ---');
		Sys.println('Haxe Version: ${haxeVersion}');
		try {
			var lastBuiltWith:Null<String> = null;
			var compiling = #if final "final" #elseif debug "debug" #else "release" #end;
			var target = #if windows "windows" #elseif mac "macos" #elseif linux "linux" #elseif android "android" #elseif ios "ios" #elseif html5 "html5" #else "" #end;
			if(target == "") throw "Unknown target";
			var exportPath = Sys.getCwd() + "/export/" + compiling + "/" + target + "/";
			exportPath += "obj/Options.txt";

			var options = sys.io.File.getContent(exportPath);
			for(option in options.split("\n")) {
				if(option.startsWith("haxe=")) {
					lastBuiltWith = option.substr(5);
					break;
				}
			}

			if(lastBuiltWith != null && lastBuiltWith != haxeVersion)
				Sys.println('Last Built With Haxe: ${lastBuiltWith} [!!!! MAKE SURE IF YOU SWITCHED VERSIONS YOU DELETE EXPORT FOLDERS !!!!]');
		} catch(e) {}
		Sys.println('Target Platform: ${
			#if windows "Windows"
			#elseif mac "Mac"
			#elseif linux "Linux"
			#elseif android "Android"
			#elseif ios "iOS"
			#elseif html5 "HTML5"
			#else "Unknown"
			#end
		}');
		Sys.println('Build Date: ${Date.now().toString()}');
		Sys.println('');
	}
}
#end