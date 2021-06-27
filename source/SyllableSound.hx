package;

import lime.media.vorbis.VorbisInfo;
import lime.utils.ArrayBuffer;
import flixel.FlxG;
import lime.media.openal.AL;
import haxe.io.Bytes;
import lime.utils.UInt8Array;
import lime.media.vorbis.VorbisFile;
import sys.FileSystem;
import lime.media.openal.ALSource;
import lime.media.openal.ALBuffer;

class SyllableSound
{
	var buffer:ALBuffer = AL.createBuffer();
	// DD: Three sources to cycle through if one is still playing when we need to start the syllable again.
	// Otherwise, the source's sound gets cut off without fading out and causes an audible crackle.
	var sources:Array<ALSource> = [AL.createSource(), AL.createSource(), AL.createSource()];
	var volume:Float = 1.0;
	var inUse:Array<Bool> = [false, false, false];
	var fadingNow:Array<Bool> = [false, false, false];
	var currentSource:Int = 0;
	var isPaused:Bool = false;
	var ttl:Float = 0;

	public function new(playerName:String, syllable:String, loop:Bool = true)
	{
		var vorb:VorbisFile;
		if (FileSystem.exists("assets/shared/sounds/voices/" + playerName + "/" + syllable + ".ogg"))
		{
			vorb = VorbisFile.fromFile("assets/shared/sounds/voices/" + playerName + "/" + syllable + ".ogg");
		}
		else
		{
			// vorb = VorbisFile.fromFile("assets/shared/sounds/notepluckhold.ogg");
			vorb = VorbisFile.fromFile("assets/shared/sounds/voices/test/" + syllable + ".ogg");
		}
		var sndData = readVorbisFileBuffer(vorb);
		var vorbInfo:VorbisInfo = vorb.info();
		var vorbChannels = AL.FORMAT_STEREO16;
		if (vorbInfo.channels <= 1)
			vorbChannels = AL.FORMAT_MONO16;
		var vorbRate = vorbInfo.rate;

		AL.bufferData(buffer, vorbChannels, sndData, sndData.length, vorbRate);
		for (i in sources)
		{
			AL.sourcei(i, AL.BUFFER, buffer);
		}
		if (loop)
			loopOn();
	}

	public function play(length:Float = 0)
	{
		if (inUse[currentSource] || fadingNow[currentSource])
			currentSource = (currentSource + 1) % sources.length;

		AL.sourcei(sources[currentSource], AL.GAIN, Conductor.masterVolume * volume * FlxG.sound.volume);
		AL.sourcePlay(sources[currentSource]);
		inUse[currentSource] = true;
		fadingNow[currentSource] = false;
		setTime(length);

		// DD: OpenAL got some jank that causes sounds to stop suddenly.
		sys.thread.Thread.create(() ->
		{
			var thisSource = currentSource;
			while (inUse[thisSource])
			{
				if (AL.getSourcei(sources[currentSource], AL.SOURCE_STATE) == AL.STOPPED)
				{
					AL.sourcePlay(sources[currentSource]);
				}
			}
		});
	}

	public function update(elasped:Float, gamePaused:Bool)
	{
		refreshVolume();
		if (gamePaused)
			stop();
		else
			decreaseTime(elasped);

		if (ttl <= 0)
		{
			stop();
		}
	}

	public function setTime(newttl:Float)
	{
		ttl = newttl;
	}

	public function decreaseTime(time:Float)
	{
		ttl -= time;
	}

	// DD: Stopping a sound mid-play can cause a crackle noise.
	// This makes a sound progressively fade to silence in 50ms.
	public function stop()
	{
		if (inUse[currentSource])
		{
			AL.sourcei(sources[currentSource], AL.GAIN, 0);
			inUse[currentSource] = false;
			ttl = 0;
			fadingNow[currentSource] = true;
			var sourcetoStop:Int = currentSource;
			haxe.Timer.delay(function()
			{
				if (!inUse[sourcetoStop])
				{
					AL.sourceStop(sources[sourcetoStop]);
					fadingNow[sourcetoStop] = false;
				}
			}, 50);
		}
	}

	// DD: Don't call this unless the syllablesound is about to discarded.
	public function forceStop()
	{
		inUse[currentSource] = false;
		fadingNow[currentSource] = false;
		AL.sourceStop(sources[currentSource]);
	}

	public function setVolume(vol:Float)
	{
		volume = vol;
	}

	public function refreshVolume()
	{
		for (i in 0...sources.length)
		{
			if (FlxG.sound.muted)
				AL.sourcef(sources[i], AL.GAIN, 0);
			else if (inUse[i])
				AL.sourcef(sources[i], AL.GAIN, Conductor.masterVolume * volume * FlxG.sound.volume);
		}
	}

	public function loopOn()
	{
		for (source in sources)
			AL.sourcei(source, AL.LOOPING, 1);
	}

	public function loopOff()
	{
		for (source in sources)
			AL.sourcei(source, AL.LOOPING, 0);
	}

	public function setPitch(pitch:Float)
	{
		for (source in sources)
			AL.sourcef(source, AL.PITCH, pitch);
	}

	public function pause()
	{
		AL.sourcePause(sources[currentSource]);
		isPaused = true;
	}

	public function resume()
	{
		if (isPaused)
			AL.sourcePlay(sources[currentSource]);
	}

	// DD: Delete this thing. May cause memory leaks. Needs more testing.
	public function delete()
	{
		forceStop();
		AL.deleteSources(sources);
		AL.deleteBuffer(buffer);
	}

	// DD: Anything outside doesn't need to know we have multiple sources and inUse values.
	// All that needs to be known is if a sound is playing.
	public function isInUse():Bool
	{
		var returnval:Bool = false;
		for (i in 0...sources.length)
		{
			if (inUse[i])
				returnval = true;
		}
		return returnval;
	}

	// DD: Reads an .ogg or something. It's not the most efficient, but this only runs at level start.
	public static function readVorbisFileBuffer(vorbisFile:VorbisFile):UInt8Array
	{
		var length = Std.int(vorbisFile.bitrate() * vorbisFile.timeTotal() * vorbisFile.info().rate/10000);
		var buffer = Bytes.alloc(length);
		var read = 0, total = 0, readMax;

		while (total < length)
		{
			readMax = 4096;

			if (readMax > length - total)
			{
				readMax = length - total;
			}

			read = vorbisFile.read(buffer, total, readMax);

			if (read > 0)
			{
				total += read;
			}
			else
			{
				break;
			}
		}

		var realbuffer = new UInt8Array(total);
		realbuffer.buffer.blit(0, buffer, 0, total);

		return realbuffer;
	}
}
