package funkin.backend.utils;

import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.system.FakeCamera;
import funkin.backend.system.FakeCamera.FakeCallCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

interface IPrePostDraw {
	public function preDraw():Void;
	public function postDraw():Void;
}

@:access(flixel.FlxCamera)
@:access(flixel.FlxSprite)
final class MatrixUtil {
	public static function getMatrixPosition(sprite:FlxSprite, points:OneOfTwo<FlxPoint, Array<FlxPoint>>, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1):Array<FlxPoint>
	{
		//if(_width == -1) _width = sprite.width;
		//if(_height == -1) _height = sprite.height;
		if(camera == null) camera = sprite.camera;
		if(points is FlxBasePoint) points = [points];
		var isFunkinSprite = sprite is FunkinSprite;
		var funkinSprite:FunkinSprite = null;
		if(isFunkinSprite) funkinSprite = cast sprite;
		var isAnimateAtlas = isFunkinSprite && funkinSprite.animateAtlas != null;

		var nc:FakeCamera = isAnimateAtlas ? FakeCallCamera.instance : FakeCamera.instance;
		nc.zoom = camera.zoom;
		nc.scroll.set(camera.scroll.x, camera.scroll.y);
		nc.pixelPerfectRender = camera.pixelPerfectRender;

		if(isAnimateAtlas) {
			var nc = FakeCallCamera.instance;
			var sprite = funkinSprite;
			var oldOnDraw = nc.onDraw;
			nc.onDraw = function(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader, smooth:Bool = false, ?shader:FlxShader) {
				// pixels is null
				
			}
			var cameras = sprite.animateAtlas._cameras;
			sprite.animateAtlas._cameras = [nc];
			if(sprite is IPrePostDraw) {
				var postDraw = cast(sprite, IPrePostDraw);
				postDraw.preDraw();
				@:privateAccess sprite.draw();
				postDraw.postDraw();
			} else {
				@:privateAccess sprite.draw();
			}
			sprite.animateAtlas._cameras = cameras;
			nc.onDraw = oldOnDraw;
		} else {
			if(sprite is IPrePostDraw) {
				var postDraw = cast(sprite, IPrePostDraw);
				postDraw.preDraw();
				@:privateAccess sprite.drawComplex(nc);
				postDraw.postDraw();
			} else {
				@:privateAccess sprite.drawComplex(nc);
			}
		}

		var points:Array<FlxPoint> = cast points;
		transformPoints(sprite, points, sprite._matrix, camera, _width, _height);
		return points;
	}

	/**
	 * Warning: modifies the points in the array
	**/
	public static function transformPoints(sprite:FlxSprite, points:Array<FlxPoint>, matrix:FlxMatrix, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1):Array<FlxPoint> {
		var isFunkinSprite = sprite is FunkinSprite;
		var funkinSprite:FunkinSprite = null;
		if(isFunkinSprite) funkinSprite = cast sprite;

		for(point in points) {
			var x = matrix.__transformX(point.x * _width, point.y * _height);
			var y = matrix.__transformY(point.x * _width, point.y * _height);

			// reset to ingame coords
			x += camera.scroll.x;
			y += camera.scroll.y;

			if(isFunkinSprite) {
				var ratio = 1 - FlxMath.lerp(1 / camera.zoom, 1, funkinSprite.zoomFactor);
				x += camera.width / 2 * ratio;
				y += camera.height / 2 * ratio;
			}
			point.set(x, y);
		}
		return points;
	}
}