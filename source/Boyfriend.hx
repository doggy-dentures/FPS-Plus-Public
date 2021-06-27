package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{
	public var stunned:Bool = false;
	public var invuln:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
		if (!isModel && !debugMode)
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
			{
				idleEnd();
			}

			if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
			{
				playAnim('deathLoop');
			}
		}
		else if (isModel && !debugMode)
		{
			if (model.currentAnim.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;
		}

		super.update(elapsed);
	}

	override public function idleEnd(?ignoreDebug:Bool = false)
	{
		if (!isModel && (!debugMode || ignoreDebug))
		{
			switch (curCharacter)
			{
				default:
					playAnim('idle', true, false, animation.getByName('idle').numFrames - 1);
			}
		}
		else if (isModel && (!debugMode || ignoreDebug))
		{
			playAnim('idle');
		}
	}

	override public function dance(?ignoreDebug:Bool = false) {

		if (!isModel && (!debugMode || ignoreDebug))
		{
			switch(curCharacter){

				default:
					if (!animation.curAnim.name.startsWith('sing'))
					{
						playAnim('idle', true);
					}

			}
		}
		
	}
}
