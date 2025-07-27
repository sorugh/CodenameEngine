package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;

#if lime_vorbis
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
import lime.utils.ArrayBuffer;
#end

// ORIGINAL CODES FROM YOSH & LUNAR https://github.com/CodenameCrew/YoshiCrafterEngine/blob/main/source/WaveformSprite.hx
// REWRITTEN BY RALTYRO
class AudioAnalyzer {
	public var sound:FlxSound;
	public var buffer:AudioBuffer;
	var __toBits:Float;
	var __wordSize:Int;
	var __bitUnsignedSize:Int;
	var __bitSize:Int;
	var __min:Array<Int> = [];
	var __max:Array<Int> = [];

	//var __ln10:Float = 2.3025850929940456;
	//var __ln2:Float = 0.6931471805599453;
	#if lime_vorbis
	var __vorbis:VorbisFile;
	#end

	public function new(sound:FlxSound) {
		this.sound = sound;
		__check();
	}

	public function getLevels(levels:Array<Float>, barCount:Int, duration:Float):Float {
		__check();
		// TODO: implement FFT
		return 0;
	}

	inline function __check() if (sound.buffer != buffer) {
		__bitSize = 1 << ((buffer = sound.buffer).bitsPerSample - 1);
		__bitUnsignedSize = 1 << buffer.bitsPerSample;
		__toBits = buffer.sampleRate / 1000 * buffer.channels * (__wordSize = buffer.bitsPerSample >> 3);
		__vorbis = null;
		__min.resize(buffer.channels);
		__max.resize(buffer.channels);
	}

	/**
	 * Returns a peak of an attached FlxSound from startPos to endPos in milliseconds.
	 * @param startPos Start Position of the FlxSound in milliseconds.
	 * @param endPos End Position of the FlxSound in milliseconds.
	 * @param outMin The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional)
	 * @param outMax The output maximum value from the analyzer, indices is in channels (Optional)
	 * @return Output Amplitude value
	**/
	public function analyze(startPos:Float, endPos:Float, ?outMin:Array<Float>, ?outMax:Array<Float>):Float {
		__check();
		if (buffer.data != null) return __analyze(startPos, endPos, outMin, outMax);
		#if lime_vorbis
		else if (__prepareVorbis()) return __analyzeVorbis(startPos, endPos, outMin, outMax);
		#end
		return 0;
	}

	function __analyze(startPos:Float, endPos:Float, ?outMin:Array<Float>, ?outMax:Array<Float>):Float {
		__prepareAmplitude();

		var pos = Math.floor(startPos * __toBits), end = Math.floor(endPos * __toBits), buf = buffer.data #if !js .buffer #end;
		var c = Math.floor((pos % (__wordSize * buffer.channels)) / __wordSize), b = 0, w = 0;
		pos -= pos % __wordSize;
		end -= end % __wordSize;

		while (pos < end) {
			if (__wordSize == 1) b = #if js buf[pos++] #else buf.get(pos++) #end - __bitSize;
			else {
				while (w < buffer.bitsPerSample) {
					b |= #if js buf[pos] #else buf.get(pos) #end << w;
					w += 8;
					pos++;
				}
				if (b > __bitSize) b -= __bitUnsignedSize;
			}
			if (__max[c] < b) __max[c] = b; else if (__min[c] < (b = -b)) __min[c] = b;
			if (++c > buffer.channels) c = 0;
			w = b = 0;
		}

		return __getAmplitude(outMin, outMax);
	}

	inline function __prepareAmplitude() for (i in 0...buffer.channels) __min[i] = __max[i] = 0;
	inline function __getAmplitude(?outMin:Array<Float>, ?outMax:Array<Float>):Float {
		var min = 0, max = 0, useOutput = outMin != null && outMax != null, v:Float;
		for (i in 0...buffer.channels) {
			if (__min[i] > min) min = __min[i];
			if (__max[i] > max) max = __max[i];
			if (useOutput) {
				if (outMin[i] < (v = __min[i] / __bitSize)) outMin[i] = v;
				if (outMax[i] < (v = __max[i] / __bitSize)) outMax[i] = v;
			}
		}

		return (max + min) / __bitSize;
	}

