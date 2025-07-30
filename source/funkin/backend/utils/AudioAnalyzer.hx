package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;
import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

#if (lime_cffi && lime_vorbis)
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

/**
 * An utility that analyze FlxSounds,
 * can be used to make waveform or real-time audio visualizer.
 * 
 * FlxSound.amplitude does work in CNE so if any case if your only checking for peak of current
 * time, use that instead.
**/
class AudioAnalyzer {
	public static function getByte(buf:ArrayBuffer, pos:Int, wordSize:Int):Int {
		if (wordSize == 2) return ArrayBufferIO.getInt16(buf, pos);
		else if (wordSize == 3) {
			var b = ArrayBufferIO.getUint16(buf, pos) | (buf.get(pos + 2) << 16);
			if (b > 8388608) return b - 16777216;
			else return b;
		}
		else if (wordSize == 4) return ArrayBufferIO.getInt32(buf, pos);
		else return ArrayBufferIO.getUint8(buf, pos) - 128;
	}

	public var sound:FlxSound;
	public var buffer:AudioBuffer;
	public var fftSize:Int;

	public var byteSize:Int;

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

	/**
	 * Creates an analyzer for specified FlxSound
	 * @param sound An FlxSound to analyze.
	**/
	public function new(sound:FlxSound, fftSize = 1024) {
		this.sound = sound;
		this.fftSize = fftSize;
		__check();
	}

	function __check() if (sound.buffer != buffer) {
		byteSize = 1 << ((buffer = sound.buffer).bitsPerSample - 1);

		__toBits = buffer.sampleRate / 1000 * (__sampleSize = buffer.channels * (__wordSize = buffer.bitsPerSample >> 3));
		__min.resize(buffer.channels);
		__max.resize(buffer.channels);

		#if (lime_cffi && lime_vorbis) __vorbis = null; #end
	}

	/**
	 * TODO: IMPLEMENT FFT
	**/
	public function getLevels(levels:Array<Float>, barCount:Int, duration:Float):Float {
		return 0;
	}

	/**
	 * Returns a peak of an attached FlxSound from startPos to endPos in milliseconds.
	 * @param startPos Start Position of the FlxSound in milliseconds.
	 * @param endPos End Position of the FlxSound in milliseconds.
	 * @param outOrOutMin The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional, if outMax doesn't get passed in, it will be [min, max] with all channels combined instead)
	 * @param outMax The output maximum value from the analyzer, indices is in channels (Optional)
	 * @return Output Amplitude value
	**/
	public function analyze(startPos:Float, endPos:Float, ?outOrOutMin:Array<Float>, ?outMax:Array<Float>):Float {
		__minByte = __maxByte = 0;

		if (outOrOutMin != null) {
			var f:Float;
			if (outMax != null) {
				for (i in 0...buffer.channels) __min[i] = __max[i] = 0;

				read(startPos, endPos, __analyzeCallback);

				for (i in 0...buffer.channels) {
					if (outOrOutMin[i] < (f = __min[i] / byteSize)) outOrOutMin[i] = f;
					if (outMax[i] < (f = __max[i] / byteSize)) outMax[i] = f;
				}
			}
			else {
				read(startPos, endPos, __analyzeCallbackSimple);

				outOrOutMin.resize(2);
				if (outOrOutMin[0] < (f = __minByte / byteSize)) outOrOutMin[0] = f;
				if (outOrOutMin[1] < (f = __maxByte / byteSize)) outOrOutMin[1] = f;
			}
		}
		else
			read(startPos, endPos, __analyzeCallbackSimple);

		return (__maxByte + __minByte) / byteSize;
	}

	function __analyzeCallback(b:Int, c:Int):Void
		((b > __max[c]) ? (if ((__max[c] = b) > __maxByte) (__maxByte = b)) : (if (-b > __min[c]) (if ((__min[c] = -b) > __minByte) (__minByte = __min[c]))));

	function __analyzeCallbackSimple(b:Int, c:Int):Void
		((b > __maxByte) ? (__maxByte = b) : (if (-b > __minByte) (__minByte = -b)));

	public function read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		__check();
		if (buffer.data != null) __read(startPos, endPos, callback);
		#if lime_cffi
		else if (__canReadStream() && (startPos += __readStream(startPos, endPos, callback)) >= endPos) return;
		#if lime_vorbis
		else if (__prepareDecoder()) __readDecoder(startPos, endPos, callback);
		#end
		#end
	}

	inline function __read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
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

private typedef AudioAnalyzerCallback = Int->Int->Void;

/*
abstract Complex(Array<Float>) {
	public var real(get, never):Float;
	inline function get_real() return this[0];

	public var imag(get, never):Float;
	inline function get_imag() return this[1];

	public inline function new(real:Float, imag:Float) this = [real, imag];
	public static inline function fromReal(real:Float):Complex return new Complex(real, 0);
	public static inline function exp(w:Float):Complex return new Complex(Math.cos(w), Math.sin(w));

	public var angle(get, never):Float;
	inline function get_angle() return Math.atan2(imag, real);

	public var magnitude(get, never):Float;
	inline function get_magnitude():Float return Math.sqrt(real*real + imag*imag);

	@:op(A + B)
	public inline function add(rhs:Complex):Complex return new Complex(real + rhs.real, imag + rhs.imag);

	@:op(A - B)
	public inline function sub(rhs:Complex):Complex return new Complex(real - rhs.real, imag - rhs.imag);

	@:op(A * B)
	public inline function mult(rhs:Complex):Complex
		return new Complex(real*rhs.real - imag*rhs.imag, real*rhs.imag + imag*rhs.real);

	@:op(A / B)
	public inline function div(rhs:Complex):Complex {
		var m = rhs.magnitude;
		return new Complex((real*rhs.real + imag*rhs.imag) / m, (imag*rhs.real - real*rhs.imag) / m);
	}

	public inline function conj():Complex return new Complex(real, -imag);
}
*/