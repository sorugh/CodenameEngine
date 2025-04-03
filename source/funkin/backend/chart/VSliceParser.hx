package funkin.backend.chart;

import funkin.backend.chart.ChartData.ChartMetaData;

// These new structures are kinda a mess to port, i love and hate them at the same time; why the hell are every difficulty in the same file???  - Nex
class VSliceParser {
	public static function parseChart(data:Dynamic, metaData:Dynamic, events:Dynamic, result:ChartData) {
		// base fnf chart parsing
		var data:Array<SwagNote> = data;
		var metadata:SwagMetadata = metaData;
		var events:Array<SwagEvent> = events;

		result.stage = metadata.playData.stage;

		var p2isGF:Bool = false;
		result.strumLines.push({
			characters: [metadata.playData.characters.player],
			type: 1,
			position: "boyfriend",
			notes: [],
			vocalsSuffix: "-Player"
		});
		result.strumLines.push({
			characters: [metadata.playData.characters.opponent],
			type: 0,
			position: (p2isGF = metadata.playData.characters.opponent.startsWith("gf")) ? "girlfriend" : "dad",
			notes: [],
			vocalsSuffix: "-Opponent"
		});
		var gfName = metadata.playData.characters.girlfriend;
		if (!p2isGF && gfName != "none") {
			result.strumLines.push({
				characters: [gfName],
				type: 2,
				position: "girlfriend",
				notes: [],
				visible: false,
			});
		}

		var timeChanges = metadata.timeChanges;
		result.meta.bpm = timeChanges[0].bpm;
		result.meta.needsVoices = true;

		for (note in data)
		{
			var daNoteType:Null<Int> = null;
			if (note.k != null)
				daNoteType = Chart.addNoteType(result, note.k == "alt" ? "Alt Anim Note" : note.k);  // they hardcoded "alt" for converting old charts BUT THEN WHY THE HELL WOULD YOU CALL "MOM" THE NOTE KIND IN WEEK5 GRAHHH  - Nex

			var daNoteData:Int = Std.int(note.d % 8);
			var isMustHit:Bool = Math.floor(daNoteData / 4) == 0;

			result.strumLines[isMustHit ? 0 : 1].notes.push({
				time: note.t,
				id: daNoteData % 4,
				type: daNoteType,
				sLen: note.l
			});
		}

		var curBPM = result.meta.bpm;
		for (i in 1...timeChanges.length)  // starting from 1 on purpose  - Nex
		{
			var curChange = timeChanges[i];
			if (curBPM != curChange.bpm)
			{
				curBPM = curChange.bpm;
				result.events.push({
					time: curChange.t,
					name: "BPM Change",
					params: [curBPM]
				});
			}
		}

		for (event in events)
		{
			var values = event.v;
			switch (event.e)
			{
				case "FocusCamera":
					var arr:Array<Dynamic> = [switch(values.char) {
						case 0: 1;
						case 1: 0;
						default: 2;
					}];
					if (values.ease != "CLASSIC" && values.ease != null) {
						if (values.ease == "INSTANT") arr = arr.concat([false]);
						else {
							var cneEase = parseEase(values.ease);
							arr = arr.concat([true, values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1]]);
						}
					}
					trace(arr);
					result.events.push({
						time: event.t,
						name: "Camera Movement",
						params: arr
					});
				case "PlayAnimation":
					result.events.push({
						time: event.t,
						name: "Play Animation",
						params: [switch(values.target) {
							case 'boyfriend' | 'bf' | 'player': 1;
							case 'dad' | 'opponent': 0;
							default /*case 'girlfriend' | 'gf'*/: 2;  // usually the default should be the stage prop but we dont have that sooo  - Nex
						}, values.anim, values.force == null ? false : values.force]
					});
				case "ScrollSpeed":
					var cneEase = values.ease == null || values.ease == "INSTANT" ? ["linear", null] : parseEase(values.ease);
					result.events.push({
						time: event.t,
						name: "Scroll Speed Change",  // we dont support the strumline value and also i will put the whole ease name into a single parameter since it works anyways  - Nex
						params: [values.ease != "INSTANT", values.scroll == null ? 1 : values.scroll, values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1], values.absolute != true]
					});
				case "SetCameraBop":
					result.events.push({
						time: event.t,
						name: "Camera Modulo Change",
						params: [values.rate == null ? 4 : values.rate, values.intensity == null ? 1 : values.intensity]
					});
				case "ZoomCamera":
					var cneEase = values.ease == null || values.ease == "INSTANT" ? ["linear", null] : parseEase(values.ease);
					result.events.push({
						time: event.t,
						name: "Camera Zoom",  // we dont support the direct mode since welp, its kind of useless here  - Nex
						params: [values.ease != "INSTANT", values.zoom == null ? 1 : values.zoom, "camGame", values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1], false]
					});
			}
		}

		/*var camFocusedBF:Bool = false;
		var altAnims:Bool = false;
		var beatsPerMeasure:Float = data.beatsPerMeasure.getDefault(Flags.DEFAULT_BEATS_PER_MEASURE);
		var curBPM:Float = firstTimeChange.bpm;
		var curTime:Float = 0;
		var curCrochet:Float = ((60 / curBPM) * 1000);

		if (data.notes != null) for(section in data.notes) {
			if (section == null) {
				curTime += curCrochet * beatsPerMeasure;
				continue; // Yoshi Engine charts crash fix
			}

			if (camFocusedBF != (camFocusedBF = section.mustHitSection)) {
				result.events.push({
					time: curTime,
					name: "Camera Movement",
					params: [camFocusedBF ? 1 : 0]
				});
			}

			if (section.altAnim == null) section.altAnim = false;
			if (altAnims != (altAnims = section.altAnim)) {
				result.events.push({
					time: curTime,
					name: "Alt Animation Toggle",
					params: [altAnims, false, 0]
				});
			}

			if (section.sectionNotes != null) for(note in section.sectionNotes) {
				if (note[1] < 0) continue;

				var daStrumTime:Float = note[0];
				var daNoteData:Int = Std.int(note[1] % 8);
				var daNoteType:Int = Std.int(note[1] / 8);
				var gottaHitNote:Bool = daNoteData >= 4 ? !section.mustHitSection : section.mustHitSection;

				if (note.length > 2) {
					if (note[3] is Int && data.noteTypes != null)
						daNoteType = Chart.addNoteType(result, data.noteTypes[Std.int(note[3])-1]);
					else if (note[3] is String)
						daNoteType = Chart.addNoteType(result, note[3]);
				} else {
					if(data.noteTypes != null)
						daNoteType = Chart.addNoteType(result, data.noteTypes[daNoteType-1]);
				}

				result.strumLines[gottaHitNote ? 1 : 0].notes.push({
					time: daStrumTime,
					id: daNoteData % 4,
					type: daNoteType,
					sLen: note[2]
				});
			}

			if (section.changeBPM && section.bpm != curBPM) {
				curCrochet = ((60 / (curBPM = section.bpm)) * 1000);

				result.events.push({
					time: curTime,
					name: "BPM Change",
					params: [section.bpm]
				});
			}

			curTime += curCrochet * beatsPerMeasure;
		}*/
	}

	public static function parseMeta(data:Dynamic, result:ChartMetaData) {
		var data:SwagMetadata = data;
		result.name = data.songName;
		result.artist = data.artist;

		result.customValues = {};
		result.customValues.timeChanges = data.timeChanges;
		var firstTimeChange:SwagTimeChange = data.timeChanges[0];
		result.bpm = firstTimeChange.bpm;
		result.beatsPerMeasure = firstTimeChange.b != null ? firstTimeChange.b : Flags.DEFAULT_BEATS_PER_MEASURE;

		result.difficulties = data.playData.difficulties.concat(data.playData.songVariations);
		Reflect.deleteField(data.playData, "difficulties");

		for (field in Reflect.fields(data.playData))
			Reflect.setProperty(result.customValues, field, Reflect.getProperty(data.playData, field));
	}

	public static function encodeMeta(meta:ChartMetaData, ?chart:ChartData):SwagMetadata {
		var addVars:Dynamic = meta.customValues;
		var defStage:String = addVars.stage != null ? addVars.stage : Flags.DEFAULT_STAGE;
		var defChars:SwagCharactersList = addVars.characters != null ? addVars.characters : {player: Flags.DEFAULT_CHARACTER, girlfriend: Flags.DEFAULT_GIRLFRIEND, opponent: Flags.DEFAULT_OPPONENT, playerVocals: [], opponentVocals: [], instrumental: '', altInstrumentals: []};
		var defTimeCh:Array<SwagTimeChange>;

		if (addVars.timeChanges != null && addVars.timeChanges.length > 0) {
			defTimeCh = addVars.timeChanges;
			defTimeCh[0].bpm = meta.bpm;
		}
		else defTimeCh = [{bpm: meta.bpm, t: -1}];

		if (chart != null) {
			defStage = chart.stage;

			var done:Array<Bool> = [false, false, false];
			for (strumLine in chart.strumLines) switch (strumLine.type) {
				case OPPONENT:
					if (!done[0]) {
						done[0] = true;
						defChars.opponent = strumLine.characters.getDefault([defChars.opponent])[0];
					}
				case PLAYER:
					if (!done[1]) {
						done[1] = true;
						defChars.player = strumLine.characters.getDefault([defChars.player])[0];
					}
				case ADDITIONAL:
					if (!done[3]) {
						done[3] = true;
						defChars.girlfriend = strumLine.characters.getDefault([defChars.girlfriend])[0];
					}
			}
		}

		var result:SwagMetadata = {
			songName: meta.name,
			timeFormat: MILLISECONDS,
			artist: meta.artist,
			timeChanges: defTimeCh,
			looped: false,
			generatedBy: 'V-Slice Chart Importer (Codename Engine)',
			version: Flags.VSLICE_SONG_METADATA_VERSION,
			playData: {
				stage: defStage,
				characters: defChars,
				songVariations: addVars.songVariations != null ? [for (i in 0...addVars.songVariations.length) {meta.difficulties.remove(addVars.songVariations[i]); addVars.songVariations[i];}] : [],
				difficulties: meta.difficulties,
				noteStyle: addVars.noteStyle != null ? addVars.noteStyle : Flags.VSLICE_DEFAULT_NOTE_STYLE,
				album: addVars.album != null ? addVars.album : Flags.VSLICE_DEFAULT_ALBUM_ID,
				previewStart: addVars.previewStart != null ? addVars.previewStart : Flags.VSLICE_DEFAULT_PREVIEW_START,
    			previewEnd: addVars.previewEnd != null ? addVars.previewEnd : Flags.VSLICE_DEFAULT_PREVIEW_END
			},
		};

		return result;
	}

	public static function encodeChart(chart:ChartData):NewSwagSong {
		// TO DO
		return null;
	}

	public static function parseEase(vsliceEase:String):Array<String> {
		for (key in ['InOut', 'In', 'Out']) if (vsliceEase.endsWith(key)) return [vsliceEase.substr(0, vsliceEase.length - key.length), key];
		return [vsliceEase];
	}
}