	#if lime_vorbis // As far i know, only native supports vorbis
	var __buffer:ArrayBuffer;
	var __bufferSize:Int;
	function __prepareVorbis():Bool @:privateAccess {
		if (buffer.__srcVorbisFile == null) return __vorbis != null;
		if (__vorbis != null) return true;
		if ((__vorbis = buffer.__srcVorbisFile.clone()) != null) { // IM HOPING IT HAVE A GC CLOSURE.
			__buffer = new ArrayBuffer(__bufferSize = 0x400 * buffer.channels * (buffer.bitsPerSample >> 3));
			return true;
		}
		return false;
	}

	function __analyzeVorbis(startPos:Float, endPos:Float, ?outMin:Array<Float>, ?outMax:Array<Float>):Float @:privateAccess {
		var n = Math.floor((endPos - startPos) * __toBits);
		if ((n -= n % __wordSize) < __wordSize) return 0;

		var pos = 0, c = 0, b = 0, w = 0;
		__prepareAmplitude();

		var backend = sound._source != null ? sound._source.__backend : null;
		if (backend != null && backend.streamTimer != null) {
			var i = backend.bufferSizes.length - backend.queuedBuffers;
			var time = backend.bufferTimes[i] * 1000;

			if (startPos >= time && startPos < backend.bufferTimes[backend.bufferSizes.length - 1] * 1000) {
				var buf = backend.bufferDatas[i].buffer, size = backend.bufferSizes[i];
				c = Math.floor(((pos = Math.floor((startPos - time) * __toBits)) % (__wordSize * buffer.channels)) / __wordSize);
				pos -= pos % __wordSize;

				while (n > 0) {
					if (__wordSize == 1) b = buf.get(pos++) - __bitSize;
					else {
						while (w < buffer.bitsPerSample) {
							b |= buf.get(pos) << w;
							w += 8;
							pos++;
						}
						if (b > __bitSize) b -= __bitUnsignedSize;
					}
					if (__max[c] < b) __max[c] = b; else if (__min[c] < (b = -b)) __min[c] = b;
					if (++c > buffer.channels) c = 0;
					if (pos >= size) {
						if (++i >= backend.bufferDatas.length) break;
						size = backend.bufferSizes[i];
						buf = backend.bufferDatas[i].buffer;
						pos = 0;
					}
					w = b = 0;
					n -= __wordSize;
				}

				if (n == 0) return __getAmplitude(outMin, outMax);
				startPos = pos / __toBits + time;
				pos = c = 0;
			}
		}

		if (Math.abs(startPos - __vorbis.timeTell() * 1000) > 4) {
			if (startPos < 1) __vorbis.rawSeek(0);
			else __vorbis.timeSeek(startPos / 1000);
		}

		var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, result;
		while (n > 0) {
			n -= (result = __vorbis.read(__buffer, 0, n < __bufferSize ? n : __bufferSize, isBigEndian, __wordSize, true));

			if (result == Vorbis.HOLE) continue;
			else if (result <= 0) break;

			while (pos < result) {
				if (__wordSize == 1) b = __buffer.get(pos++) - __bitSize;
				else {
					while (w < buffer.bitsPerSample) {
						b |= __buffer.get(pos) << w;
						w += 8;
						pos++;
					}
					if (b > __bitSize) b -= __bitUnsignedSize;
				}
				if (__max[c] < b) __max[c] = b; else if (__min[c] < (b = -b)) __min[c] = b;
				if (++c > buffer.channels) c = 0;
				w = b = 0;
			}
			pos = 0;
		}

		return __getAmplitude(outMin, outMax);
	}
	#end
}