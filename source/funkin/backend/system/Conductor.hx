package funkin.backend.system;

import flixel.FlxState;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.chart.ChartData;
import funkin.backend.system.interfaces.IBeatReceiver;

@:structInit
class BPMChangeEvent
{
	public var songTime:Float;
	public var bpm:Float;
	public var beatsPerMeasure:Float = 4;
	public var stepsPerBeat:Int = 4;

	public var endSongTime:Float = 0;
	public var continuous:Bool = false;

	public var stepTime:Float;
	public var beatTime:Float;
	public var measureTime:Float;
}

final class Conductor
{
	/**
	 * FlxSignals
	 */
	public static var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onBPMChange:FlxTypedSignal<(Float,Float)->Void> = new FlxTypedSignal();
	public static var onTimeSignatureChange:FlxTypedSignal<(Float,Float)->Void> = new FlxTypedSignal();

	/**
	 * Current position of the song, in milliseconds.
	 */
	public static var songPosition(get, default):Float;
	private static function get_songPosition() {
		if (songOffset != Options.songOffset) songOffset = Options.songOffset;
		return songPosition - songOffset;
	}

	/**
	 * Offset of the song
	 */
	public static var songOffset:Float = 0;


	/**
	 * Current bpmChangeMap index
	 */
	public static var curChangeIndex:Int = 0;

	/**
	 * Current bpmChangeMap
	 */
	public static var curChange(get, never):Null<BPMChangeEvent>;
	private static function get_curChange()
		return bpmChangeMap[curChangeIndex];

	/**
	 * Current BPM
	 */
	public static var bpm(get, never):Float;
	private static function get_bpm()
		return curChangeIndex == 0 ? startingBPM : getTimeWithIndexInBPM(songPosition, curChangeIndex);

	/**
	 * Starting BPM
	 */
	public static var startingBPM(get, never):Float;
	private static function get_startingBPM()
		return bpmChangeMap.length == 0 ? 100 : bpmChangeMap[0].bpm;

	/**
	 * Current Crochet (time per beat), in milliseconds.
	 * It should be crotchet but ehhh, now it's there for backward compatibility.
	 */
	public static var crochet(get, never):Float;
	private static function get_crochet() return 60000 / bpm;

	/**
	 * Current StepCrochet (time per step), in milliseconds.
	 */
	public static var stepCrochet(get, never):Float;
	private static function get_stepCrochet() return crochet / stepsPerBeat;

	/**
	 * Number of beats per mesure (top number in time signature). Defaults to 4.
	 */
	public static var beatsPerMeasure(get, never):Float;
	private static function get_beatsPerMeasure()
		return bpmChangeMap.length == 0 ? 4 : bpmChangeMap[curChangeIndex].beatsPerMeasure;

	/**
	 * Number of steps per beat (bottom number in time signature). Defaults to 4.
	 */
	public static var stepsPerBeat(get, never):Float;
	private static function get_stepsPerBeat()
		return bpmChangeMap.length == 0 ? 4 : bpmChangeMap[curChangeIndex].stepsPerBeat;

	/**
	 * Current step
	 */
	public static var curStep:Int = 0;

	/**
	 * Current beat
	 */
	public static var curBeat:Int = 0;

	/**
	 * Current measure
	 */
	public static var curMeasure:Int = 0;

	/**
	 * Current step, as a `Float` (ex: 4.94, instead of 4)
	 */
	public static var curStepFloat:Float = 0;

	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public static var curBeatFloat:Float = 0;

	/**
	 * Current measure, as a `Float` (ex: 1.24, instead of 1)
	 */
	public static var curMeasureFloat:Float = 0;


	@:dox(hide) public static var lastSongPos:Float = 0;
	@:dox(hide) public static var offset:Float = 0;

	/**
	 * Array of all BPM changes that have been mapped.
	 */
	public static var bpmChangeMap:Array<BPMChangeEvent>;

	@:dox(hide) public function new() {}

	public static function reset() {
		songPosition = lastSongPos = curBeatFloat = curStepFloat = curBeat = curStep = 0;
		changeBPM();
	}

	public static function changeBPM(bpm:Float = 100, beatsPerMeasure:Float = 4, stepsPerBeat:Int = 4)
		bpmChangeMap = [{bpm: bpm, beatsPerMeasure: beatsPerMeasure, stepsPerBeat: stepsPerBeat, songTime: 0, stepTime: 0, beatTime: 0, measureTime: 0}];

	public static function setupSong(SONG:ChartData) {
		reset();
		mapBPMChanges(SONG);
	}

