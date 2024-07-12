package funkin.backend.system.framerate;

import haxe.ds.Vector;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

inline final FRAME_TIME_HISTORY = 20;

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;

	public var fpsHistoryIndex:Int = 0;
	public var fpsHistory:Vector<Float>;

	public function new() {
		super();

		fpsHistory = new Vector(FRAME_TIME_HISTORY);
		// Initialize to 60 FPS, so that the initial estimation until we get enough data is always reasonable.
		for(i in 0...FRAME_TIME_HISTORY) {
			fpsHistory[i] = 1000.0 / 60.0;
		}

		fpsNum = new TextField();
		fpsLabel = new TextField();

		for(label in [fpsNum, fpsLabel]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
			addChild(label);
		}
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		// todo use gpu time
		fpsHistory[fpsHistoryIndex] = FlxG.elapsed * 1000;
		fpsHistoryIndex = (fpsHistoryIndex + 1) % FRAME_TIME_HISTORY;

		// Calculate average CPU time.
		// Code based on Godot's FPS counter.
		var cpuTime = 0.0;
		for(i in 0...FRAME_TIME_HISTORY) {
			cpuTime += fpsHistory[i];
		}
		cpuTime /= FRAME_TIME_HISTORY;
		cpuTime = Math.max(0.01, cpuTime); // Prevent unrealistically low values.

		fpsNum.text = Std.string(Math.floor(1000.0 / cpuTime));
		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height;
	}
}