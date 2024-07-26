package funkin.backend.utils;

import flixel.util.FlxColor;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;

class DrawUtil {
	public static var line:FlxSprite = null;
	public static var dot:FlxSprite = null;

	public static inline function drawDot(x:Float, y:Float, ?scale:Float = 1) {
		if (dot == null) createDrawers();

		dot.setPosition(x, y);
		dot.scale.set(0.7/dot.cameras[0].zoom * scale, 0.7/dot.cameras[0].zoom * scale);
		dot.x -= dot.width / 2;
		dot.y -= dot.height / 2;
		dot.draw();
	}

	public static inline function drawLine(point1:FlxPoint, point2:FlxPoint, sizeModify:Float = 1, ?color:Null<FlxColor>) {
		if (line == null) createDrawers();

		var dx:Float = point2.x - point1.x;
		var dy:Float = point2.y - point1.y;

		var angle:Float = Math.atan2(dy, dx);
		var distance:Float = Math.sqrt(dx * dx + dy * dy);

		line.setPosition(point1.x, point1.y);
		line.angle = angle * FlxAngle.TO_DEG;
		line.origin.set(0, line.frameHeight / 2);
		line.scale.x = distance / line.frameWidth;
		line.scale.y = 0.20/line.cameras[0].zoom * sizeModify;
		line.y -= line.height / 2;
		if (color != null) line.color = color;
		line.draw();

		line.angle = 0;
		line.scale.x = line.scale.y = 1;
		line.updateHitbox();
	}

	public static inline function createDrawers() {
		dot = new FlxSprite().loadGraphic(Paths.image("editors/stage/selectionDot"), true, 32, 32);
		dot.antialiasing = true;
		dot.animation.add("default", [0], 0, false);
		dot.animation.add("hollow", [1], 0, false);
		dot.animation.play("default");
		dot.camera = FlxG.camera;
		dot.forceIsOnScreen = true;

		line = new FlxSprite().makeGraphic(30, 30, FlxColor.WHITE);
		line.camera = FlxG.camera;
		line.forceIsOnScreen = true;
	}

	public static function destroyDrawers() {
		dot.destroy(); line.destroy();
		dot = null; line = null;
	}
}