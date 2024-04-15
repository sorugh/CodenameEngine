package funkin.editors.character;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.util.FlxColor;

// DONT DELETE I MIGHT USE LATER -lunar
class CharacterIconDisplay extends UISprite {
	public var healthBarBG:FlxSprite;
	public var healthBar:FlxSprite;
	public var textProperties:UIText;

	public function new(x:Float, y:Float, name:String, icon:String, color:Null<FlxColor>, barWidth:Int) {
		super(x, y);

		var path:String = Paths.image('icons/${icon}');
		if (!Assets.exists(path)) path = Paths.image('icons/face');

		var imageBitmap:BitmapData = Assets.getBitmapData(path, true, false);
		var iconBitmap:BitmapData = new BitmapData(150, 150, true, 0x00000000);

		iconBitmap.copyPixels(imageBitmap, new Rectangle(0, 0, 150, 150), new Point(0,0));

		loadGraphic(iconBitmap.cropBitmap());
		scale.x = scale.y = 40/pixels.height;
		updateHitbox();

		antialiasing = true;

		healthBarBG = new FlxSprite(x+(width/2), y+(height*(2.25/4))+2).makeSolid(barWidth-Std.int(width), 10, 0xFF000000);
		healthBar = new FlxSprite(healthBarBG.x+2, healthBarBG.y+2).makeSolid(
			Std.int(healthBarBG.width-4), Std.int(healthBarBG.height-4), 
			color != null ? color : 0xFFFFFFFF
		);

		textProperties = new UIText(x+width+2, healthBarBG.y-14, 0, 'Character Properties of ${name}...', 13);

		members.push(healthBarBG);
		members.push(healthBar);
		members.push(textProperties);
	}

	public override function draw() {
		drawMembers();
		drawSuper();
	}
}