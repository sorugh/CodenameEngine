package funkin.backend;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxColor;
import funkin.backend.utils.TranslationUtil.IFormatInfo;

class FunkinText extends FlxText {
	public var langStrID:String = null;
	private var langFormat:IFormatInfo;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 16, Border:Bool = true, ?LangStrID:String, ?Parameters:Array<Dynamic>) {
		langStrID = LangStrID;
		langFormat = TranslationUtil.getUnformatted(Text, LangStrID);

		// Should still default to the normal string if the translation is not found
		super(X, Y, FieldWidth, getFormattedText(Parameters), Size);
		setFormat(Paths.font("vcr.ttf"), Size, FlxColor.WHITE);
		if (Border) {
			borderStyle = OUTLINE;
			borderSize = 1;
			borderColor = 0xFF000000;
		}
	}

	public inline function resetLang(Parameters:Array<Dynamic>)
		return this.text = getFormattedText(Parameters);

	private inline function getFormattedText(Parameters:Array<Dynamic>)
		return langFormat.format(Parameters);
}