	private static function mapBPMChange(curChange:BPMChangeEvent, time:Float, bpm:Float, ?endTime:Null<Float>):BPMChangeEvent {
		if (bpm == curChange.bpm) return curChange;
		
		var beatTime:Float, measureTime:Float, stepTime:Float;
		if (curChange.continuous) {
			beatTime = curChange.beatTime + (curChange.endSongTime - curChange.songTime) * (bpm - curChange.bpm) / Math.log(bpm / curChange.bpm) / 60000 +
				(time - curChange.endSongTime) / (60000 / curChange.bpm);
			
			measureTime = curChange.measureTime + (beatTime - curChange.beatTime) / beatsPerMeasure;
			stepTime = curChange.stepTime + (beatTime - curChange.beatTime) * stepsPerBeat;
		}
		else {
			beatTime = curChange.beatTime + (time - curChange.songTime) / (60000 / curChange.bpm);
			measureTime = curChange.measureTime + (beatTime - curChange.beatTime) / beatsPerMeasure;
			stepTime = curChange.stepTime + (beatTime - curChange.beatTime) * stepsPerBeat;
		}

		bpmChangeMap.push(curChange = {
			songTime: time,
			stepTime: stepTime,
			beatTime: beatTime,
			measureTime: measureTime,
			bpm: bpm,
			continuous: endTime is Float,
			beatsPerMeasure: curChange.beatsPerMeasure,
			stepsPerBeat: curChange.stepsPerBeat
		});
		if (curChange.continuous) curChange.endSongTime = endTime;
		return curChange;
	}

	/**
	 * Maps BPM changes from a song.
	 * @param song Song to map BPM changes from.
	 */
	public static function mapBPMChanges(song:ChartData) {
		var curChange:BPMChangeEvent = {
			songTime: 0,
			stepTime: 0,
			beatTime: 0,
			measureTime: 0,
			bpm: song.meta.bpm,
			beatsPerMeasure: song.meta.beatsPerMeasure.getDefault(4),
			stepsPerBeat: CoolUtil.floorInt(song.meta.stepsPerBeat.getDefault(4))
		};
		bpmChangeMap = [curChange];
		if (song.events == null) return;

		// fix the sort first...
		var events:Array<ChartEvent> = [];
		for (e in song.events) if (e.params != null && (e.name == "BPM Change" || e.name == "Time Signature Change")) events.push(e);
		events.sort(function(a, b) return Std.int(a.time - b.time));

		for (e in events) {
			var name = e.name, params = e.params, time = e.time;
			if (name == "BPM Change" && params[0] is Float)
				curChange = mapBPMChange(curChange, time, params[0], params[1]);
			else if (name == "Time Signature Change") {
				var beatsPerMeasure = params[0], stepsPerBeat = params[1];
				//if (beatsPerMeasure == curChange.beatsPerMeasure && stepsPerBeat == curChange.stepsPerBeat) continue;
				/* TODO: make so time sigs doesnt stop the bpm change if its in the duration of bpm change */

				if (curChange.songTime == time) {
					curChange.beatsPerMeasure = beatsPerMeasure;
					curChange.stepsPerBeat = stepsPerBeat;
				}
				else
					curChange = mapBPMChange(curChange, time, curChange.bpm);
				
				curChange.stepTime = CoolUtil.floorInt(curChange.stepTime + .99998);
				curChange.beatTime = CoolUtil.floorInt(curChange.beatTime + .99998);
				curChange.measureTime = CoolUtil.floorInt(curChange.measureTime + .99998);
			}
		}
	}

	private static var elapsed:Float;

	public static function init() {
		FlxG.signals.preUpdate.add(update);
		FlxG.signals.preStateCreate.add(onStateSwitch);
		reset();
	}

	private static function __updateSongPos(elapsed:Float) {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			lastSongPos = FlxG.sound.music != null ? FlxG.sound.music.time - songOffset : -songOffset;
			return;
		}

