package funkin.editors.charter;

import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.editors.extra.PropertyButton;

using StringTools;

class CharterMetaDataScreen extends UISubstateWindow {
	public var metadata:ChartMetaData;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var stepsPerBeatStepper :UINumericStepper;
	public var customPropertiesButtonList:UIButtonList<PropertyButton>;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:FlxSprite;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficulitesTextBox:UITextBox;

	public function new(metadata:ChartMetaData) {
		super();
		this.metadata = metadata;
	}

	inline function translate(id:String):String
		return TU.translate("charterMetaDataScreen." + id);

	public override function create() {
		winTitle = translate("title");
		winWidth = 1056;
		winHeight = 520;

		super.create();

		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translate("songData"), 28));

		songNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.name);
		add(songNameTextBox);
		addLabelOn(songNameTextBox, translate("songName"));

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, metadata.bpm, 1, 2, 1, null, 90);
		add(bpmStepper);
		addLabelOn(bpmStepper, translate("bpm"));

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, metadata.beatsPerMeasure, 1, 0, 1, null, 54);
		add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, translate("timeSignature"));

		add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		stepsPerBeatStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, metadata.stepsPerBeat, 1, 0, 1, null, 54);
		add(stepsPerBeatStepper);

		add(title = new UIText(songNameTextBox.x, songNameTextBox.y + 10 + 46, 0, translate("menusData"), 28));

		displayNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.displayName);
		add(displayNameTextBox);
		addLabelOn(displayNameTextBox, translate("displayName"));

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, metadata.icon, 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		add(iconTextBox);
		addLabelOn(iconTextBox, translate("icon"));

		updateIcon(metadata.icon);

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, translate("opponentMode"), metadata.opponentModeAllowed);
		add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, translate("modesAllowed"));

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, translate("coopAllowed"), metadata.coopAllowed);
		add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, metadata.parsedColor);
		add(colorWheel);
		addLabelOn(colorWheel, translate("color"));

		difficulitesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, metadata.difficulties.join(", "));
		add(difficulitesTextBox);
		addLabelOn(difficulitesTextBox, translate("difficulties"));

		customPropertiesButtonList = new UIButtonList<PropertyButton>(stepsPerBeatStepper.x + 80 + 26 + 105, songNameTextBox.y, 290, 316, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}
		for (val in Reflect.fields(metadata.customValues))
			customPropertiesButtonList.add(new PropertyButton(val, Reflect.field(metadata.customValues, val), customPropertiesButtonList));
		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, translate("customValues"));

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, TU.translate("editor.saveClose"), function() {
			saveMeta();
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.close"), function() {
			close();
		}, 125);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		//closeButton.y -= closeButton.bHeight;
		add(closeButton);
		add(saveButton);
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) add(iconSprite = new FlxSprite());

		if (iconSprite.animation.exists(icon)) return;
		@:privateAccess iconSprite.animation.clearAnimations();

		var path:String = Paths.image('icons/$icon');
		if (!Assets.exists(path)) path = Paths.image('icons/' + Flags.DEFAULT_HEALTH_ICON);

		iconSprite.loadGraphic(path, true, 150, 150);
		iconSprite.animation.add(icon, [0], 0, false);
		iconSprite.antialiasing = true;
		iconSprite.animation.play(icon);

		iconSprite.scale.set(0.5, 0.5);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + 150 + 8, (iconTextBox.y + 16) - (iconSprite.height/2));
	}

	public function saveMeta() {
		for (stepper in [bpmStepper, beatsPerMeasureStepper, stepsPerBeatStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var customVals = {};
		for (vals in customPropertiesButtonList.buttons.members) {
			Reflect.setProperty(customVals, vals.propertyText.label.text, vals.valueText.label.text);
		}

		PlayState.SONG.meta = {
			name: songNameTextBox.label.text,
			bpm: bpmStepper.value,
			beatsPerMeasure: Std.int(beatsPerMeasureStepper.value),
			stepsPerBeat: Std.int(stepsPerBeatStepper.value),
			displayName: displayNameTextBox.label.text,
			icon: iconTextBox.label.text,
			color: colorWheel.curColorString,
			parsedColor: colorWheel.curColor,
			opponentModeAllowed: opponentModeCheckbox.checked,
			coopAllowed: coopAllowedCheckbox.checked,
			difficulties: [for (diff in difficulitesTextBox.label.text.split(",")) diff.trim()],
			customValues: customVals,
		};

		Charter.instance.updateBPMEvents();
	}
}