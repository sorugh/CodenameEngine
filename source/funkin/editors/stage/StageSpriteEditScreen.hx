package funkin.editors.stage;

import funkin.editors.stage.elements.StageElementButton;
import funkin.editors.ui.UISoftcodedWindow;

using StringTools;


class StageSpriteEditScreen extends UISoftcodedWindow {
	public var data:StageElementButton;
	public var sprite:FunkinSprite;

	public function new(data:StageElementButton) {
		this.data = data;
		this.sprite = data.getSprite();
		super("layouts/stage/spriteEditScreen.xml", [
			"stage" => StageEditor.instance.stage,
			"sprite" => sprite,
			"data" => data,
			"exID" => StageEditor.exID,
			"getEx" => function(name:String):Dynamic {
				return sprite.extra.get(StageEditor.exID(name));
			}
		]);
	}

	public override function create() {
		super.create();
	}

	public override function saveData() {
		super.saveData();
		data.updateInfo(sprite);
	}
}