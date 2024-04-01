package funkin.backend;

import flixel.util.FlxColor;
import flixel.text.FlxText;

class FunkinText extends FlxText {
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 16, Border:Bool = true, ?TranslationID:String) {
		super(X, Y, FieldWidth, TranslationsUtil.checkTransl(Text, TranslationID), Size);
		setFormat(Paths.font("vcr.ttf"), Size, FlxColor.WHITE);
		if (Border) {
			borderStyle = OUTLINE;
			borderSize = 1;
			borderColor = 0xFF000000;
		}
	}
}