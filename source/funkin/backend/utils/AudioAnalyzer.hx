package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;
import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

#if (lime_cffi && lime_vorbis)
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

typedef AudioAnalyzerCallback = Int->Int->Void;

/**
 * An utility that analyze FlxSounds,
 * can be used to make waveform or real-time audio visualizer.
 * 
 * FlxSound.amplitude does work in CNE so if any case if your only checking for peak of current
 * time, use that instead.
**/
class AudioAnalyzer {
	public static function getByte(buf:ArrayBuffer, pos:Int, wordSize:Int):Int {
		if (wordSize == 2) return inline ArrayBufferIO.getInt16(buf, pos);
		else if (wordSize == 3) {
			var b = inline ArrayBufferIO.getUint16(buf, pos) | (buf.get(pos + 2) << 16);
			if (b > 8388608) return b - 16777216;
			else return b;
		}
		else if (wordSize == 4) return inline ArrayBufferIO.getInt32(buf, pos);
		else return inline ArrayBufferIO.getUint8(buf, pos) - 128;
	}

	public var sound:FlxSound;
	public var buffer(default, null):AudioBuffer;
	public var fftSamples(default, set):Int;

	public var byteSize(default, null):Int;

	var __toBits:Float;
	var __wordSize:Int;
	var __sampleSize:Int;

	#if (lime_cffi && lime_vorbis)
	var __vorbis:VorbisFile;
	var __buffer:ArrayBuffer;
	var __bufferSize:Int;
	#end

	// analyze
	var __min:Array<Int> = [];
	var __max:Array<Int> = [];
	var __minByte:Int;
	var __maxByte:Int;

	// samples
	var __sampleIndex:Int;
	var __sampleOutputLength:Int;
	var __sampleOutput:Array<Float>;

	// fft
	var __logN:Int;
	var __freqSamples:Array<Float>;
	var __reverseIndices:Array<Int> = [];
	var __rootReals:Array<Float> = [];
	var __rootImags:Array<Float> = [];
	var __freqReals:Array<Float> = [];
	var __freqImags:Array<Float> = [];

	// levels
	var __frequencies:Array<Float>;

	/**
	 * Creates an analyzer for specified FlxSound
	 * @param sound An FlxSound to analyze.
	**/
	public function new(sound:FlxSound, fftSamples = 512) {
		this.sound = sound;
		this.fftSamples = fftSamples;
		__check();
	}

	function __check() if (sound.buffer != buffer) {
		byteSize = 1 << ((buffer = sound.buffer).bitsPerSample - 1);

		#if (lime_cffi && lime_vorbis) __vorbis = null; #end

		__toBits = buffer.sampleRate / 1000 * (__sampleSize = buffer.channels * (__wordSize = buffer.bitsPerSample >> 3));
		__min.resize(buffer.channels);
		__max.resize(buffer.channels);
	}

	inline function set_fftSamples(v:Int):Int {
		if (fftSamples == (fftSamples = v)) return v;
		
		var half = v >> 1, a, c;
		__logN = Math.floor(Math.log(v) / Math.log(2));
		__reverseIndices.resize(half);
		__rootReals.resize(half);
		__rootImags.resize(half);
		__freqReals.resize(half);
		__freqImags.resize(half);
		for (i in 0...half) {
			__reverseIndices[i] = __bitReverse(i);
			__rootReals[i] = Math.cos(a = 2 * Math.PI * i / v);
			__rootImags[i] = Math.sin(a);
		}

		return v;
	}

	inline function __bitReverse(x:Int):Int {
		var y = 0, i = __logN;
		while (i > 0) {
			y = (y << 1) | (x & 1);
			x >>= 1;
			i--;
		}
		return y;
	}

	public function getLevels(startPos:Float, barCount:Int, ?levels:Array<Float>, delta = 0.0, minDb = -70.0, maxDb = -20.0):Array<Float> {
		__frequencies = getFrequencies(startPos, __frequencies);

		if (levels == null) levels = [];
		levels.resize(barCount);

		var x1 = 0.5, i1 = 1, n = fftSamples >> 1;
		var x2, i2, v;
		for (i in 0...barCount) {
			i2 = Math.floor(x2 = Math.pow(n, (i + 1) / barCount) - 0.5);

			if (i2 < i1) v = __frequencies[i2] * (x2 - x1);
			else {
				v = __frequencies[i1 - 1] * (i1 - x1);
				while (i1 < i2) v += __frequencies[i1++];
				if (i2 < n) v += __frequencies[i2] * (x2 - i2);
			}

			i1 = Math.ceil(x1 = x2);

			v = 20 * Math.log(v * barCount / 12) / 2.302585092994046/*log(10)*/ / (maxDb - minDb);
			if (delta > 0 && levels[i] > v) levels[i] -= (levels[i] - v) * delta;
			else levels[i] = v;
		}

		return levels;
	}

