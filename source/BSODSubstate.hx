package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class BSODSubstate extends FlxSubState
{

    private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

    var skippable:Bool = false;
    var bsod:FlxSprite;

	override function create()
    {
        super.create();
        bsod = new FlxSprite().loadGraphic('assets/images/bsod.png');
        bsod.scrollFactor.x = 0;
        bsod.scrollFactor.y = 0;
        add(bsod);
        FlxG.sound.play('assets/sounds/bsod' + TitleState.soundExt);
        new FlxTimer().start(3, function(tmr:FlxTimer)
        {
            skippable = true;
        });
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (skippable && (controls.ACCEPT || controls.BACK))
		{
            FlxG.sound.playMusic("assets/music/klaskiiLoop.ogg", 0.75);
			FlxG.switchState(new StoryMenuState());
		}

	}

}
