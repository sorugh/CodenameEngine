package funkin.editors.stage;

import funkin.editors.stage.elements.StageElementButton;
import funkin.editors.ui.UISoftcodedWindow;

using StringTools;


class StageSpriteEditScreen extends UISoftcodedWindow {
	public var newSprite:Bool = false;
	public var data:StageElementButton;
	public var sprite:FunkinSprite;
	var isSaving:Bool = false;

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
			},
			"setEx" => function(name:String, value:Dynamic) {
				sprite.extra.set(StageEditor.exID(name), value);
			},
		]);
	}

	public override function create() {
		super.create();
	}

	public override function saveData() {
		isSaving = true;
		super.saveData();
		data.updateInfo(sprite);
	}

	public override function close() {
		if (!isSaving && newSprite) {
			data.onDelete();
			trace("deleting sprite");
		}
		super.close();
	}
}