	/**
	 * Gets frequencies from an attached FlxSound from startPos with samples
	 * @return Output of frequencies ranging from 1 to fftSamples/2.
	**/
	public function getFrequencies(startPos:Float, ?frequencies:Array<Float>):Array<Float> {
		__freqSamples = getSamples(startPos, fftSamples, true, __freqSamples);

		var inv = fftSamples >> 1;
		for (i in 0...inv) {
			__freqReals[__reverseIndices[i]] = __freqSamples[i];
			__freqImags[i] = 0;
		}

		var h = 1, g = 0, b = 0, r = 0;
		var tr, ti, i1, i2;
		while (inv > 0) {
			h <<= 1;
			while (g < fftSamples) {
				while (b < h) {
					i2 = (i1 = g + b) + h;
					tr = __rootReals[r] * __freqReals[i2] - __rootImags[r] * __freqImags[i2];
					ti = __rootReals[r] * __freqImags[i2] + __rootImags[r] * __freqReals[i2];

					__rootReals[i2] = __freqReals[i1] - tr;
					__rootImags[i2] = __freqImags[i1] - ti;
					__freqReals[i1] += tr;
					__freqImags[i1] += ti;

					b++;
					r += inv;
				}
				b = r = 0;
				g += h;
			}
			g = 0;

			inv >>= 1;
		}

		if (frequencies == null) frequencies = [];
		frequencies.resize(inv = fftSamples >> 1);
		
		var mag;
		for (i in 0...inv) frequencies[i] = (mag = Math.sqrt(__freqReals[i] * __freqReals[i] + __freqImags[i] * __freqImags[i])) < 0.001 ? 0 : mag;

		return frequencies;
	}

	/**
	 * Analyzes an attached FlxSound from startPos to endPos in milliseconds to get the amplitudes.
	 * @param startPos Start Position of the FlxSound in milliseconds.
	 * @param endPos End Position of the FlxSound in milliseconds.
	 * @param outOrOutMin The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional, if outMax doesn't get passed in, it will be [min, max] with all channels combined instead).
	 * @param outMax The output maximum value from the analyzer, indices is in channels (Optional).
	 * @return Output of amplitude from given position.
	**/
	public function analyze(startPos:Float, endPos:Float, ?outOrOutMin:Array<Float>, ?outMax:Array<Float>):Float {
		var hasOut = outOrOutMin != null;
		var hasTwoOut = hasOut && outMax != null;

		if (hasTwoOut) for (i in 0...buffer.channels) __min[i] = __max[i] = 0;
		__minByte = __maxByte = 0;

		__check();
		__read(startPos, endPos, hasTwoOut ? __analyzeCallback : __analyzeCallbackSimple);

		if (hasOut) {
			var f:Float;
			if (hasTwoOut) for (i in 0...buffer.channels) {
				if (outOrOutMin[i] < (f = __min[i] / byteSize)) outOrOutMin[i] = f;
				if (outMax[i] < (f = __max[i] / byteSize)) outMax[i] = f;
			}
			else {
				outOrOutMin.resize(2);
				if (outOrOutMin[0] < (f = __minByte / byteSize)) outOrOutMin[0] = f;
				if (outOrOutMin[1] < (f = __maxByte / byteSize)) outOrOutMin[1] = f;
			}
		}

		return (__maxByte + __minByte) / byteSize;
	}

	function __analyzeCallback(b:Int, c:Int):Void
		((b > __max[c]) ? (if ((__max[c] = b) > __maxByte) (__maxByte = b)) : (if (-b > __min[c]) (if ((__min[c] = -b) > __minByte) (__minByte = __min[c]))));

	function __analyzeCallbackSimple(b:Int, c:Int):Void
		((b > __maxByte) ? (__maxByte = b) : (if (-b > __minByte) (__minByte = -b)));

	/**
	 * Gets samples from startPos with given length of samples.
	 * @param startPos Start Position of the FlxSound in milliseconds.
	 * @param length Length of Samples.
	 * @param mono Merge all of the byte channels of samples in one channel instead (Optional).
	 * @param Output that gets passed into this function (Optional).
	 * @return Output of 
	**/
	public function getSamples(startPos:Float, length:Int, mono = true, ?output:Array<Float>):Array<Float> {
		((output == null) ? (__sampleOutput = output = []) : (__sampleOutput = output)).resize((__sampleOutputLength = length) * (mono ? 1 : buffer.channels));
		__sampleIndex = 0;

		__check();
		__read(startPos, startPos + (length / __toBits), mono ? __getSamplesCallbackMerge : __getSamplesCallback);

		__sampleOutput = null;
		return output;
	}

