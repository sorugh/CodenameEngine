package funkin.backend.assets;

enum abstract AssetSource(Null<Bool>) from Bool from Null<Bool> to Null<Bool> {
	var SOURCE = true;
	var MODS = false;
	var BOTH = null;

	@:from public static function fromString(string:String):AssetSource
	{
		return switch (string.trim().toLowerCase())
		{
			case "source": SOURCE;
			case "mods": MODS;
			case "both": BOTH;
			default: MODS;
		}
	}

	@:to public inline function toString():String
	{
		return switch (this)
		{
			case SOURCE: "source";
			case MODS: "mods";
			case BOTH: "both";
		}
	}
}