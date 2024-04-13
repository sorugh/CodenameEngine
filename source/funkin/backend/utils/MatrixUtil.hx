package funkin.backend.utils;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;

class MatrixUtil {
	public static function getMatrixPosition(sprite:FlxSprite, points:OneOfTwo<FlxPoint, Array<FlxPoint>>, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1):Array<FlxPoint>
	{
		//if(_width == -1) _width = sprite.width;
		//if(_height == -1) _height = sprite.height;
		if(camera == null) camera = sprite.camera;
		if(points is FlxBasePoint) points = [points];
		var nc = funkin.backend.system.NothingCamera.instance;
		nc.scroll.set(camera.scroll.x, camera.scroll.y);
		//nc.zoom = camera.zoom; // might not be needed
		nc.pixelPerfectRender = camera.pixelPerfectRender;
		@:privateAccess sprite.drawComplex(nc);

		var points:Array<FlxPoint> = cast points;
		@:privateAccess for(point in points) {
			var x = sprite._matrix.__transformX(point.x * _width, point.y * _height);
			var y = sprite._matrix.__transformY(point.x * _width, point.y * _height);

			// reset to ingame coords
			x += camera.scroll.x;
			y += camera.scroll.y;

			point.set(x, y);
		}
		return points;
	}
}