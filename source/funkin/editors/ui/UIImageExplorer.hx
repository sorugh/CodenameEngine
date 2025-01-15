package funkin.editors.ui;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.display.BitmapData;

using StringTools;
using funkin.backend.utils.BitmapUtil;

class UIImageExplorer extends UIFileExplorer {
	public function new(x:Float, y:Float, ?w:Int, ?h:Int, ?onFile:(String, Bytes)->Void) {
		super(x, y, w, h, "png, jpg", function (filePath, file) {
			if (filePath != null && file != null) uploadImage(filePath, file);
			if (onFile != null) onFile(filePath, file);
		});

		deleteButton.bWidth = 26;
		deleteButton.bHeight = 26;
	}

	public var fileText:UIText;

	public function uploadImage(filePath:String, file:Bytes) {
		var imagePath:Dynamic = Path.normalize(filePath);

		var dataPathExt:String = CoolUtil.imageHasFrameData(imagePath);
		var animationList:Array<String> = [];

		if (dataPathExt != null) 
			animationList = CoolUtil.getAnimsListFromFrames(CoolUtil.loadFramesFromData(File.getContent(Path.withExtension(imagePath, dataPathExt)), dataPathExt), dataPathExt);

		uiElement = new FlxSprite().loadGraphic(BitmapData.fromBytes(file).crop());

		var imageScale:Float = 1;
		if (uiElement.width < 300 || uiElement.height < 200)
			imageScale = Math.max(300/uiElement.width, 200/uiElement.height);
		else if (uiElement.width > 700 || uiElement.height > 500)
			imageScale = Math.min(700/uiElement.width, 500/uiElement.height);

		uiElement.scale.set(imageScale, imageScale);
		uiElement.updateHitbox();

		bWidth = Std.int(uiElement.width)+32; bHeight = Std.int(uiElement.height)+32+deleteButton.bHeight+4;
		uiElement.x = x+16; uiElement.y = y+16+deleteButton.bHeight+4;

		uiElement.antialiasing = true;
		members.push(uiElement);

		imagePath = new Path(imagePath);

		fileText = new UIText(x+20, y+16, bWidth-20-deleteButton.bWidth-16, '${imagePath.file}.${imagePath.ext} (${CoolUtil.getSizeString(file.length)}, ${animationList.length} Animations Found)');
		if (animationList.length <= 0) fileText.applyMarkup(
			'${imagePath.file}.${imagePath.ext} (${CoolUtil.getSizeString(file.length)}, #NO Animations Found#)',
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "#")]);
		members.push(fileText);

		deleteButton.x = x + bWidth - deleteButton.bWidth - 16;
		deleteButton.y = y + 12;

		deleteIcon.x = deleteButton.x + deleteButton.bWidth/2 - 8;
		deleteIcon.y = deleteButton.y + deleteButton.bHeight/2 - 8;

		/*
		var normalFilePath:String = Path.normalize(filePath);
		var gamePath:String = Path.normalize(Sys.getCwd());

		if (normalFilePath.contains(gamePath))
			normalFilePath = normalFilePath.replace(gamePath, ".");
		*/
	}

	public override function removeFile() {
		bWidth = 320; bHeight = 58;

		members.remove(fileText);
		fileText.destroy();

		super.removeFile();
	}
}