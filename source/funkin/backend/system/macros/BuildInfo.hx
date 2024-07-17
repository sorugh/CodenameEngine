package funkin.backend.system.macros;

#if macro
class BuildInfo {
	public static function printBuildInfo() {
		Sys.println('[ BUILD INFO ]');
		Sys.println('Haxe Version: ${haxe.macro.Context.definedValue("haxe")}');
		Sys.println('Target Platform: ${
			#if windows "Windows"
			#elseif mac "Mac"
			#elseif linux "Linux"
			#elseif android "Android"
			#elseif ios "iOS"
			#else "Unknown"
			#end
		}');
		Sys.println('Build Date: ${Date.now().toString()}');
		Sys.println('');
	}
}
#end