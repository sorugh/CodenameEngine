package funkin.editors.character;

import openfl.geom.Rectangle;
import funkin.backend.utils.XMLUtil.AnimData;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class CharacterAnimButton extends UIButton {
	public var anim:String = null;
	public var data:AnimData = null;
	public var parent:CharacterAnimsWindow;

	public var animationDisplayBG:UISliceSprite;
	public var nameTextBox:UITextBox;
	public var animTextBox:UITextBox;
	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var fpsStepper:UINumericStepper;
	public var loopedCheckbox:UICheckbox;
	public var indicesTextBox:UITextBox;
	public var XYComma:UIText;

	public var editButton:UIButton;
	public var editIcon:FlxSprite;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;
	public var ghostButton:UIButton;
	public var ghostIcon:FlxSprite;

	public var playIcon:FlxSprite;

	public var labels:Map<UISprite, UIText> = [];

	public function new(x:Float, y:Float, animData:AnimData, parent:CharacterAnimsWindow) {
		this.anim = animData.name;
		this.data = animData;
		this.parent = parent;
		super(x,y, '${animData.name} (${animData.x}, ${animData.y})', function () {
			CharacterEditor.instance.playAnimation(this.anim);
		}, Std.int(500-16-32), 208);

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y-18, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		autoAlpha = autoFrames = autoFollow = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		field.fieldWidth = 0; framesOffset = 9;
		field.size = 14;
		// field.visible = false;

		animationDisplayBG = new UISliceSprite(x+12, y+12+18+12, 128, 128, 'editors/ui/inputbox-small');
		members.push(animationDisplayBG);

		nameTextBox = new UITextBox(animationDisplayBG.x+126+16, animationDisplayBG.y, animData.name, 116, 22, false, true);
		members.push(nameTextBox);
		addLabelOn(nameTextBox, "Name", 12);

		animTextBox = new UITextBox(nameTextBox.x + 100 + 12, nameTextBox.y, animData.anim, 146, 22, false, true);
		members.push(animTextBox);
		addLabelOn(animTextBox, "Animation", 12);

		positionXStepper = new UINumericStepper(animTextBox.x, animTextBox.y+32+18, animData.x, 0.001, 2, null, null, 64, 22, true);
		members.push(positionXStepper);
		addLabelOn(positionXStepper, "Position (X,Y)", 12);

		members.push(XYComma = new UIText(positionXStepper.x+104-32+0, positionXStepper.y + 9, 0, ",", 18));

		positionYStepper = new UINumericStepper(positionXStepper.x+104-32+26, positionXStepper.y, animData.y, 0.001, 2, null, null, 64, 22, true);
		members.push(positionYStepper);

		fpsStepper = new UINumericStepper(animTextBox.x + 200 + 26, animTextBox.y, 0, 0.1, 2, animData.fps, 100, 52, 22, true);
		members.push(fpsStepper);
		addLabelOn(fpsStepper, "FPS", 12);

		loopedCheckbox = new UICheckbox(fpsStepper.x + 82 - 32 + 26, fpsStepper.y, "Looping?", animData.loop, 0, true);
		members.push(loopedCheckbox);
		addLabelOn(loopedCheckbox, "Looped", 12);

		loopedCheckbox.x += 8; loopedCheckbox.y += 6;

		indicesTextBox = new UITextBox(nameTextBox.x, nameTextBox.y, animData.indices.getDefault([]).join(","), 278, 22, false, true);
		members.push(indicesTextBox);
		addLabelOn(indicesTextBox, "Indices (frames)", 12);

		playIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image("editors/character/play"));
		// playIcon.color = 0xFFD60E0E;
		playIcon.antialiasing = false;
		members.push(playIcon);

		deleteButton = new UIButton(0, 0, "", null, 28*2,24);
		deleteButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		deleteButton.color = 0xFFAC3D3D;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image("editors/deleter"));
		deleteIcon.color = 0xFFD60E0E;
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		editButton = new UIButton(0, 0, "", null, 28,24);
		editButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		editButton.color = 0xFFAFAA12;
		members.push(editButton);

		editIcon = new FlxSprite().loadGraphic(Paths.image('editors/character/edit-button'));
		editIcon.color = 0xFFE8E801;
		editIcon.antialiasing = false;
		members.push(editIcon);

		ghostButton = new UIButton(0, 0, "", null, 28, 24);
		ghostButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		ghostButton.color = 0xFFADADAD;
		ghostButton.alpha = 0.5;
		members.push(ghostButton);

		ghostIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image('editors/character/ghost'), true, 16, 12);
		ghostIcon.animation.add("alive", [0]);
		ghostIcon.animation.add("dead", [1]);
		ghostIcon.animation.play("dead");
		ghostIcon.antialiasing = false;
		ghostIcon.updateHitbox();
		members.push(ghostIcon);
	}

	public override function update(elapsed:Float) {
		playIcon.follow(this, 22, 19);
		field.follow(this, 22+15+8, 16);

		deleteButton.follow(this, (500-16-32)-16-(28*2), 14);
		deleteIcon.follow(deleteButton, (deleteButton.bWidth/2)-6.5, (deleteButton.bHeight/2)-6);

		editButton.follow(this, (500-16-32)-16-(28*2)-12-28, 14);
		editIcon.follow(editButton, (editButton.bWidth/2)-8,  (editButton.bHeight/2)-6);

		ghostButton.follow(this, (500-16-32)-16-(28*2)-12-28-12-28, 14);
		ghostIcon.follow(ghostButton, (ghostButton.bWidth/2)-8, (ghostButton.bHeight/2)-6);

		animationDisplayBG.follow(this, 16, 8+32+8+2+11);
		nameTextBox.follow(this, 14+128+16, 8+32+8+2+8+14);
		animTextBox.follow(this, 14+128+12+116+20, 8+32+8+2+8+14);

		positionXStepper.follow(this, 14+128+16, 8+32+8+2+8+10+24+26);
		positionYStepper.follow(this, 14+128+16+64-32+28, 8+32+8+2+8+10+24+26);
		XYComma.follow(positionXStepper, 64-24, 6);

		fpsStepper.follow(this, 14+128+16+64-32+28+64-22+20, 8+32+8+2+8+10+24+26);
		loopedCheckbox.follow(this, 14+128+16+64-32+28+64-22+20+52-22+18+8, 8+32+8+2+8+10+24+32);

		indicesTextBox.follow(this, 14+128+16, 8+32+8+2+8+10+24+26+24+22);

		for (ui => text in labels)
			text.follow(ui, -(2+(ui is UICheckbox?12:0)), -(18+(ui is UICheckbox?6:0)));

		super.update(elapsed);
	}

	public override function draw() {
		super.draw();

		if (parent.displayAnimsFramesList.exists(anim)) {
			var displayData:{frame:Int, scale:Float, animBounds:Rectangle} = parent.displayAnimsFramesList.get(anim);
			parent.displayWindowSprite.frame = parent.displayWindowSprite.frames.frames[displayData.frame];

			parent.displayWindowSprite.scale.x = parent.displayWindowSprite.scale.y = displayData.scale;
			parent.displayWindowSprite.updateHitbox();

			// parent.displayWindowSprite.origin.set();
			
			parent.displayWindowSprite.follow(
				this, 16+(128/2)-((parent.displayWindowSprite.frame.sourceSize.x*displayData.scale)/2), 
				8+32+8+2+11+(128/2)-((parent.displayWindowSprite.frame.sourceSize.y*displayData.scale)/2)
			);
			parent.displayWindowSprite.draw();
		}
	}
}