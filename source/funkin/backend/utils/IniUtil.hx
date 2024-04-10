package funkin.backend.utils;

typedef IniMap = Map<String, String>;

/**
 * Parses an ini file and returns a map of its contents.
 * WARNING: This is not a full ini parser, it only supports the basics. So no sections
 */
class IniUtil {
	public static inline function parseAsset(assetPath:String, ?defaultVariables:IniMap):IniMap
		return parseString(Assets.getText(assetPath), defaultVariables);

	public static function parseString(data:String, ?defaultVariables:IniMap):IniMap {
		var trimmed:String;
		var splitContent = [for(e in data.split("\n")) if ((trimmed = e.trim()) != "") trimmed];

		var finalMap:IniMap = [];
		if (defaultVariables != null)
			for(k=>e in defaultVariables)
				finalMap[k] = e;

		for(line in splitContent) {
			// comment
			if (line.startsWith(";")) continue;
			// sections; not supported yet
			if (line.startsWith("[") && line.endsWith("]")) continue;

			var index = line.indexOf("=");
			var name = line.substr(0, index).trim();
			var value = line.substr(index+1).trim();

			if (value.startsWith("\"") && value.endsWith("\""))
				value = value.substr(1, value.length - 2);

			if (value.length == 0 || name.length == 0)
				continue;

			finalMap[name] = value;
		}
		return finalMap;
	}
}