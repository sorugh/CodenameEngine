package funkin.editors.character;

import flixel.util.FlxColor;
import funkin.editors.stage.StageEditor;
import funkin.editors.extra.PropertyButton;
import flixel.graphics.FlxGraphic;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import funkin.game.Character;

using funkin.backend.utils.BitmapUtil;

typedef CharacterExtraInfo = {
	var icon:String;
	var iconColor:Null<FlxColor>;
	var holdTime:Float;
	var customProperties:Map<String, Dynamic>;
}

class CharacterInfoScreen extends UISubstateWindow {
	public var character:Character;

	public var iconColorPicker:UIIconColorPicker;
	public var iconColorWheel:UIColorwheel;

	public var useDurationCheckbox:UICheckbox;
	public var durationStepper:UINumericStepper;

	public var customPropertiesButtonList:UIButtonList<PropertyButton>;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var onSave:(info:CharacterExtraInfo) -> Void = null;

	public function new(character:Character, onSave:(info:CharacterExtraInfo) -> Void) {
		this.character = character;
		this.onSave = onSave;
		super();
	}

	public override function create() {
		winTitle = 'Edit Character Properties...';
		winWidth = 824; winHeight = 400;

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Edit Character Info", 28));

		iconColorPicker = new UIIconColorPicker(title.x, title.y + title.height + 38, character.getIcon(), character.antialiasing, null);
		add(iconColorPicker);
		addLabelOn(iconColorPicker, "Icon");

		iconColorWheel = new UIColorwheel(iconColorPicker.x+12+125+12+22, iconColorPicker.y, character.iconColor);
		add(iconColorWheel);
		addLabelOn(iconColorWheel, "Icon Color");

		iconColorPicker.colorWheel = iconColorWheel;

		durationStepper = new UINumericStepper(iconColorWheel.x, iconColorWheel.y + 125 + 36, character.holdTime == -1 ? 4 : character.holdTime, 0.001, 2, 0, 9999999, 74);
		add(durationStepper);
		addLabelOn(durationStepper, "Sing Duration");

		useDurationCheckbox = new UICheckbox(durationStepper.x + durationStepper.bWidth + 20, durationStepper.y+6, "Use Sing Duration?", character.holdTime != -1);
		useDurationCheckbox.onChecked = (checked:Bool) -> {durationStepper.selectable = checked;};
		add(useDurationCheckbox);

		durationStepper.selectable = useDurationCheckbox.checked;

		customPropertiesButtonList = new UIButtonList<PropertyButton>(iconColorWheel.x+iconColorWheel.bWidth+22, iconColorWheel.y, 290, 200, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}

		for (prop=>val in character.extra)
			if (prop != StageEditor.exID("bounds"))
				customPropertiesButtonList.add(new PropertyButton(prop, val, customPropertiesButtonList));

		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, "Custom Values (Advanced)");

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveCharacterInfo();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, "Close", function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
	}

	public function saveCharacterInfo() {
		@:privateAccess durationStepper.__onChange(durationStepper.label.text);

		if (onSave != null) onSave({
			icon: iconColorPicker.iconTextBox.label.text,
			iconColor: iconColorWheel.curColor,
			holdTime: useDurationCheckbox.checked ? durationStepper.value : -1,
			customProperties: [
				for (val in customPropertiesButtonList.buttons.members)
					val.propertyText.label.text => val.valueText.label.text
			]
		});
	}
}

class UIIconColorPicker extends UISliceSprite {
	public var colorWheel:UIColorwheel;

	public var iconSprite:FlxSprite;
	public var iconTextBox:UITextBox;

	public var pickerButton:UIButton;
	public var pickerIcon:FlxSprite;
	
	public function new(x:Float, y:Float, icon:String, antialaising:Bool, colorWheel:UIColorwheel) {
		super(x, y, 12+125+12, 4+125+4+32+12, 'editors/ui/inputbox');

		this.colorWheel = colorWheel;

		iconTextBox = new UITextBox(x+12, y+4+125+4, icon, 125);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		members.push(iconTextBox);

		members.push(iconSprite = new FlxSprite());
		iconSprite.antialiasing = antialaising;

		pickerButton = new UIButton(x+12+125-26, y+12, "", colorPick, 26, 26);
		pickerButton.frames = Paths.getFrames('editors/ui/inputbox');
		members.push(pickerButton);

		pickerIcon = new FlxSprite(pickerButton.x+7, pickerButton.y+7).loadGraphic(Paths.image("editors/ui/picker"));
		members.push(pickerIcon);

		updateIcon(icon);
	}

	var __path:String = null;
	public function updateIcon(icon:String) {
		if (iconSprite.animation.exists(icon)) return;
		@:privateAccess iconSprite.animation.clearAnimations();

		var path:String = Paths.image('icons/$icon');
		if (!Assets.exists(path)) path = Paths.image('icons/face');

		iconSprite.loadGraphic(__path = path, true, 150, 150);
		iconSprite.animation.add(icon, [0], 0, false);
		iconSprite.animation.play(icon);

		iconSprite.scale.set(125/150, 125/150);
		iconSprite.updateHitbox();
		iconSprite.setPosition(x+12, y+4);

		__cachedColor = null;
	}

	var __cachedColor:Null<FlxColor> = null;
	public function colorPick() {
		if (__cachedColor == null) {
			var imageBitmap:BitmapData = Assets.getBitmapData(__path, true, false);
			__cachedColor = imageBitmap.getMostPresentColor();
			imageBitmap.dispose();
		}

		if (colorWheel != null) {
			colorWheel.hue = __cachedColor.hue; 
			colorWheel.saturation = __cachedColor.saturation; 
			colorWheel.brightness = __cachedColor.brightness;
			colorWheel.updateWheel();
		}
	}
}