		if (lastSongPos != (lastSongPos = FlxG.sound.music.time - songOffset)) {
			// update conductor
			songPosition = lastSongPos;
		} else {
			songPosition += songOffset + elapsed * 1000;
		}
	}

	private static function onStateSwitch(newState:FlxState) {
		if (FlxG.sound.music == null)
			reset();
	}
	private static var __lastChange:BPMChangeEvent;
	private static var __updateBeat:Bool;
	private static var __updateMeasure:Bool;

	private static function update() {
		if (FlxG.state != null && FlxG.state is MusicBeatState && cast(FlxG.state, MusicBeatState).cancelConductorUpdate) return;

		__updateSongPos(FlxG.elapsed);

		var oldStep = curStep, oldBeat = curBeat, oldMeasure = curMeasure, oldChangeIndex = curChangeIndex;

		if ((curChangeIndex = getTimeInChangeIndex(songPosition, curChangeIndex)) > 0) {
			var change = curChange;
			curBeatFloat = getTimeWithBPMInBeats(songPosition, curChangeIndex, getTimeWithIndexInBPM(songPosition, curChangeIndex));
			curMeasureFloat = change.measureTime + (curBeatFloat - change.beatTime) / beatsPerMeasure;
			curStepFloat = change.stepTime + (curBeatFloat - change.beatTime) * stepsPerBeat;
		}
		else {
			curBeatFloat = songPosition / (60000 / bpm);
			curMeasureFloat = curBeatFloat / beatsPerMeasure;
			curStepFloat = curBeatFloat * stepsPerBeat;
		}

		if (curChangeIndex != oldChangeIndex) {
			var prev = bpmChangeMap[oldChangeIndex];
			if (beatsPerMeasure != prev.beatsPerMeasure || stepsPerBeat != prev.stepsPerBeat)
				onTimeSignatureChange.dispatch(beatsPerMeasure, stepsPerBeat);

			if (curChange.bpm != prev.bpm) onBPMChange.dispatch(curChange.bpm, curChange.endSongTime);
		}

		if (curStep != (curStep = CoolUtil.floorInt(curStepFloat))) {
			if (curStep < oldStep && oldStep - curStep < 2) return;
			// updates step
			__updateBeat = curBeat != (curBeat = CoolUtil.floorInt(curBeatFloat));
			__updateMeasure = __updateBeat && (curMeasure != (curMeasure = CoolUtil.floorInt(curMeasureFloat)));

			if (curStep > oldStep) {
				for(i in oldStep...curStep) {
					onStepHit.dispatch(i+1);
				}
			}
			if (__updateBeat && curBeat > oldBeat) {
				for(i in oldBeat...curBeat) {
					onBeatHit.dispatch(i+1);
				}
			}
			if (__updateMeasure && curMeasure > oldMeasure) {
				for(i in oldMeasure...curMeasure) {
					onMeasureHit.dispatch(i+1);
				}
			}

			if (FlxG.state is IBeatReceiver) {
				var state = FlxG.state;
				while(state != null) {
					if (state is IBeatReceiver && (state.subState == null || state.persistentUpdate)) {
						var st = cast(state, IBeatReceiver);
						if (curStep > oldStep) {
							for(i in oldStep...curStep) {
								st.stepHit(i+1);
							}
						}
						if (__updateBeat && curBeat > oldBeat) {
							for(i in oldBeat...curBeat) {
								st.beatHit(i+1);
							}
						}
						if (__updateMeasure && curMeasure > oldMeasure) {
							for(i in oldMeasure...curMeasure) {
								st.measureHit(i+1);
							}
						}
					}
					state = state.subState;
				}
			}
		}
	}

	public static function getTimeInChangeIndex(time:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].songTime > time) {
			while (--index >= 0) if (time > bpmChangeMap[index].songTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].songTime > time) return i;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getStepsInChangeIndex(stepTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].stepTime > stepTime) {
			while (--index >= 0) if (stepTime > bpmChangeMap[index].stepTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].stepTime > stepTime) return i;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getBeatsInChangeIndex(beatTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].beatTime > beatTime) {
			while (--index >= 0) if (beatTime > bpmChangeMap[index].beatTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].beatTime > beatTime) return i;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getMeasuresInChangeIndex(measureTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].measureTime > measureTime) {
			while (--index >= 0) if (measureTime > bpmChangeMap[index].measureTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].measureTime > measureTime) return i;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getTimeWithIndexInBPM(time:Float, index:Int):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && time < bpmChange.endSongTime && index > 0) {
			var prevBPM = bpmChangeMap[index].bpm;
			if (time <= bpmChange.songTime) return prevBPM;

			var ratio = (time - bpmChange.songTime) / (bpmChange.endSongTime - bpmChange.songTime);
			return Math.pow(prevBPM, 1 - ratio) * Math.pow(bpmChange.bpm, ratio);
		}
		return bpmChange.bpm;
	}

	public static function getBeatsWithIndexInBPM(beatTime:Float, index:Int):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && index > 0) {
			var prevBPM = bpmChangeMap[index].bpm;
			if (beatTime <= bpmChange.beatTime) return prevBPM;

			var endBeatTime = bpmChange.beatTime + (bpmChange.endSongTime - bpmChange.songTime) * (bpmChange.bpm - prevBPM) / Math.log(bpmChange.bpm / prevBPM) / 60000;
			if (beatTime < endBeatTime) return FlxMath.remapToRange(beatTime, bpmChange.beatTime, endBeatTime, prevBPM, bpmChange.bpm);
		}
		return bpmChange.bpm;
	}

	public static function getTimeInBPM(time:Float):Float {
		if (bpmChangeMap.length == 0) return 100;
		return getTimeWithIndexInBPM(time, getTimeInChangeIndex(time));
	}

	public static function getTimeWithBPMInBeats(time:Float, index:Int, bpm:Float):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && time > bpmChange.songTime && index > 0) {
			var prevBPM = bpmChangeMap[index].bpm;
			if (time > bpmChange.endSongTime)
				return bpmChange.beatTime + (bpmChange.endSongTime - bpmChange.songTime) * (bpm - prevBPM) / Math.log(bpm / prevBPM) / 60000 +
					(time - bpmChange.endSongTime) / (60000 / bpm);
			else
				return bpmChange.beatTime + (time - bpmChange.songTime) * (bpm - prevBPM) / Math.log(bpm / prevBPM) / 60000;
		}
		else {
			return bpmChange.beatTime + (time - bpmChange.songTime) / (60000 / bpm);
		}
	}

	public static function getTimeInSteps(time:Float):Float {
		var index = getTimeInChangeIndex(time);
		if (index == -1) return time / (15000 / 100);
		else if (index == 0) return time / (60000 / getTimeInBPM(time)) * bpmChangeMap[index].stepsPerBeat;
		else {
			var change = bpmChangeMap[index];
			return change.stepTime + (getTimeWithBPMInBeats(time, index, getTimeWithIndexInBPM(time, index)) - change.beatTime) * change.stepsPerBeat;
		}
	}

	@:haxe.warning("-WDeprecated")
	public static inline function getStepForTime(time:Float):Float return getTimeInSteps(time);

	public static function getTimeInBeats(time:Float):Float {
		var index = getTimeInChangeIndex(time);
		return index < 1 ? time / (60000 / getTimeInBPM(time)) : getTimeWithBPMInBeats(time, index, getTimeWithIndexInBPM(time, index));
	}

	public static function getBeatsWithBPMInTime(beatTime:Float, index:Int, bpm:Float):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && beatTime > bpmChange.beatTime && index > 0) {
			var prevBPM = bpmChangeMap[index].bpm;
			var time = bpmChange.songTime + (beatTime - bpmChange.beatTime) / (bpm - prevBPM) * Math.log(bpm / prevBPM) * 60000;
			if (time > bpmChange.endSongTime)
				return bpmChange.endSongTime + (beatTime - (
						bpmChange.beatTime + (bpmChange.endSongTime - bpmChange.songTime) * (bpm - prevBPM) / Math.log(bpm / prevBPM) / 60000
					)) * (60000 / bpm);
			else
				return time;
		}
		else {
			return bpmChange.songTime + (beatTime - bpmChange.beatTime) * (60000 / bpm);
		}
	}

	public static function getStepsInTime(stepTime:Float):Float {
		var index = getStepsInChangeIndex(stepTime);
		if (index == -1) return stepTime * (15000 / 100);
		else if (index == 0) return stepTime * (60000 / getTimeInBPM(0)) / bpmChangeMap[index].stepsPerBeat;
		else {
			var change = bpmChangeMap[index];
			var beatTime = change.beatTime + (stepTime - change.stepTime) / change.stepsPerBeat;
			return getBeatsWithBPMInTime(beatTime, index, getBeatsWithIndexInBPM(beatTime, index));
		}
	}

	@:haxe.warning("-WDeprecated")
	public static inline function getTimeForStep(steps:Float):Float return getStepsInTime(steps);

	public static function getBeatsInTime(beatTime:Float):Float {
		var index = getBeatsInChangeIndex(beatTime);
		return index < 1 ? beatTime * (60000 / getTimeInBPM(0)) : getBeatsWithBPMInTime(beatTime, index, getBeatsWithIndexInBPM(beatTime, index));
	}

	public static inline function getMeasureLength()
		return stepsPerBeat * beatsPerMeasure;

	public static inline function getMeasuresLength() {
		if (FlxG.sound.music == null) return 0.0;
		var length = FlxG.sound.music.length;
		var index = getTimeInChangeIndex(length, bpmChangeMap.length - 1);
		var change = bpmChangeMap[index];
		return change.measureTime + (getTimeWithBPMInBeats(length, index, getTimeWithIndexInBPM(length, index)) - change.beatTime) / change.beatsPerMeasure;
	}
}