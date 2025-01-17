package funkin.editors.alphabet;

import haxe.xml.Access;
import funkin.game.Character;
import funkin.options.OptionsScreen;
import funkin.options.type.IconOption;
import funkin.options.type.NewOption;
import funkin.options.type.TextOption;
import funkin.options.type.OptionType;
import haxe.io.Path;

class AlphabetSelection extends EditorTreeMenu
{
	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("editor.alphabet.selection." + id, args);

	public override function create()
	{
		bgType = "charter";
		super.create();

		var modsList:Array<String> = [];
		for(file in Paths.getFolderContent('data/alphabet/', true, BOTH)) // mods ? MODS : BOTH
			if (Path.extension(file) == "xml") modsList.push(CoolUtil.getFilename(file));

		var list:Array<OptionType> = [
			for (typeface in modsList)
				new AlphabetIconOption(typeface, translate("acceptTypeface"), typeface, function() {
					FlxG.switchState(new AlphabetEditor(typeface));
				})
		];

		var newChar = translate("newTypeface");
		list.insert(0, new NewOption(newChar, newChar, function() {
			openSubState(new UIWarningSubstate(translate("warnings.notImplemented-title"), translate("warnings.notImplemented-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: function(t) {}}
			]));
		}));

		main = new OptionsScreen(TU.translate("editor.alphabet.name"), translate("desc"), list);

		DiscordUtil.call("onEditorTreeLoaded", ["Alphabet Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}
}

class AlphabetIconOption extends TextOption {
	public var iconSpr:FlxSprite;

	public function new(name:String, desc:String, typeface:String, callback:Void->Void) {
		super(name, desc, callback);

		var xml = Xml.parse(Assets.getText(Paths.xml('alphabet/$typeface'))).firstElement();
		var spritesheet = null;
		for(node in xml.elements()) {
			if (node.nodeName == "spritesheet") {
				spritesheet = node.firstChild().nodeValue;
				break;
			}
		}

		var useColorOffsets = xml.get("useColorOffsets").getDefault("false") == "true";


		// todo fix crash if invalid spritesheet;

		iconSpr = new FlxSprite();
		iconSpr.frames = Paths.getFrames(spritesheet);
		iconSpr.antialiasing = true;
		var frameToUse = iconSpr.frames.frames[0];
		for(frame in iconSpr.frames.frames) {
			if (frame.name.toUpperCase().startsWith("A")) {
				frameToUse = frame;
				break;
			}
		}
		iconSpr.frame = frameToUse;
		if(useColorOffsets) {
			iconSpr.colorTransform.color = -1;
		}
		iconSpr.setPosition(90 - iconSpr.width - 20, (__text.height - iconSpr.height) / 2);
		add(iconSpr);
	}
}