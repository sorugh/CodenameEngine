package funkin.editors.ui;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class UISliceSprite extends UISprite {
	public var bWidth(default, set):Int = 120;
	public var bHeight(default, set):Int = 20;
	public var framesOffset(default, set):Int = 0;

	public var incorporeal:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getFrames(path);
		resize(w, h);

		calculateFrames();
		__genMesh();
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
		__framesDirty = true;
		__meshDirty = true;
		return val;
	}

	function set_framesOffset(value:Int) {
		if(value != framesOffset) {
			framesOffset = value;
			__framesDirty = true;
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

		leftWidth = Std.int(Math.max(topleft.frame.width, Math.max(middleleft.frame.width, bottomleft.frame.width)));
		rightWidth = Std.int(Math.max(topright.frame.width, Math.max(middleright.frame.width, bottomright.frame.width)));
		topHeight = Std.int(Math.max(topleft.frame.height, Math.max(top.frame.height, topright.frame.height)));
		bottomHeight = Std.int(Math.max(topleft.frame.height, Math.max(top.frame.height, topright.frame.height)));

		__genUVs();
	}

	public override function draw() @:privateAccess {
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY) {
			if (__framesDirty) calculateFrames();
			if (__meshDirty) __genMesh();
	
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;
	
				getScreenPosition(_point, camera).subtractPoint(offset);
				
				#if !flash
				camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, false, antialiasing, colorTransform, shader);
				#else
				camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, false, antialiasing);
				#end
	
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
		}

		super.drawMembers();
		__lastDrawCameras = cameras.copy();
	}

	var vertices:DrawData<Float> = new DrawData<Float>();
	var indices:DrawData<Int> = new DrawData<Int>();
	var uvtData:DrawData<Float> = new DrawData<Float>();
	var colors:DrawData<Int> = new DrawData<Int>();

	var __framesDirty:Bool = false;
	var __meshDirty:Bool = false;

	public function set_bWidth(value:Int):Int {
		if(value != bWidth) {
			bWidth = value;
			__meshDirty = true;
		}
		return value;
	}

	public function set_bHeight(value:Int):Int {
		if(value != bHeight) {
			bHeight = value;
			__meshDirty = true;
		}
		return value;
	}

	private inline function __genMesh() {
		indices.length = 0;
		vertices.length = 0;

		// TOP PART
		if (drawTop) {
			// TOP LEFT
			var topLeftWidth:Float = topleft.frame.width * Math.min(bWidth / (topleft.frame.width * 2), 1);
			var topLeftHeight:Float = topleft.frame.height * Math.min(bHeight / (topleft.frame.height * 2), 1);
			__genSliceTri(
				0, 0, 
				topLeftWidth, topLeftHeight
			);

			// TOP MIDDLE
			if (bWidth > topleft.frame.width + topright.frame.width) {
				var topWidth:Float = bWidth - topleft.frame.width - topright.frame.width;
				var topHeight:Float = top.frame.height * Math.min(bHeight / (top.frame.height * 2), 1);
				__genSliceTri(
					topLeftWidth, 0, 
					topWidth, topHeight
				);
			}

			// TOP RIGHT
			var topRightWidth:Float = topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1);
			var topRightHeight:Float = topright.frame.height * Math.min(bHeight/(topright.frame.height*2), 1);
			__genSliceTri(
				bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), 0,
				topRightWidth, topRightHeight
			);
		}

		if (drawMiddle && bHeight > top.frame.height + bottom.frame.height) {
			var middleHeight:Float = bHeight - (topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)) -
			bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);

			// MIDDLE LEFT
			var middleLeftWidth:Float = middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1);
			__genSliceTri(
				0, top.frame.height,
				middleLeftWidth, middleHeight
			);

			// MIDDLE
			if (bWidth > (middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1)) + middleright.frame.width) {
				var middleWidth:Float = bWidth - middleleft.frame.width - middleright.frame.width;
				__genSliceTri(
					topleft.frame.width, top.frame.height,
					middleWidth, middleHeight
				);
			}

			// MIDDLE RIGHT
			var middleRightWidth:Float = middleright.frame.width * Math.min(bWidth/(middleright.frame.width*2), 1);
			__genSliceTri(
				bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), top.frame.height,
				middleRightWidth, middleHeight
			);
		}

		// BOTTOM
		if (drawBottom) {
			// BOTTOM LEFT
			var bottomLeftWidth:Float = bottomleft.frame.width * Math.min(bWidth/(bottomleft.frame.width*2), 1);
			var bottomLeftHeight:Float = bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);
			__genSliceTri(
				0, bHeight - (bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)),
				bottomLeftWidth, bottomLeftHeight
			);

			// BOTTOM MIDDLE
			if (bWidth > bottomleft.frame.width + bottomright.frame.width) {
				var bottomMiddleWidth:Float = bWidth - bottomleft.frame.width - bottomright.frame.width;
				var bottomMiddleHeight:Float = bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1);
				__genSliceTri(
					bottomleft.frame.width, bHeight - (bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1)),
					bottomMiddleWidth, bottomMiddleHeight
				);
			}

			// BOTTOM RIGHT
			var bottomRightWidth:Float = bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1);
			var bottomRightHeight:Float = bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1);
			__genSliceTri(
				bWidth - (bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1)),
				bHeight - (bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1)),
				bottomRightWidth, bottomRightHeight
			);
		}

		__meshDirty = false;
	}

	private inline function __genUVs() {
		uvtData.length = 0;

		__genSliceUV(topleft);
		__genSliceUV(top);
		__genSliceUV(topright);
		__genSliceUV(middleleft);
		__genSliceUV(middle);
		__genSliceUV(middleright);
		__genSliceUV(bottomleft);
		__genSliceUV(bottom);
		__genSliceUV(bottomright);

		__framesDirty = false;
	} 

	private inline function __genSliceTri(x:Float, y:Float, width:Float, height:Float) {
		var indicesOffset:Int = Std.int(vertices.length / 2);

		indices.push(indicesOffset);
		indices.push(indicesOffset + 1);
		indices.push(indicesOffset + 2);
		indices.push(indicesOffset);
		indices.push(indicesOffset + 2);
		indices.push(indicesOffset + 3);

		vertices.push(x);
		vertices.push(y);
		vertices.push(x + width);
		vertices.push(y);
		vertices.push(x + width);
		vertices.push(y + height);
		vertices.push(x);
		vertices.push(y + height);
	}

	private inline function __genSliceUV(frame:FlxFrame) {
		uvtData.push(frame.uv.x);
		uvtData.push(frame.uv.y);
		uvtData.push(frame.uv.width);
		uvtData.push(frame.uv.y);
		uvtData.push(frame.uv.width);
		uvtData.push(frame.uv.height);
		uvtData.push(frame.uv.x);
		uvtData.push(frame.uv.height);
	}

	@:access(flixel.FlxCamera)
	override function getBoundingBox(camera:FlxCamera):FlxRect {
		getScreenPosition(_point, camera);

		_rect.set(_point.x, _point.y, bWidth, bHeight);
		_rect = camera.transformRect(_rect);

		// if (isPixelPerfectRender(camera))
		// 	  _rect.floor();

		return _rect;
	}

	override public function destroy():Void
	{
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		super.destroy();
	}
}