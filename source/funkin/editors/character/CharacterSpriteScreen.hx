package funkin.editors.character;

import haxe.io.Bytes;
import flixel.util.typeLimit.OneOfTwo;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterSpriteScreen extends UISubstateWindow {
	private var imagePath:String = null;
	private var onSave:(String, Bool) -> Void = null;

	public var ogImageFiles:Map<String, OneOfTwo<String, Bytes>> = [];
	public var imageExplorer:UIImageExplorer;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public function new(imagePath:String, ?onSave:(String, Bool)->Void) {
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

		imageExplorer = new UIImageExplorer(20, windowSpr.y + 30 + 16 + 20, imagePath, 320, 58, (_, _) -> {onLoadImage();});
		add(imageExplorer);
		addLabelOn(imageExplorer, "Character Image File").applyMarkup(
			"Character Image File $* Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		ogImageFiles = imageExplorer.imageFiles.copy();

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, "Save & Close", function() {
			imageExplorer.saveFiles('${Paths.getAssetsRoot()}/images/characters', () -> {
				onSave(imageExplorer.imageName, imageExplorer.isAtlas);
				close();
			});
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;
		saveButton.selectable = false;

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

	public function onLoadImage() {
		refreshWindowSize();

		if (imageExplorer == null || imageExplorer.imageFiles == null) return;
		var filesSame = CoolUtil.deepEqual(ogImageFiles, imageExplorer.imageFiles);
		saveButton.selectable = !filesSame && !CoolUtil.isMapEmpty(imageExplorer.imageFiles) && (imageExplorer.animationList.length > 0);
	}

	public function refreshWindowSize() {
		if (imageExplorer == null) return;
		windowSpr.bWidth = 20 + imageExplorer.bWidth + 20;
		windowSpr.bHeight = 30 + 16 + 20 + imageExplorer.bHeight + 14 + saveButton.bHeight + 14;

		saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - saveButton.bWidth;
		closeButton.x = saveButton.x - 20 - closeButton.bWidth; 
		closeButton.y = saveButton.y = imageExplorer.y + imageExplorer.bHeight + 14;
	}
}