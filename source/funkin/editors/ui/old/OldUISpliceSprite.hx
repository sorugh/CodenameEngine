package funkin.editors.ui.old;

import flixel.graphics.frames.FlxFrame;

class OldUISliceSprite extends UISprite {
	public var bWidth:Int = 120;
	public var bHeight:Int = 20;
	public var framesOffset(default, set):Int = 0;

	public var incorporeal:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getFrames(path);
		resize(w, h);
		calculateFrames();
	}

	public override function updateButton() {
		if (incorporeal) return;
		__rect.x = x;
		__rect.y = y;
		__rect.width = bWidth;
		__rect.height = bHeight;
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public function resize(w:Int, h:Int) {
		bWidth = w;
		bHeight = h;
	}

	public var topAlpha:Null<Float> = null;
	public var middleAlpha:Null<Float> = null;
	public var bottomAlpha:Null<Float> = null;

	public var drawTop:Bool = true;
	public var drawMiddle:Bool = true;
	public var drawBottom:Bool = true;

	var topleft:FlxFrame = null;
	var top:FlxFrame = null;
	var topright:FlxFrame = null;
	var middleleft:FlxFrame = null;
	var middle:FlxFrame = null;
	var middleright:FlxFrame = null;
	var bottomleft:FlxFrame = null;
	var bottom:FlxFrame = null;
	var bottomright:FlxFrame = null;

	public var topHeight:Int = 0;
	public var bottomHeight:Int = 0;
	public var leftWidth:Int = 0;
	public var rightWidth:Int = 0;

	override function set_frames(val) {
		super.set_frames(val);
		calculateFrames();
		return val;
	}

	function set_framesOffset(value:Int) {
		if(value != framesOffset) {
			framesOffset = value;
			calculateFrames();
		}
		return value;
	}

	function calculateFrames() {
		if(frames == null) return;
		topleft = frames.frames[framesOffset];
		top = frames.frames[framesOffset + 1];
		topright = frames.frames[framesOffset + 2];
		middleleft = frames.frames[framesOffset + 3];
		middle = frames.frames[framesOffset + 4];
		middleright = frames.frames[framesOffset + 5];
		bottomleft = frames.frames[framesOffset + 6];
		bottom = frames.frames[framesOffset + 7];
		bottomright = frames.frames[framesOffset + 8];

		leftWidth = Std.int(MathUtil.maxSmart(topleft.frame.width, middleleft.frame.width, bottomleft.frame.width));
		rightWidth = Std.int(MathUtil.maxSmart(topright.frame.width, middleright.frame.width, bottomright.frame.width));
		topHeight = Std.int(MathUtil.maxSmart(topleft.frame.height, top.frame.height, topright.frame.height));
		bottomHeight = Std.int(MathUtil.maxSmart(topleft.frame.height, top.frame.height, topright.frame.height));
	}

	public override function draw() @:privateAccess {
		var lastPixelPerfect:Bool = cameras[0] != null ? cameras[0].pixelPerfectRender : false;
		if (cameras[0] != null) cameras[0].pixelPerfectRender = false;
		
		var x:Float = this.x;
		var y:Float = this.y;

		if (visible && !(bWidth == 0 || bHeight == 0)) {
			var oldAlpha = alpha;
			// TOP
			if (drawTop) {
				// TOP LEFT
				if(topAlpha != null) alpha = topAlpha;
				frame = topleft;
				setPosition(x, y);
				__setSize(
					topleft.frame.width * Math.min(bWidth/(topleft.frame.width*2), 1),
					topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)
				);
				super.drawSuper();

				// TOP
				if (bWidth > topleft.frame.width + topright.frame.width) {
					frame = top;
					setPosition(x + topleft.frame.width, y);
					__setSize(bWidth - topleft.frame.width - topright.frame.width, top.frame.height * Math.min(bHeight/(top.frame.height*2), 1));
					super.drawSuper();
				}

				// TOP RIGHT
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y);
				frame = topright;
				__setSize(
					topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1),
					topright.frame.height * Math.min(bHeight/(topright.frame.height*2), 1)
				);
				super.drawSuper();
			}

			// MIDDLE
			if (drawMiddle && bHeight > top.frame.height + bottom.frame.height) {
				if(middleAlpha != null) alpha = middleAlpha;
				var middleHeight:Float = bHeight - (topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)) -
				bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);

				// MIDDLE LEFT
				frame = middleleft;
				setPosition(x, y + top.frame.height);
				__setSize(middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1), middleHeight);
				super.drawSuper();

				if (bWidth > (middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1)) + middleright.frame.width) {
					// MIDDLE
					frame = middle;
					setPosition(x + topleft.frame.width, y + top.frame.height);
					__setSize(bWidth - middleleft.frame.width - middleright.frame.width, middleHeight);
					super.drawSuper();
				}

				// MIDDLE RIGHT
				frame = middleright;
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y + top.frame.height);
				__setSize(middleright.frame.width * Math.min(bWidth/(middleright.frame.width*2), 1), middleHeight);
				super.drawSuper();
			}

			// BOTTOM
			if (drawBottom) {
				if(bottomAlpha != null) alpha = bottomAlpha;
				// BOTTOM LEFT
				frame = bottomleft;
				setPosition(x, y + bHeight - (bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)));
				__setSize(
					bottomleft.frame.width * Math.min(bWidth/(bottomleft.frame.width*2), 1),
					bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)
				);
				super.drawSuper();

				if (bWidth > bottomleft.frame.width + bottomright.frame.width) {
					// BOTTOM
					frame = bottom;
					setPosition(x + bottomleft.frame.width, y + bHeight - (bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1)));
					__setSize(bWidth - bottomleft.frame.width - bottomright.frame.width, bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1));
					super.drawSuper();
				}

				// BOTTOM RIGHT
				frame = bottomright;
				setPosition(
					x + bWidth - (bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1)),
					y + bHeight - (bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1))
				);
				__setSize(
					bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1),
					bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1)
				);
				super.drawSuper();

			}
			alpha = oldAlpha;
		}
		if (cameras[0] != null) cameras[0].pixelPerfectRender = lastPixelPerfect;

		setPosition(x, y);
		super.drawMembers();
	}

	private function __setSize(Width:Float, Height:Float) {
		var newScaleX:Float = Width / frameWidth;
		var newScaleY:Float = Height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (Width <= 0)
			scale.x = newScaleY;
		else if (Height <= 0)
			scale.y = newScaleX;

		updateHitbox();
	}
}