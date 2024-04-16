package funkin.editors.stage.elements;

import haxe.xml.Access;
import flixel.util.FlxColor;

using flixel.util.FlxColorTransformUtil;

class StageElementButton extends UIButton {
	public var xml:Access;

	public var editButton:UIButton;
	public var editIcon:FlxSprite;

	public var visibleButton:UIButton;
	public var visibleIcon:FlxSprite;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var isHidden:Bool = false;

	public var selected:Bool = false;

	public var tagColor:UISliceSprite;

	public function new(x:Float,y:Float, xml:Access) {
		this.xml = xml;
		super(x,y, getInfoText(), function () {
			onSelect();
			//CharacterEditor.instance.playAnimation(this.sprite.name);
		}, StageEditor.SPRITE_WINDOW_WIDTH, StageEditor.SPRITE_WINDOW_BUTTON_HEIGHT);
		autoAlpha = false;

		tagColor = new UISliceSprite(x, y, 10, StageEditor.SPRITE_WINDOW_BUTTON_HEIGHT, 'editors/ui/button');
		tagColor.alpha = 1; // Make entire sprite transparent
		tagColor.selectable = false;
		tagColor.active = false;
		//members.push(tagColor);

		topAlpha = middleAlpha = bottomAlpha = 0.7;

		field.alignment = LEFT;

		visibleButton = new UIButton(x+282+17, y, "", function () {
			onGhostClick();
			//CharacterEditor.instance.ghostAnim(this.anim);
		}, 32);
		visibleButton.autoAlpha = false;
		members.push(visibleButton);

		visibleIcon = new FlxSprite(visibleButton.x + 8, visibleButton.y + 8).loadGraphic(Paths.image('editors/stage/visible-icon'), true, 16, 16);
		visibleIcon.animation.add("visible", [0]);
		visibleIcon.animation.add("invisible", [1]);
		visibleIcon.animation.play("visible");
		visibleIcon.antialiasing = false;
		visibleIcon.updateHitbox();
		members.push(visibleIcon);

		editButton = new UIButton(visibleButton.x+32+17, y, "", function () {
			onEdit();
		}, 32);
		editButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		editButton.color = FlxColor.YELLOW;
		editButton.autoAlpha = false;
		members.push(editButton);

		editIcon = new FlxSprite(editButton.x + 8, editButton.y + 8).loadGraphic(Paths.image('editors/character/edit-button'));
		editIcon.antialiasing = false;
		members.push(editIcon);

		deleteButton = new UIButton(editButton.x+32+17, y, "", function () {
			onDelete();
		}, 32);
		deleteButton.color = FlxColor.RED;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	var _lastSelected:Bool = false;

	public override function update(elapsed:Float) {
		editButton.selectable = visibleButton.selectable = deleteButton.selectable = selectable;
		editButton.shouldPress = visibleButton.shouldPress = deleteButton.shouldPress = shouldPress;

		hovered = !deleteButton.hovered;
		updatePos();
		super.update(elapsed);
		field.x += 12;

		tagColor.color = color;
	}

	//private var _lastHovered:Bool = false;

	public override function draw() {
		//if(_lastHovered != (_lastHovered = hovered && !pressed)) {
		if(_lastSelected != (_lastSelected = selected)) {
			updateColorTransform();
		}
		super.draw();
	}

	/*public override function setFrameOffset() {
		var _frameOffset = 0;
		if(selected) _frameOffset = 9;
		if(hovered && pressed) _frameOffset = 18;
		framesOffset = _frameOffset;
	}*/

	public override function updateColorTransform() {
		super.updateColorTransform();

		if(selected) {
			useColorTransform = true;
			colorTransform.setOffsets(70, 70, 70, 0);
		} else {
			colorTransform.setOffsets(0, 0, 0, 0);
		}
	}

	public function updateInfo() {
		field.text = getInfoText();

		visibleIcon.animation.play(isHidden ? "invisible" : "visible");
		//visibleIcon.alpha = !isHidden ? 1 : 0.5;
	}

	public function updatePos() {
		// buttons
		var spacing = 8;
		var buttonY = y + (bHeight - 32) / 2;
		deleteButton.x = bWidth - deleteButton.bWidth - spacing;
		deleteButton.y = buttonY;
		editButton.x = deleteButton.x - editButton.bWidth - spacing;
		editButton.y = buttonY;
		visibleButton.x = editButton.x - visibleButton.bWidth - spacing;
		visibleButton.y = buttonY;
		//deleteButton.x = (editButton.x = (visibleButton.x = (x+282+17))+32+17)+32+17;
		//deleteButton.y = editButton.y = visibleButton.y = y;
		// icons
		visibleIcon.x = visibleButton.x + 8; visibleIcon.y = visibleButton.y + 8;
		editIcon.x = editButton.x + 8; editIcon.y = editButton.y + 8;
		deleteIcon.x = deleteButton.x + (15/2); deleteIcon.y = deleteButton.y + 8;

		tagColor.x = x;// + bWidth - tagColor.bWidth;
		tagColor.y = y;
	}

	public function getSprite():FunkinSprite {
		return null;
	}

	public function canRender() {
		return true;
	}

	public function getName():String {
		return "UNKNOWN";
	}

	public function onSelect() {
		// TODO: implement
	}

	public function onGhostClick() {
		// TODO: implement
	}

	public function onEdit() {
		// TODO: implement
	}

	public function onDelete() {
		// TODO: implement
	}

	public function getPos():FlxPoint {
		return FlxPoint.get(-1, -1);
	}

	public function getInfoText():String {
		var pos = getPos();
		var text = '${getName()} (${CoolUtil.quantize(pos.x, 100)}, ${CoolUtil.quantize(pos.y, 100)})';
		var sprite = getSprite();
		if(sprite != null) {
			text += '\nScale: (${CoolUtil.quantize(sprite.scale.x, 100)}, ${CoolUtil.quantize(sprite.scale.y, 100)})';
			text += '\nScroll: (${CoolUtil.quantize(sprite.scrollFactor.x, 100)}, ${CoolUtil.quantize(sprite.scrollFactor.y, 100)})';
		}
		pos.put();
		return text;
	}
}