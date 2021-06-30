package;

import flixel.util.FlxDestroyUtil;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
//import io.newgrounds.NG;
import lime.app.Application;
import openfl.Assets;
//import polymod.Polymod;

using StringTools;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = true;
	static public var soundExt:String = ".ogg";

	var logoAddTween:FlxTween;
	var logoMonkeyTween:FlxTween;

	override public function create():Void
	{
		//Polymod.init({modRoot: "mods", dirs: ['introMod']});

		// DEBUG BULLSHIT

		super.create();
		FlxG.mouse.visible = false;

		FlxG.save.bind('data', 'dd-monkey');

		Highscore.load();

		if (FlxG.save.data.weekUnlocked != null)
		{
			// FIX LATER!!!
			// WEEK UNLOCK PROGRESSION!!
			// StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;

			if (StoryMenuState.weekUnlocked.length < 4)
				StoryMenuState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!StoryMenuState.weekUnlocked[0])
				StoryMenuState.weekUnlocked[0] = true;
		}

		KeyBinds.keyCheck();
		PlayerSettings.init();

		Main.fpsDisplay.visible = true;

		startIntro();
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var logoAdd:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		Conductor.changeBPM(158);
		persistentUpdate = true;

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = FlxAtlasFrames.fromSparrow('assets/images/logoBumpin.png', 'assets/images/logoBumpin.xml');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		logoAdd = new FlxSprite();
		logoAdd.loadGraphic('assets/images/logoadd.png');
		logoAdd.scale.x = logoAdd.scale.y = 0.6;
		logoAdd.antialiasing = true;
		logoAdd.updateHitbox();
		logoAdd.setPosition(logoBl.x + logoBl.width/2, logoBl.y + logoBl.height/2 + 100);

		var bgGrad:FlxSprite = new FlxSprite().loadGraphic('assets/images/titleBG.png');
		bgGrad.antialiasing = true;
		bgGrad.updateHitbox();

		gfDance = new FlxSprite();
		gfDance.loadGraphic('assets/images/logoMonkey.png');
		gfDance.setPosition(FlxG.width - gfDance.width - 20, FlxG.height * 0.07);
		gfDance.antialiasing = true;

		// gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		// gfDance.frames = FlxAtlasFrames.fromSparrow('assets/images/gfDanceTitle.png', 'assets/images/gfDanceTitle.xml');
		// gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		// gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		// gfDance.antialiasing = true;
		add(bgGrad);
		add(gfDance);
		add(logoBl);
		add(logoAdd);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = FlxAtlasFrames.fromSparrow('assets/images/titleEnter.png', 'assets/images/titleEnter.xml');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		skipIntro();
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if(initialized){
			Conductor.songPosition = FlxG.sound.music.time;
			// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

			if (FlxG.keys.justPressed.F)
			{
				FlxG.fullscreen = !FlxG.fullscreen;
			}

			var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			if (gamepad != null)
			{
				if (gamepad.justPressed.START)
					pressedEnter = true;

				#if switch
				if (gamepad.justPressed.B)
					pressedEnter = true;
				#end
			}

			if (pressedEnter && !transitioning && skippedIntro)
			{
				titleText.animation.play('press');

				FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play('assets/sounds/confirmMenu' + TitleState.soundExt, 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					// Check if version is outdated
					FlxG.switchState(new MainMenuState());
				});
				// FlxG.sound.play('assets/music/titleShoot' + TitleState.soundExt, 0.7);
			}
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		logoBl.animation.play('bump', true);
		danceLeft = !danceLeft;

		if (logoAddTween != null)
			logoAddTween.cancel();
		if (logoMonkeyTween != null)
			logoMonkeyTween.cancel();
		logoAddTween = FlxTween.tween(logoAdd, {"scale.x": 0.61, "scale.y": 0.61}, Conductor.stepCrochet*1/1000, {onComplete: function(_){logoAdd.scale.x = logoAdd.scale.y = 0.6;}});
		logoMonkeyTween = FlxTween.tween(gfDance, {"scale.x": 1.02, "scale.y": 1.02}, Conductor.stepCrochet*1/1000, {onComplete: function(_){gfDance.scale.x = gfDance.scale.y = 1.0;}});

		// if (danceLeft)
		// 	gfDance.animation.play('danceRight', true);
		// else
		// 	gfDance.animation.play('danceLeft', true);

		FlxG.log.add(curBeat);
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 1);
			PlayerSettings.player1.controls.loadKeyBinds();
			Config.configCheck();
			skippedIntro = true;
		}
	}

	override public function destroy()
	{
		FlxDestroyUtil.destroy(logoAddTween);
		FlxDestroyUtil.destroy(logoMonkeyTween);
		super.destroy();
	}
}
