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

	public var labels:Map<UISprite, UIText> = [];

	public function new(x:Float, y:Float, animData:AnimData, parent:CharacterAnimsWindow) {
		this.anim = animData.name;
		this.data = animData;
		this.parent = parent;
		super(x,y, '${animData.name} (${animData.x}, ${animData.y})', function () {
			CharacterEditor.instance.playAnimation(this.anim);
		}, Std.int(500-16-32), 184);

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y-18, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		autoAlpha = autoFrames = autoFollow = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		field.fieldWidth = 0; framesOffset = 9;
		field.visible = false;

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
	}

	public override function update(elapsed:Float) {
		field.follow(this, 20, 12);

		animationDisplayBG.follow(this, 16, 12+18+11);
		nameTextBox.follow(this, 14+128+16, 12+18+8+14);
		animTextBox.follow(this, 14+128+12+116+20, 12+18+8+14);

		positionXStepper.follow(this, 14+128+16, 12+18+8+10+24+26);
		positionYStepper.follow(this, 14+128+16+64-32+28, 12+18+8+10+24+26);
		XYComma.follow(positionXStepper, 64-24, 6);

		fpsStepper.follow(this, 14+128+16+64-32+28+64-22+20, 12+18+8+10+24+26);
		loopedCheckbox.follow(this, 14+128+16+64-32+28+64-22+20+52-22+18+8, 12+18+8+10+24+32);

		indicesTextBox.follow(this, 14+128+16, 12+18+8+10+24+26+24+22);

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
				12+18+11+(128/2)-((parent.displayWindowSprite.frame.sourceSize.y*displayData.scale)/2)
			);
			parent.displayWindowSprite.draw();
		}
	}
}