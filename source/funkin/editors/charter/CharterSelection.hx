package funkin.editors.charter;

import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.backend.chart.ChartData;
import funkin.backend.system.framerate.Framerate;
import funkin.editors.EditorTreeMenu;
import funkin.editors.charter.SongCreationScreen.SongCreationData;
import funkin.menus.FreeplayState.FreeplaySonglist;
import funkin.options.*;
import funkin.options.type.*;
import funkin.options.type.NewOption;
import haxe.Json;

using StringTools;

class CharterSelection extends EditorTreeMenu {
	public var freeplayList:FreeplaySonglist;
	public var curSong:ChartMetaData;
	public override function create() {
		bgType = "charter";

		super.create();

		Framerate.offset.y = 60;

		freeplayList = FreeplaySonglist.get(false);

		var list:Array<OptionType> = [
			for(s in freeplayList.songs) new EditorIconOption(s.name, TU.translate("charterSelection.acceptSong"), s.icon, function() {
				curSong = s;
				var list:Array<OptionType> = [
					for(d in s.difficulties) if (d != "")
						new TextOption(d, TU.translate("charterSelection.acceptDifficulty"), function() {
							FlxG.switchState(new Charter(s.name, d));
						})
				];
				#if sys
				var newDiff = TU.translate("charterSelection.newDifficulty");
				list.push(new NewOption(newDiff, newDiff, function() {
					FlxG.state.openSubState(new ChartCreationScreen(saveChart));
				}));
				#end
				optionsTree.add(new OptionsScreen(s.name, TU.translate("charterSelection.selectDifficulty"), list));
			}, s.color.getDefault(0xFFFFFFFF))
		];

		#if sys
		var newSong = TU.translate("charterSelection.newSong");
		list.insert(0, new NewOption(newSong, newSong, function() {
			FlxG.state.openSubState(new SongCreationScreen(saveSong));
		}));
		#end

		main = new OptionsScreen(TU.translate("editor.chart.name"), TU.translate("charterSelection.desc"), list);

		DiscordUtil.call("onEditorTreeLoaded", ["Chart Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		bg.colorTransform.redOffset = lerp(bg.colorTransform.redOffset, 0, 0.0625);
		bg.colorTransform.greenOffset = lerp(bg.colorTransform.greenOffset, 0, 0.0625);
		bg.colorTransform.blueOffset = lerp(bg.colorTransform.blueOffset, 0, 0.0625);
		bg.colorTransform.redMultiplier = lerp(bg.colorTransform.redMultiplier, 1, 0.0625);
		bg.colorTransform.greenMultiplier = lerp(bg.colorTransform.greenMultiplier, 1, 0.0625);
		bg.colorTransform.blueMultiplier = lerp(bg.colorTransform.blueMultiplier, 1, 0.0625);
	}

	public override function onMenuChange() {
		super.onMenuChange();
		if (optionsTree.members.length > 1) { // selected a song
			if(main != null) {
				var opt = main.members[main.curSelected];
				if(opt is EditorIconOption) {
					var opt:EditorIconOption = cast opt;

					// small flashbang
					var color = opt.flashColor;
					bg.colorTransform.redOffset = 0.25 * color.red;
					bg.colorTransform.greenOffset = 0.25 * color.green;
					bg.colorTransform.blueOffset = 0.25 * color.blue;
					bg.colorTransform.redMultiplier = FlxMath.lerp(1, color.redFloat, 0.25);
					bg.colorTransform.greenMultiplier = FlxMath.lerp(1, color.greenFloat, 0.25);
					bg.colorTransform.blueMultiplier = FlxMath.lerp(1, color.blueFloat, 0.25);
				}
			}
		}
	}

	#if sys
	public function saveSong(creation:SongCreationData, ?callback:String -> SongCreationData -> Void) {
		var songAlreadyExists:Bool = [for (s in freeplayList.songs) s.name.toLowerCase()].contains(creation.meta.name.toLowerCase());

		if (songAlreadyExists) {
			openSubState(new UIWarningSubstate(TU.translate("chartCreation.warnings.song-exists-title"), TU.translate("chartCreation.warnings.song-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: function(t) {}},
			]));
			return;
		}

		// Paths
		var songsDir:String = '${Paths.getAssetsRoot()}/songs/';
		var songFolder:String = '$songsDir${creation.meta.name}';

		#if sys
		// Make Directories
		sys.FileSystem.createDirectory(songFolder);
		sys.FileSystem.createDirectory('$songFolder/song');
		sys.FileSystem.createDirectory('$songFolder/charts');

		// Save Files
		CoolUtil.safeSaveFile('$songFolder/meta.json', Chart.makeMetaSaveable(creation.meta));
		if (creation.instBytes != null) sys.io.File.saveBytes('$songFolder/song/Inst.${Flags.SOUND_EXT}', creation.instBytes);
		if (creation.voicesBytes != null) sys.io.File.saveBytes('$songFolder/song/Voices.${Flags.SOUND_EXT}', creation.voicesBytes);

		if (creation.playerVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Player.${Flags.SOUND_EXT}', creation.playerVocals);
		if (creation.oppVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Opponent.${Flags.SOUND_EXT}', creation.oppVocals);
		#end

		if (callback != null)
			callback(songFolder, creation);

		var option = new EditorIconOption(creation.meta.name, TU.translate("charterSelection.acceptSong"), creation.meta.icon, function() {
			curSong = creation.meta;
			var list:Array<OptionType> = [
				for(d in creation.meta.difficulties)
					if (d != "") new TextOption(d, TU.translate("charterSelection.acceptDifficulty"), function() {
						FlxG.switchState(new Charter(creation.meta.name, d));
					})
			];
			var newDiff = TU.translate("charterSelection.newDifficulty");
			list.push(new NewOption(newDiff, newDiff, function() {
				FlxG.state.openSubState(new ChartCreationScreen(saveChart));
			}));
			optionsTree.insert(1, new OptionsScreen(creation.meta.name, TU.translate("charterSelection.selectDifficulty"), list));
		}, creation.meta.color.getDefault(0xFFFFFFFF));

		// Add to List
		freeplayList.songs.insert(0, creation.meta);
		main.insert(1, option);
	}

	public function saveChart(name:String, data:ChartData) {
		var difficultyAlreadyExists:Bool = curSong.difficulties.contains(name);

		if (difficultyAlreadyExists) {
			openSubState(new UIWarningSubstate(TU.translate("chartCreation.warnings.chart-exists-title"), TU.translate("chartCreation.warnings.chart-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: function(t) {}},
			]));
			return;
		}

		// Paths
		var songFolder:String = '${Paths.getAssetsRoot()}/songs/${curSong.name}';

		// Save Files
		CoolUtil.safeSaveFile('$songFolder/charts/${name}.json', Json.stringify(data, Flags.JSON_PRETTY_PRINT));

		// Add to List
		// duplicated code, todo: fix this
		curSong.difficulties.push(name);
		var option = new TextOption(name, TU.translate("charterSelection.acceptDifficulty"), function() {
			FlxG.switchState(new Charter(curSong.name, name));
		});
		optionsTree.members[optionsTree.members.length-1].insert(optionsTree.members[optionsTree.members.length-1].length-1, option);

		// Add to Meta
		var meta = Json.parse(sys.io.File.getContent('$songFolder/meta.json'));
		if (meta.difficulties != null && !meta.difficulties.contains(name)) {
			meta.difficulties.push(name);
			CoolUtil.safeSaveFile('$songFolder/meta.json', Chart.makeMetaSaveable(meta));
		}
	}
	#end
}