	// TODO: check later if this formula is correct.
	function __getSamplesCallbackMerge(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (c == 0) __sampleOutput[__sampleIndex] = b / buffer.channels / byteSize;
		else if (c == buffer.channels) {
			__sampleOutput[__sampleIndex] += b / buffer.channels / byteSize;
			__sampleIndex++;
		}
		else
			__sampleOutput[__sampleIndex] += b / buffer.channels / byteSize;
	}

	function __getSamplesCallback(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		__sampleOutput[__sampleIndex] = b / byteSize;
		__sampleIndex++;
	}

	/**
	 * Read an attached FlxSound from startPos to endPos in milliseconds with a callback.
	 * @param startPos Start Position of the FlxSound in milliseconds.
	 * @param endPos End Position of the FlxSound in milliseconds.
	 * @param callback Int->Int->Void Byte->Channels->Void Callback to get the byte of a sample.
	**/
	public function read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		__check();
		__read(startPos, endPos, callback);
	}

	inline function __read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		if (buffer.data != null) __readData(startPos, endPos, callback);
		#if lime_cffi
		else if (__canReadStream() && (startPos += __readStream(startPos, endPos, callback)) >= endPos) return;
		#if lime_vorbis
		else if (__prepareDecoder()) __readDecoder(startPos, endPos, callback);
		#end
		#end
	}

	inline function __readData(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var pos = Math.floor(startPos * __toBits), end = Math.floor(endPos * __toBits), c = 0;
		pos -= pos % __sampleSize;
		end -= end % __sampleSize;

		while (pos < end) {
			callback(getByte(buffer.data.buffer, pos, __wordSize), c);
			if (++c > buffer.channels) c = 0;
			pos += __wordSize;
		}
	}

	#if lime_cffi
	inline function __canReadStream():Bool
		@:privateAccess return sound._source != null && sound._source.__backend != null && sound._source.__backend.streamTimer != null;

	inline function __readStream(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback):Float @:privateAccess {
		var backend = sound._source.__backend;
		var i = backend.bufferSizes.length - backend.queuedBuffers;
		var time = backend.bufferTimes[i] * 1000;

		var n = Math.floor((endPos - startPos) * __toBits);
		if (startPos >= time && startPos < backend.bufferTimes[backend.bufferSizes.length - 1] * 1000) {
			var pos = Math.floor((startPos - time) * __toBits), buf = backend.bufferDatas[i].buffer, size = backend.bufferSizes[i], c = 0;
			pos -= pos % __sampleSize;

			while (n > 0) {
				callback(getByte(buf, pos, __wordSize), c);
				if (++c > buffer.channels) c = 0;
				if ((pos += __wordSize) >= size) {
					if (++i >= backend.bufferDatas.length) break;
					buf = backend.bufferDatas[i].buffer;
					size = backend.bufferSizes[i];
					pos = 0;
				}
				n -= __wordSize;
			}
		}

		return endPos - (n / __toBits);
	}

	#if lime_vorbis
	inline function __prepareDecoder():Bool @:privateAccess {
		if (buffer.__srcVorbisFile == null) return __vorbis != null;
		if (__vorbis != null) return true;
		if ((__vorbis = buffer.__srcVorbisFile.clone()) != null) { // IM HOPING IT HAVE A GC CLOSURE.
			__buffer = new ArrayBuffer(__bufferSize = 0x400 * __sampleSize);
			return true;
		}
		return false;
	}

	inline function __readDecoder(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var time = startPos / 1000;
		if (Math.abs(time - __vorbis.timeTell()) > 0.004) {
			if (startPos < 1) __vorbis.rawSeek(0);
			else __vorbis.timeSeek(time);
		}

		var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, result;
		var n = Math.floor((endPos - startPos) * __toBits), pos = 0, c = 0;
		n -= n % __sampleSize;

		while (n > 0) {
			result = __vorbis.read(__buffer, 0, n < __bufferSize ? n : __bufferSize, isBigEndian, __wordSize, true);
			if (result == Vorbis.HOLE) continue;
			else if (result <= 0) break;

			while (pos < result) {
				callback(getByte(__buffer, pos, __wordSize), c);
				if (++c > buffer.channels) c = 0;
				if ((pos += __wordSize) >= n) break;
			}
			pos = 0;
			n -= result;
		}
	}
	#end
	#end
}