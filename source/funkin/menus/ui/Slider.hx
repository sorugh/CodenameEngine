package funkin.menus.ui;

import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;

class Slider extends FlxSprite {
	public var playSound:Bool = true;
	public var selected:Bool = false;
	public var value:Float;
	public var segments:Int;

	public var barWidth(default, set):Float;
	public var barHeight(default, null):Float;
	public var showSlider:Bool = true;

	public var barFramerate:Float = 24.0;
	var __animTime:Float = 0.0;
	var __curSegments:Int;

	public function new(?x:Float, ?y:Float, value:Float = 0.5, barWidth:Float = 500, segments:Int = 4) {
		super(x, y);
		this.value = value;
		this.barWidth = barWidth;
		this.segments = segments;

		frames = Paths.getFrames('menus/options/slider');
	}

	function playAnimOrDefault(a:String, d:String) {
		if (animation.exists(a)) animation.play(a);
		else animation.play(d);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		__animTime += elapsed;

		if (animation.curAnim == null) {
			animation.play(selected ? 'selected' : 'unselected');
			__curSegments = CoolUtil.minInt(segments, Math.floor(value * (segments + 1)));
		}
		else {
			switch (animation.curAnim.name) {
				case 'selected': if (!selected) playAnimOrDefault('deselect', 'unselected');
				case 'unselected': if (selected) playAnimOrDefault('selecting', 'selected');
				case 'selecting' | 'segment': if (animation.finished) animation.play('selected');
				case 'deselect': if (animation.finished) animation.play('unselected');
			}

			if (__curSegments != (__curSegments = CoolUtil.minInt(segments, Math.floor(value * (segments + 1)))) && playSound) {
				FlxG.sound.play(Paths.sound('menu/volume')).pitch = 0.75 + __curSegments * 0.5 / (segments + 1);
				if (animation.curAnim.name == 'selected' && animation.exists('segment')) animation.play('segment');
			}
		}
	}

	override function isSimpleRender(?camera:FlxCamera):Bool return false;
	override function drawComplex(camera:FlxCamera) {
		if (showSlider) {
			var xOff = frame.sourceSize.x * 0.5 - barWidth * value, yOff = (frame.sourceSize.y - barHeight) * 0.5;
			frameOffset.add(xOff, yOff);
			super.drawComplex(camera);
			frameOffset.subtract(xOff, yOff);
		}
	}

	function getBarAnim(type:Int, filled:Bool):FlxAnimation {
		var name = (type == 1 ? 'corner ' : (type == 2 ? 'segment ' : 'bar ')) + (filled ? 'filled0' : 'empty0');
		if (animation.exists(name)) return animation.getByName(name);

		animation.addByPrefix(name, name, barFramerate, true);
		return animation.getByName(name);
	}

	inline function sliderResetFrameSize() {
		frameWidth = Std.int(barWidth);
		frameHeight = Std.int(barHeight);
		_halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
		resetSize();
	}

	override function resetHelpers() {
		animation.addByPrefix('unselected', 'slider unselected0', 24, true);
		animation.addByPrefix('selected', 'slider selected0', 24, true);
		animation.addByPrefix('deselect', 'slider deselect0', 24, false);
		animation.addByPrefix('selecting', 'slider selecting0', 24, false);
		animation.addByPrefix('segment', 'slider segment0', 24, false);

		var anim;
		barHeight = 0;
		for (type in 0...3) {
			if ((anim = getBarAnim(type, false)) != null) barHeight = Math.max(barHeight, frames.frames[anim.frames[0]].sourceSize.y);
			if ((anim = getBarAnim(type, true)) != null) barHeight = Math.max(barHeight, frames.frames[anim.frames[0]].sourceSize.y);
		}

		sliderResetFrameSize();
		resetSizeFromFrame();
		centerOrigin();

		if (FlxG.renderBlit) {
			dirty = true;
			updateFramePixels();
		}
	}

	override function set_frame(v:FlxFrame):FlxFrame {
		super.set_frame(v);
		if (v != null) sliderResetFrameSize();
		return v;
	}

	function set_barWidth(v:Float):Float {
		origin.x = _halfSize.x = 0.5 * (frameWidth = Std.int(barWidth = v));
		return v;
	}
}