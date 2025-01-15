package funkin.editors.character;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterSpriteScreen extends UISubstateWindow {
	private var imagePath:String = null;
	private var onSave:String -> Void = null;

	public var imageExplorer:UIFileExplorer;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public function new(imagePath:String, ?onSave:String->Void) {
		super();
		this.imagePath = imagePath;
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = 'Edit character sprite';
		winWidth = 360; winHeight = 183;

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		super.create();

		imageExplorer = new UIImageExplorer(20, windowSpr.y + 30 + 16 + 20, 320, 58, (_, _) -> {refreshWindowSize();});
		add(imageExplorer);
		addLabelOn(imageExplorer, "Character Image File").applyMarkup(
			"Character Image File $* Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, "Save & Close", function() {
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Cancel", function() {
			close();
		}, 125);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		//closeButton.y -= closeButton.bHeight;
		add(closeButton);
		add(saveButton);

		refreshWindowSize();
	}

	public function refreshWindowSize() {
		windowSpr.bWidth = 20 + imageExplorer.bWidth + 20;
		windowSpr.bHeight = 30 + 16 + 20 + imageExplorer.bHeight + 14 + saveButton.bHeight + 14;

		saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - saveButton.bWidth;
		closeButton.x = saveButton.x - 20 - closeButton.bWidth; 
		closeButton.y = saveButton.y = imageExplorer.y + imageExplorer.bHeight + 14;
	}
}