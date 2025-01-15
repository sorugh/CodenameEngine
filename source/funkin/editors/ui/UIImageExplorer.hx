package funkin.editors.ui;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;

using StringTools;
using funkin.backend.utils.BitmapUtil;

// TODO: make this limited if on web
class UIImageExplorer extends UIFileExplorer {
	public function new(x:Float, y:Float, ?w:Int, ?h:Int, ?onFile:(String, Bytes)->Void) {
		super(x, y, w, h, "png, jpg", function (filePath, file) {
			if (filePath != null && file != null) uploadImage(filePath, file);
			if (onFile != null) onFile(filePath, file);
		});

		deleteButton.bWidth = 26;
		deleteButton.bHeight = 26;

		this.allowAtlases = true; //allowAtlases;
	}

	private var allowAtlases:Bool;

	public var fileText:UIText;

	static var ANIMATE_ATLAS_REGEX = ~/^(?:Animation\.json|spritemap(?:\d+)?\.json)$/i; // no .zip atlases tho
	static var SPRITEMAP_JSON_REGEX = ~/^(?:spritemap(?:\d+)?\.json)$/i;
	static var SPRITEMAP_PNG_REGEX = ~/^(?:spritemap(?:\d+)?\.png)$/i;

	public function uploadImage(filePath:String, file:Bytes) {
		var imagePath:Dynamic = Path.normalize(filePath);

		var directoryPath:String = Path.directory(imagePath);
		var fileName:String = Path.withoutDirectory(imagePath).toLowerCase();
		var files:Array<String> = [];

		var isAtlas:Bool = false;
		if(allowAtlases && ANIMATE_ATLAS_REGEX.match(fileName)) {
			// check if directory has the other files
			files = FileSystem.readDirectory(directoryPath);
			var hasAnimationJson:Bool = false;
			var hasSpritemapJson:Bool = false;
			for(file in files) {
				file = file.toLowerCase();
				if(file == "animation.json")
					hasAnimationJson = true;
				else if(SPRITEMAP_JSON_REGEX.match(file))
					hasSpritemapJson = true;

				if(hasAnimationJson && hasSpritemapJson) {
					isAtlas = true;
					break;
				}
			}
		} else if(allowAtlases && Path.extension(fileName) == "png") {
			// check if the spritemap json files point to the image
			files = FileSystem.readDirectory(directoryPath);
			var hasAnimationJson:Bool = false;
			var foundSpritemapJson:Bool = false;
			for(file in files) {
				if(SPRITEMAP_JSON_REGEX.match(file)) {
					var content:String = CoolUtil.removeBOM(File.getContent(Path.join([directoryPath, file])));
					var json:AnimateAtlas = Json.parse(content);
					if(json.meta.image.toLowerCase() == fileName.toLowerCase())
						foundSpritemapJson = true;
				} else if(file.toLowerCase() == "animation.json")
					hasAnimationJson = true;

				if(hasAnimationJson && foundSpritemapJson) {
					isAtlas = true;
					break;
				}
			}
		}

		var spritemaps:Array<String> = [];
		var spritemapImages:Array<String> = [];
		if(isAtlas) {
			// this doesn't check for gaps in the numbering
			for(file in files)
				if(SPRITEMAP_JSON_REGEX.match(file))
					spritemaps.push(file);

			spritemaps.sort(Reflect.compare);

			for(spritemap in spritemaps) {
				var content:String = CoolUtil.removeBOM(File.getContent(Path.join([directoryPath, spritemap])));
				var json:AnimateAtlas = Json.parse(content);
				var imageToFind:String = json.meta.image.toLowerCase();
				for(file in files) {
					// lowercase since windows does case insensitive stuff, so we use lowercase to match behavior on mac and linux
					// and we also store the data from the filesystem instead of the json.meta.image
					if(file.toLowerCase() == imageToFind) {
						spritemapImages.push(file);
						break;
					}
				}
			}

			if(spritemapImages.length == 0)
				isAtlas = false;
		}

		var dataPathExt:String = !isAtlas ? CoolUtil.imageHasFrameData(imagePath) : null;
		var animationList:Array<String> = [];

		if (dataPathExt != null)
			animationList = CoolUtil.getAnimsListFromFrames(CoolUtil.loadFramesFromData(File.getContent(Path.withExtension(imagePath, dataPathExt)), dataPathExt), dataPathExt);

		var size = 0;
		var image = null;
		if (isAtlas && spritemapImages.length > 0) {
			var spritemapPath:String = Path.join([directoryPath, spritemapImages[0]]);
			trace("Loading spritemap: " + spritemapImages[0]);

			imagePath = Path.normalize(spritemapPath);
			directoryPath = Path.directory(imagePath);
			fileName = Path.withoutDirectory(imagePath).toLowerCase();

			for(spritemap in spritemapImages) {
				var spritemapPath:String = Path.join([directoryPath, spritemap]);
				var info = FileSystem.stat(spritemapPath);
				size += info.size;
			}

			image = BitmapData.fromFile(spritemapPath).crop();
		} else {
			trace("Loading image");
			size = file.length;
			image = BitmapData.fromBytes(file).crop();
		}

		uiElement = new FlxSprite().loadGraphic(image);

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

		var message = new StringBuf();
		message.add('${imagePath.file}.${imagePath.ext}');

		message.add(' (${CoolUtil.getSizeString(size)}');

		if(!isAtlas) {
			if (animationList.length > 0) {
				if(animationList.length == 1)
					message.add(', ${animationList.length} Animation Found');
				else
					message.add(', ${animationList.length} Animations Found');
			}
			else
				message.add(', #NO Animations Found#');
		} else {
			if(spritemaps.length == 1)
				message.add(', ${spritemaps.length} Spritemap Found');
			else
				message.add(', ${spritemaps.length} Spritemaps Found');
		}

		message.add(')');

		message.add(isAtlas ? " - Atlas" : " - Spritemap");

		fileText = new UIText(x+20, y+16, bWidth-20-deleteButton.bWidth-16, "");
		fileText.applyMarkup(message.toString(), [new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "#")]);
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