// METADATA STRUCTURES
typedef SwagMetadata =
{
	var timeFormat:SwagTimeFormat;
	var artist:String;
	var songName:String;
	var playData:SwagPlayData;
	var timeChanges:Array<SwagTimeChange>;
	var generatedBy:String;
	var looped:Bool;
	var version:String;

	var ?divisions:Int;
	var ?offsets:SwagSongOffsets;
}

enum abstract SwagTimeFormat(String) from String to String
{
	var TICKS = 'ticks';
	var FLOAT = 'float';
	var MILLISECONDS = 'ms';
}

typedef SwagTimeChange =
{
	var ?d:Int;  // Time Signature Den
	var ?n:Int;  // Time Signature Num
	var t:Int;  // Time Stamp
	var ?b:Int;  // Beat Time
	var ?bt:Array<Int>;  // Beat Tuplets
	var bpm:Float;
}

typedef SwagPlayData =
{
	var album:String;
	var previewStart:Float;
	var previewEnd:Float;
	var stage:String;
	var characters:SwagCharactersList;
	var songVariations:Array<String>;
	var difficulties:Array<String>;
	var noteStyle:String;
}

typedef SwagCharactersList =
{
	var player:String;
	var girlfriend:String;
	var opponent:String;
	var instrumental:String;
	var altInstrumentals:Array<String>;
	var opponentVocals:Array<String>;
	var playerVocals:Array<String>;
}

typedef SwagSongOffsets =
{
	var ?instrumental:Float;
	var ?altInstrumentals:Dynamic;
	var ?vocals:Dynamic;
}

// CHART STRUCTURE
typedef NewSwagSong =
{
	var version:String;
	var scrollSpeed:Dynamic;  // Map<String, Float>
	var events:Array<SwagEvent>;
	var notes:Dynamic;  // Map<String, Array<SwagNote>>
	var generatedBy:String;
}

typedef SwagEvent =
{
	var t:Float;  // Time
	var e:String;  // Event Kind
	var v:Dynamic;  // Value (Map<String, Dynamic>)
}

typedef SwagNote =
{
	var t:Float;  // Time
	var d:Int;  // Data
	var l:Float;  // Length
	var k:String;  // Kind
}