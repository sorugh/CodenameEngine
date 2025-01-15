package funkin.editors.extra;

import openfl.display.Graphics;
import flixel.util.FlxSpriteUtil;

class DrawAxis extends FlxObject {
	public override function draw() {
		super.draw();

		/*
		for (camera in cameras) {
			var gfx:Graphics = FlxG.renderBlit ? {
				FlxSpriteUtil.flashGfx.clear();
				FlxSpriteUtil.flashGfx;
			} :  camera.debugLayer.graphics;

			// Stole these colors directly from godot
			gfx.lineStyle(2, 0xFF76BC02, 1);

			gfx.moveTo(-camera.scroll.x, camera.viewMarginTop);
			gfx.lineTo(-camera.scroll.x, camera.viewMarginBottom);

			gfx.lineStyle(2, 0xFFD72C47, 1);

			gfx.moveTo(camera.viewMarginLeft, -camera.scroll.y);
			gfx.lineTo(camera.viewMarginRight, -camera.scroll.y);

			if (FlxG.renderBlit)
				camera.buffer.draw(FlxSpriteUtil.flashGfxSprite);
		}
		*/
	}
}