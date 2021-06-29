package;

import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import openfl.media.SoundChannel;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.openal.ALContext;
import lime.utils.UInt8Array;
import lime.media.vorbis.VorbisFile;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALDevice;

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	var timeOld:Float = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var player1DropDown:FlxUIDropDownMenu;
	var player2DropDown:FlxUIDropDownMenu;
	var diffList:Array<String> = ["-easy", "", "-hard"];
	var diffDropFinal:String = "";
	var metronome:FlxUICheckBox;

	// var halfSpeedCheck:FlxUICheckBox;
	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var strumColors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	// var TRIPLE_GRID_SIZE:Float = 40 * 4/3;
	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;
	var gridBG2:FlxSprite;
	var gridBGTriple:FlxSprite;
	var gridBGOverlay:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Int = 0;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var leftIconBack:FlxSprite;
	var rightIconBack:FlxSprite;

	var justChanged:Bool;

	// DD: User-selected pitch value
	var curSelectedPitch:Float = 1.0;
	var curSelectedPitchOffset:Float = 0;
	var curSelectedSyllable:Int = 0;
	var curSelectedVolume:Float = 1.0;

	// DD: Necessary OpenAL sound stuff
	var vorb:VorbisFile = VorbisFile.fromFile("assets/sounds/notepluck.ogg");
	var pluckData:UInt8Array;
	var pluckbuffer:ALBuffer = AL.createBuffer();
	var pluck:ALSource = AL.createSource();

	var dada:SyllableSound;
	var dadi:SyllableSound;
	var dadu:SyllableSound;
	var dade:SyllableSound;
	var dado:SyllableSound;

	var bfa:SyllableSound;
	var bfi:SyllableSound;
	var bfu:SyllableSound;
	var bfe:SyllableSound;
	var bfo:SyllableSound;

	var allSyllableSounds:Array<SyllableSound>;

	var bfSampleMute = false;
	var dadSampleMute = false;

	override function create()
	{
		openfl.Lib.current.stage.frameRate = 120;

		var controlInfo = new FlxText(10, 30, 0,
			"SHIFT - Unlock cursor from grid\nALT - Triplets\nCONTROL - 1/32 Notes\nSHIFT + CONTROL - 1/64 Notes\n\nTAB - Place notes on both sides\n\nR - Top of section\nSHIFT + R - Song start\n\nRight Click - Select note",
			12);
		controlInfo.scrollFactor.set();
		add(controlInfo);

		lastSection = 0;

		var gridBG2Length = 4;

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, GRID_SIZE * 16, true, 0xFFE7E7E7, 0xFFC5C5C5);

		// gridBGTriple = FlxGridOverlay.create(GRID_SIZE, Std.int(GRID_SIZE * 4/3), GRID_SIZE * 8, GRID_SIZE * 16, true, 0xFFE7E7E7, 0xFFC5C5C5);
		// gridBGTriple.visible = false;

		gridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, GRID_SIZE * 16 * gridBG2Length, true, 0xFF515151, 0xFF3D3D3D);

		gridBGOverlay = FlxGridOverlay.create(GRID_SIZE * 4, GRID_SIZE * 4, GRID_SIZE * 8, GRID_SIZE * 16 * gridBG2Length, true, 0xFFFFFFFF, 0xFFB5A5CE);
		gridBGOverlay.blend = "multiply";

		add(gridBG2);
		add(gridBG);
		add(gridBGTriple);
		add(gridBGOverlay);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');

		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.iconScale = 0.5;
		rightIcon.iconScale = 0.5;

		leftIcon.setPosition((GRID_SIZE * 2) - (leftIcon.width / 4), -75);
		rightIcon.setPosition((GRID_SIZE * 2) * 3 - (rightIcon.width / 4), -75);

		leftIconBack = new FlxSprite(leftIcon.x - 2.5, leftIcon.y - 2.5).makeGraphic(75, 75, 0xFF00AAFF);
		rightIconBack = new FlxSprite(rightIcon.x - 2.5, rightIcon.y - 2.5).makeGraphic(75, 75, 0xFF00AAFF);

		add(leftIconBack);
		add(rightIconBack);
		add(leftIcon);
		add(rightIcon);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE * 4).makeGraphic(2, Std.int(gridBG2.height), FlxColor.BLACK);
		add(gridBlackLine);

		for (i in 1...gridBG2Length)
		{
			var gridSectionLine:FlxSprite = new FlxSprite(gridBG.x, gridBG.y + (gridBG.height * i)).makeGraphic(Std.int(gridBG2.width), 2, FlxColor.BLACK);
			add(gridSectionLine);
		}

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false,
				vocalVolume: 1.0
			};
		}

		// DD: Intialize OpenAL sound stuff
		pluckData = SyllableSound.readVorbisFileBuffer(vorb);
		AL.bufferData(pluckbuffer, AL.FORMAT_STEREO16, pluckData, pluckData.length, 44100);
		AL.sourcei(pluck, AL.BUFFER, pluckbuffer);
		dada = new SyllableSound(_song.player2, "a");
		dadi = new SyllableSound(_song.player2, "i");
		dadu = new SyllableSound(_song.player2, "u");
		dade = new SyllableSound(_song.player2, "e");
		dado = new SyllableSound(_song.player2, "o");
		bfa = new SyllableSound(_song.player1, "a");
		bfi = new SyllableSound(_song.player1, "i");
		bfu = new SyllableSound(_song.player1, "u");
		bfe = new SyllableSound(_song.player1, "e");
		bfo = new SyllableSound(_song.player1, "o");
		allSyllableSounds = [dada, dadi, dadu, dade, dado, bfa, bfi, bfu, bfe, bfo];

		FlxG.mouse.visible = true;
		FlxG.save.bind(_song.song.replace(" ", "-"), "Chart Editor Autosaves");

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4, 0xFF0000FF);
		add(strumLine);

		var tabs = [
			{name: "FX", label: 'FX'},
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2 + GRID_SIZE;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEffectUI();
		updateHeads();

		add(curRenderedNotes);
		add(curRenderedSustains);

		super.create();
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		metronome = new FlxUICheckBox(10, 170, null, null, "Note Click", 100);
		metronome.checked = false;

		// halfSpeedCheck = new FlxUICheckBox(10, 170, null, null, "Half Speed", 100);
		// halfSpeedCheck.checked = false;

		var check_mute_vocals = new FlxUICheckBox(10, 225, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_vocals.checked)
				vol = 0;

			vocals.volume = vol;
		};

		var check_bf_sample = new FlxUICheckBox(10, 250, null, null, "Mute Player 1 Samples (in editor)", 100);
		check_bf_sample.checked = false;
		check_bf_sample.callback = function()
		{
			bfSampleMute = false;
			if (check_bf_sample.checked)
			{
				bfSampleMute = true;
			}
		};

		var check_dad_sample = new FlxUICheckBox(10, 275, null, null, "Mute Player 2 Samples (in editor)", 100);
		check_dad_sample.checked = false;
		check_dad_sample.callback = function()
		{
			dadSampleMute = false;
			if (check_dad_sample.checked)
			{
				dadSampleMute = true;
			}
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var fullreset:FlxButton = new FlxButton(10, 150, "Full Blank", function()
		{
			var song_name = _song.song;

			PlayState.SONG = {
				song: song_name,
				notes: [],
				bpm: 120,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false,
				vocalVolume: 1.0
			};

			FlxG.resetState();
		});

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile('assets/data/characterList.txt');

		player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

		player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});

		player2DropDown.selectedLabel = _song.player2;

		var diffDrop:FlxUIDropDownMenu = new FlxUIDropDownMenu(10, 140, FlxUIDropDownMenu.makeStrIdLabelArray(["Easy", "Normal", "Hard"], true),
			function(diff:String)
			{
				trace(diff);
				diffDropFinal = diffList[Std.parseInt(diff)];
			});

		diffDrop.selectedLabel = "Normal";

		// DD: Vocal master volume adjustment
		// var stepperVocalVolumeText:FlxText = new FlxText(10, 100, 0, "Master Vocal Sample Volume", 9);
		var stepperVocalVolume:FlxUINumericStepper = new FlxUINumericStepper(10, 120, 0.1, 1, 0, 1, 2);
		var checkifVolumeNull:Null<Float> = _song.vocalVolume;
		if (checkifVolumeNull == null)
			_song.vocalVolume = 1.0;
		stepperVocalVolume.value = _song.vocalVolume;
		trace(_song.vocalVolume);
		stepperVocalVolume.name = 'song_vocalvolume';

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(check_mute_vocals);
		tab_group_song.add(check_bf_sample);
		tab_group_song.add(check_dad_sample);
		tab_group_song.add(metronome);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(diffDrop);
		// tab_group_song.add(stepperVocalVolumeText);
		tab_group_song.add(stepperVocalVolume);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", swapSections);

		var blankButton:FlxButton = new FlxButton(10, 300, "Full Clear", function()
		{
			for (x in 0..._song.notes.length)
			{
				_song.notes[x].sectionNotes = [];
			}

			updateGrid();
		});

		// Flips BF Notes
		var bSideButton:FlxButton = new FlxButton(10, 200, "Flip BF Notes", function()
		{
			var flipTable:Array<Int> = [3, 2, 1, 0, 7, 6, 5, 4, 8];

			// [noteStrum, noteData, noteSus]
			for (x in _song.notes[curSection].sectionNotes)
			{
				if (_song.notes[curSection].mustHitSection)
				{
					if (x[1] < 4)
						x[1] = flipTable[x[1]];
				}
				else
				{
					if (x[1] > 3)
						x[1] = flipTable[x[1]];
				}
			}

			updateGrid();
		});

		// Flips Opponent Notes
		var bSideButton2:FlxButton = new FlxButton(10, 220, "Flip Opp Notes", function()
		{
			var flipTable:Array<Int> = [3, 2, 1, 0, 7, 6, 5, 4, 8];

			// [noteStrum, noteData, noteSus]
			for (x in _song.notes[curSection].sectionNotes)
			{
				if (_song.notes[curSection].mustHitSection)
				{
					if (x[1] > 3)
						x[1] = flipTable[x[1]];
				}
				else
				{
					if (x[1] < 4)
						x[1] = flipTable[x[1]];
				}
			}

			updateGrid();
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[0].mustHitSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);
		tab_group_section.add(blankButton);
		tab_group_section.add(bSideButton);
		tab_group_section.add(bSideButton2);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var stepperNoteOctave:FlxUINumericStepper;
	var pitchButtons:Array<FlxUIButton>;
	var syllableButtons:Array<FlxUIButton>;
	var stepperNoteVolume:FlxUINumericStepper;

	function pitchButton(xvalue:Int)
	{
		if (curSelectedNote == null)
			return;
		var pitchOffset = 12 * stepperNoteOctave.value;
		var newPitch:Float = Math.pow(Math.pow(2, pitchOffset + xvalue), 1.0 / 12.0);
		curSelectedNote[3] = newPitch;
		updateGrid();
		updateNoteUI();
	}

	function syllableButton(xvalue:Int)
	{
		if (curSelectedNote == null)
			return;
		curSelectedNote[4] = xvalue;
		updateGrid();
		updateNoteUI();
	}

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		var susText = new FlxText(10, 10, 0, "Sustain Length", 9);
		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		var applyLength:FlxButton = new FlxButton(100, 25, 'Apply');

		var pitchText = new FlxText(10, 100, 0, "Note Pitch", 9);
		pitchButtons = [
			new FlxUIButton(10, 150, "C", function()
			{
				pitchButton(0);
			}),
			new FlxUIButton(25, 120, "C#", function()
			{
				pitchButton(1);
			}),
			new FlxUIButton(40, 150, "D", function()
			{
				pitchButton(2);
			}),
			new FlxUIButton(55, 120, "D#", function()
			{
				pitchButton(3);
			}),
			new FlxUIButton(70, 150, "E", function()
			{
				pitchButton(4);
			}),
			new FlxUIButton(100, 150, "F", function()
			{
				pitchButton(5);
			}),
			new FlxUIButton(115, 120, "F#", function()
			{
				pitchButton(6);
			}),
			new FlxUIButton(130, 150, "G", function()
			{
				pitchButton(7);
			}),
			new FlxUIButton(145, 120, "G#", function()
			{
				pitchButton(8);
			}),
			new FlxUIButton(160, 150, "A", function()
			{
				pitchButton(9);
			}),
			new FlxUIButton(175, 120, "A#", function()
			{
				pitchButton(10);
			}),
			new FlxUIButton(190, 150, "B", function()
			{
				pitchButton(11);
			})
		];

		var octaveText = new FlxText(220, 130, 0, "Note Octave", 9);
		stepperNoteOctave = new FlxUINumericStepper(220, 150);
		stepperNoteOctave.name = 'note_octave';

		var syllableText = new FlxText(10, 190, 0, "Syllable", 9);
		syllableButtons = [
			new FlxUIButton(160, 210, "Silent", function()
			{
				syllableButton(-1);
			}),
			new FlxUIButton(10, 210, "A", function()
			{
				syllableButton(0);
			}),
			new FlxUIButton(40, 210, "I", function()
			{
				syllableButton(1);
			}),
			new FlxUIButton(70, 210, "U", function()
			{
				syllableButton(2);
			}),
			new FlxUIButton(100, 210, "E", function()
			{
				syllableButton(3);
			}),
			new FlxUIButton(130, 210, "O", function()
			{
				syllableButton(4);
			})
		];

		var volumeText = new FlxText(10, 250, 0, "Note Volume", 9);
		stepperNoteVolume = new FlxUINumericStepper(10, 270, 0.1, 1, 0, 1, 2);
		stepperNoteVolume.value = 1.0;
		stepperNoteVolume.name = 'note_volume';

		tab_group_note.add(susText);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);
		tab_group_note.add(pitchText);
		tab_group_note.add(octaveText);
		tab_group_note.add(stepperNoteOctave);
		tab_group_note.add(volumeText);
		tab_group_note.add(stepperNoteVolume);
		for (i in pitchButtons)
		{
			i.resize(28, 28);
			i.setLabelFormat(null, 12);
			tab_group_note.add(i);
		}
		tab_group_note.add(syllableText);

		syllableButtons[0].resize(56, 28);
		syllableButtons[0].setLabelFormat(null, 12);
		tab_group_note.add(syllableButtons[0]);
		for (i in 1...syllableButtons.length)
		{
			syllableButtons[i].resize(28, 28);
			syllableButtons[i].setLabelFormat(null, 12);
			tab_group_note.add(syllableButtons[i]);
		}

		UI_box.addGroup(tab_group_note);
	}

	var stepperNoteFXTarget:FlxUINumericStepper;
	var stepperNoteFXType:FlxUINumericStepper;
	var stepperNoteFXVal:FlxUINumericStepper;

	function addEffectUI():Void
	{
		var tab_group_fx = new FlxUI(null, UI_box);
		tab_group_fx.name = 'FX';

		var fxTypeText = new FlxText(10, 130, 0, "FX Type", 9);
		stepperNoteFXType = new FlxUINumericStepper(10, 150, 1, 0, 0);
		stepperNoteFXType.name = 'note_fxtype';

		var fxTargetText = new FlxText(10, 190, 0, "FX Target", 9);
		stepperNoteFXTarget = new FlxUINumericStepper(10, 210, 1, 0, 0, 3);
		stepperNoteFXTarget.name = 'note_fxwho';

		var fxValText = new FlxText(10, 250, 0, "FX Value", 9);
		stepperNoteFXVal = new FlxUINumericStepper(10, 270, 1, 0);
		stepperNoteFXVal.name = 'note_fxval';

		tab_group_fx.add(fxTypeText);
		tab_group_fx.add(stepperNoteFXType);
		tab_group_fx.add(fxTargetText);
		tab_group_fx.add(stepperNoteFXTarget);
		tab_group_fx.add(fxValText);
		tab_group_fx.add(stepperNoteFXVal);

		UI_box.addGroup(tab_group_fx);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(("assets/music/" + daSong + "_Inst.ogg"), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded("assets/music/" + daSong + "_Voices.ogg");
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();
		stopSamples();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			stopSamples();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);
		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
					updateHeads();
					swapSections();

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == "note_octave")
			{
				if (curSelectedNote == null)
					return;
				var xvalue:Int = (Math.round(Math.log(Math.pow(curSelectedNote[3], 12)) / Math.log(2)));
				var noteid:Int = (xvalue % 12 >= 0 ? xvalue % 12 : 12 + xvalue % 12);
				curSelectedNote[3] = Math.pow(Math.pow(2, 12 * nums.value + noteid), 1.0 / 12.0);
			}
			else if (wname == 'song_vocalvolume')
			{
				_song.vocalVolume = nums.value;
				Conductor.mapBPMChanges(_song);
			}
			else if (wname == 'note_volume')
			{
				if (curSelectedNote == null)
					return;
				curSelectedNote[5] = nums.value;
			}
			else if (wname == 'note_fxtype')
			{
				if (curSelectedNote == null || curSelectedNote[1] != 8)
				{
					trace("Naw man");
					return;
				}
				curSelectedNote[3] = nums.value;
			}
			else if (wname == 'note_fxwho')
			{
				if (curSelectedNote == null || curSelectedNote[1] != 8)
				{
					trace("Naw man 2");
					return;
				}
				curSelectedNote[4] = Math.floor(nums.value);
			}
			else if (wname == 'note_fxval')
			{
				if (curSelectedNote == null || curSelectedNote[1] != 8)
				{
					trace("Naw man 3");
					return;
				}
				curSelectedNote[5] = nums.value;
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime():Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum(Conductor.songPosition - sectionStartTime());

		if (curStep >= 16 * (curSection + 1) && FlxG.sound.music.playing)
		{
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				trace("Overlapping Notes");

				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						deleteNote(note);
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote(getStrumTime(dummyArrow.y) + sectionStartTime(), Math.floor(FlxG.mouse.x / GRID_SIZE));
				}
			}
		}

		if (FlxG.mouse.justPressedRight)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						selectNote(note);
					}
				});
			}
		}

		// if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z){

		// }

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT)
				dummyArrow.y = Math.floor(FlxG.mouse.y / (GRID_SIZE / 4)) * (GRID_SIZE / 4);
			else if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else if (FlxG.keys.pressed.ALT)
				dummyArrow.y = Math.floor(FlxG.mouse.y / (GRID_SIZE * 4 / 3)) * (GRID_SIZE * 4 / 3);
			else if (FlxG.keys.pressed.CONTROL)
				dummyArrow.y = Math.floor(FlxG.mouse.y / (GRID_SIZE / 2)) * (GRID_SIZE / 2);
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;

			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();

			FlxG.save.bind('data');

			FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
		{
			changeNoteSustain(Conductor.stepCrochet);
		}
		if (FlxG.keys.justPressed.Q)
		{
			changeNoteSustain(-Conductor.stepCrochet);
		}

		/*if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
		}*/

		if (!typingShit.hasFocus)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
					stopSamples();
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				// && strumLine.y > gridBG.y)
				var wheelSpin = FlxG.mouse.wheel;

				FlxG.sound.music.pause();
				vocals.pause();
				stopSamples();

				if (wheelSpin > 0 && strumLine.y < gridBG.y)
					wheelSpin = 0;

				if (wheelSpin < 0 && strumLine.y > gridBG2.y + gridBG2.height)
					wheelSpin = 0;

				FlxG.sound.music.time -= (wheelSpin * Conductor.stepCrochet * 0.4);

				/*while(strumLine.y < gridBG.y){
						FlxG.sound.music.time += 1;
						Conductor.songPosition = FlxG.sound.music.time;
						strumLine.y = getYfromStrum(Conductor.songPosition - sectionStartTime());
					}
					while(strumLine.y > gridBG2.y + gridBG2.height){
						FlxG.sound.music.time -= 1;
						Conductor.songPosition = FlxG.sound.music.time;
						strumLine.y = getYfromStrum(Conductor.songPosition - sectionStartTime());
				}*/

				vocals.time = FlxG.sound.music.time;
			}

			// DD: Commenting this out for now because I need these keys for pitch shifting.
			// if (!FlxG.keys.pressed.SHIFT)
			// {
			// 	if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			// 	{
			// 		FlxG.sound.music.pause();
			// 		vocals.pause();

			// 		var daTime:Float = 1000 * FlxG.elapsed;

			// 		if (FlxG.keys.pressed.W && strumLine.y > gridBG.y)
			// 		{
			// 			FlxG.sound.music.time -= daTime;
			// 		}
			// 		else if (strumLine.y < gridBG2.y + gridBG2.height)
			// 			FlxG.sound.music.time += daTime;

			// 		vocals.time = FlxG.sound.music.time;
			// 	}
			// }
			// else
			// {
			// 	if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
			// 	{
			// 		FlxG.sound.music.pause();
			// 		vocals.pause();

			// 		var daTime:Float = Conductor.stepCrochet * 2;

			// 		if (FlxG.keys.justPressed.W && strumLine.y > gridBG.y)
			// 		{
			// 			FlxG.sound.music.time -= daTime;
			// 		}
			// 		else if (strumLine.y < gridBG2.y + gridBG2.height)
			// 			FlxG.sound.music.time += daTime;

			// 		vocals.time = FlxG.sound.music.time;
			// 	}
			// }

			// DD: Pitch adjustment keys
			if (FlxG.keys.justPressed.Z)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 0), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.S)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 1), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.X)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 2), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.D)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 3), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.C)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 4), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.V)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 5), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.G)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 6), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.B)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 7), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.H)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 8), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.N)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 9), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.J)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 10), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.M)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 11), 1.0 / 12.0);
				playPluck();
			}
			if (FlxG.keys.justPressed.COMMA)
			{
				curSelectedPitch = Math.pow(Math.pow(2, curSelectedPitchOffset + 12), 1.0 / 12.0);
				playPluck();
			}

			// DD: Octave adjustment keys
			if (FlxG.keys.justPressed.RBRACKET)
			{
				curSelectedPitchOffset += 12;
			}
			if (FlxG.keys.justPressed.LBRACKET)
			{
				curSelectedPitchOffset -= 12;
			}

			// DD: Syllable adjustment keys
			if (FlxG.keys.justPressed.NUMPADONE || FlxG.keys.justPressed.ONE)
			{
				curSelectedSyllable = 0;
			}
			if (FlxG.keys.justPressed.NUMPADTWO || FlxG.keys.justPressed.TWO)
			{
				curSelectedSyllable = 1;
			}
			if (FlxG.keys.justPressed.NUMPADTHREE || FlxG.keys.justPressed.THREE)
			{
				curSelectedSyllable = 2;
			}
			if (FlxG.keys.justPressed.NUMPADFOUR || FlxG.keys.justPressed.FOUR)
			{
				curSelectedSyllable = 3;
			}
			if (FlxG.keys.justPressed.NUMPADFIVE || FlxG.keys.justPressed.FIVE)
			{
				curSelectedSyllable = 4;
			}
			if (FlxG.keys.justPressed.NUMPADSIX || FlxG.keys.justPressed.SIX)
			{
				curSelectedSyllable = -1;
			}

			// DD: Volume adjustment keys
			if (FlxG.keys.justPressed.SEMICOLON)
			{
				if (curSelectedVolume - 0.1 >= 0.0)
					curSelectedVolume -= 0.1;
			}
			if (FlxG.keys.justPressed.QUOTE)
			{
				if (curSelectedVolume + 0.1 <= 1.0)
					curSelectedVolume += 0.1;
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;
		// DD: Commenting out D and A for now because I need them for pitch shifting.
		if (FlxG.keys.justPressed.RIGHT /*|| FlxG.keys.justPressed.D*/)
			changeSection(curSection + shiftThing);
		if (FlxG.keys.justPressed.LEFT /*|| FlxG.keys.justPressed.A*/)
			changeSection(curSection - shiftThing);

		var userSyllable:String = "";
		switch (curSelectedSyllable)
		{
			case -1:
				userSyllable = "Silent";
			case 0:
				userSyllable = "A";
			case 1:
				userSyllable = "I";
			case 2:
				userSyllable = "U";
			case 3:
				userSyllable = "E";
			case 4:
				userSyllable = "O";
		}

		var userPitch:String = "";
		var xvalue:Int = (Math.round(Math.log(Math.pow(curSelectedPitch, 12)) / Math.log(2)));
		var octavevalue = Math.floor(xvalue / 12);
		var pitchvalue = (xvalue % 12 >= 0 ? xvalue % 12 : xvalue % 12 + 12);

		switch (pitchvalue)
		{
			case 0:
				userPitch += "C";
			case 1:
				userPitch += "C#";
			case 2:
				userPitch += "D";
			case 3:
				userPitch += "D#";
			case 4:
				userPitch += "E";
			case 5:
				userPitch += "F";
			case 6:
				userPitch += "F#";
			case 7:
				userPitch += "G";
			case 8:
				userPitch += "G#";
			case 9:
				userPitch += "A";
			case 10:
				userPitch += "A#";
			case 11:
				userPitch += "B";
		}
		userPitch = userPitch + " " + octavevalue + " (" + Math.floor(curSelectedPitch * 1000) / 1000.0 + ")";

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection
			+ "\nPending Pitch: "
			+ userPitch
			+ "\nPending Octave: "
			+ curSelectedPitchOffset / 12
			+ "\nPending Syllable: "
			+ userSyllable
			+ "\nPending Volume: "
			+ curSelectedVolume;

		// || FlxG.keys.justPressed.X  || FlxG.keys.justPressed.C || FlxG.keys.justPressed.V

		// DD: Commenting this for now because I need these keys
		// if(FlxG.sound.music.playing){

		// 	if(FlxG.keys.justPressed.Z || FlxG.keys.justPressed.H)
		// 		addNote(getStrumTime(Math.floor((strumLine.y + strumLine.height) / GRID_SIZE) * GRID_SIZE) + sectionStartTime(), 0 + (_song.notes[curSection].mustHitSection ? 4 : 0));

		// 	if(FlxG.keys.justPressed.X || FlxG.keys.justPressed.J)
		// 		addNote(getStrumTime(Math.floor((strumLine.y + strumLine.height) / GRID_SIZE) * GRID_SIZE) + sectionStartTime(), 1 + (_song.notes[curSection].mustHitSection ? 4 : 0));

		// 	if(FlxG.keys.justPressed.N || FlxG.keys.justPressed.K)
		// 		addNote(getStrumTime(Math.floor((strumLine.y + strumLine.height) / GRID_SIZE) * GRID_SIZE) + sectionStartTime(), 2 + (_song.notes[curSection].mustHitSection ? 4 : 0));

		// 	if(FlxG.keys.justPressed.M || FlxG.keys.justPressed.L)
		// 		addNote(getStrumTime(Math.floor((strumLine.y + strumLine.height) / GRID_SIZE) * GRID_SIZE) + sectionStartTime(), 3 + (_song.notes[curSection].mustHitSection ? 4 : 0));

		// }

		if (metronome.checked && !justChanged)
		{
			curRenderedNotes.forEach(function(x:Note)
			{
				if (x.y < strumLine.y && !x.playedEditorClick && FlxG.sound.music.playing)
				{
					FlxG.sound.play("assets/sounds/tick.ogg", 0.6);
				}

				if (x.y > strumLine.y && x.alpha != 0.4)
				{
					x.playedEditorClick = false;
				}

				if (x.y < strumLine.y && x.alpha != 0.4)
				{
					x.playedEditorClick = true;
				}
			});
		}

		justChanged = false;

		if (FlxG.sound.music.playing)
		{
			for (note in curRenderedNotes)
			{
				if (note.strumTime - Conductor.songPosition <= 0 && note.strumTime - Conductor.songPosition > -60 && !note.tooLate)
				{
					// DD: Play those vocal samples
					if (!dadSampleMute && note.x <= GRID_SIZE * 3)
					{
						PlayState.handleVocalPlayback(note, dada, dadi, dadu, dade, dado);
					}
					else if (!bfSampleMute && note.x > GRID_SIZE * 3)
					{
						PlayState.handleVocalPlayback(note, bfa, bfi, bfu, bfe, bfo);
					}

					note.tooLate = true;
				}
			}
		}

		super.update(elapsed);

		// DD: Update vocal samples
		for (i in allSyllableSounds)
		{
			if (i.isInUse())
				i.update(FlxG.elapsed * 1000, false);
		}
		if (FlxG.sound.muted)
			AL.sourcef(pluck, AL.GAIN, 0);
		else
			AL.sourcef(pluck, AL.GAIN, FlxG.sound.volume);
	}

	// DD: Plays pluck sound so you know what pitch you selected
	function playPluck()
	{
		AL.sourcef(pluck, AL.PITCH, curSelectedPitch);
		AL.sourcePlay(pluck);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();
		stopSamples();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		justChanged = true;

		trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			curSection = sec;
			curSelectedNote = null;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				stopSamples();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
			updateNoteUI();
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4], note[5]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		leftIcon.animation.play(player2DropDown.selectedLabel);
		rightIcon.animation.play(player1DropDown.selectedLabel);

		if (_song.notes[curSection].mustHitSection)
		{
			leftIconBack.alpha = 0;
			rightIconBack.alpha = 1;
		}
		else
		{
			leftIconBack.alpha = 1;
			rightIconBack.alpha = 0;
		}
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null && curSelectedNote[1] != 8)
		{
			stepperSusLength.value = curSelectedNote[2];
			// DD: UI for pitch shift buttons
			var xvalue:Int = (Math.round(Math.log(Math.pow(curSelectedNote[3], 12)) / Math.log(2)));
			for (i in 0...pitchButtons.length)
			{
				if (((xvalue % 12 >= 0 ? xvalue % 12 : 12 + xvalue % 12) == i))
					pitchButtons[i].setLabelFormat(null, 12, FlxColor.RED);
				else
					pitchButtons[i].setLabelFormat(null, 12, FlxColor.BLACK);
			}
			stepperNoteOctave.visible = true;
			stepperNoteOctave.value = Math.floor(xvalue / 12);
			// DD: UI for syllable buttons
			for (i in -1...5)
			{
				if (curSelectedNote[4] == i)
					syllableButtons[i + 1].setLabelFormat(null, 12, FlxColor.RED);
				else
					syllableButtons[i + 1].setLabelFormat(null, 12, FlxColor.BLACK);
			}
			// DD: UI for note volume
			stepperNoteVolume.visible = true;
			stepperNoteVolume.value = curSelectedNote[5];
		}
		else
		{
			for (i in syllableButtons)
				i.setLabelFormat(null, 12, FlxColor.WHITE);
			for (i in pitchButtons)
				i.setLabelFormat(null, 12, FlxColor.WHITE);
			stepperNoteOctave.visible = false;
			stepperNoteVolume.visible = false;
		}
		updateFXUI();
	}

	function updateFXUI()
	{
		if (curSelectedNote != null && curSelectedNote[1] == 8)
		{
			stepperNoteFXType.visible = true;
			stepperNoteFXTarget.visible = true;
			stepperNoteFXVal.visible = true;
			stepperNoteFXType.value = curSelectedNote[3];
			stepperNoteFXTarget.value = curSelectedNote[4];
			stepperNoteFXVal.value = curSelectedNote[5];
		}
		else
		{
			stepperNoteFXType.visible = false;
			stepperNoteFXTarget.visible = false;
			stepperNoteFXVal.visible = false;
		}
	}

	function updateGrid():Void
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Int = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in 0...4)
		{
			// trace(_song.notes[curSection + i] != null);

			if (_song.notes[curSection + i] != null)
				addNotesToRender(curSection, i);
		}
	}

	private function addNotesToRender(curSec:Int, ?secOffset:Int = 0)
	{
		var section:Array<Dynamic> = _song.notes[curSec + secOffset].sectionNotes;
		var noteAdjust:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8];

		if (_song.notes[curSec + secOffset].mustHitSection)
		{
			noteAdjust = [4, 5, 6, 7, 0, 1, 2, 3, 8];
		}

		for (i in section)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			// DD: Adding pitch and syllable and note volume stuff
			if (i[3] == null)
				i[3] = 1.0;
			if (i[4] == null)
				i[4] = -1;
			if (i[5] == null)
				i[5] = 1.0;
			var daPitch = i[3];
			var daSyllable = i[4];
			var daVolume = i[5];

			var note:Note = new Note(daStrumTime, daNoteInfo % 4, true);
			note.absoluteNumber = daNoteInfo;
			note.sustainLength = daSus;

			note.notePitch = daPitch;
			note.noteSyllable = daSyllable;
			note.noteVolume = daVolume;

			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();

			note.x = Math.floor(noteAdjust[daNoteInfo] * GRID_SIZE);

			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));
			note.y += GRID_SIZE * 16 * secOffset;

			if (secOffset > 0)
				note.alpha = 0.4;

			curRenderedNotes.add(note);

			if (curSelectedNote != null && curSelectedNote[1] == daNoteInfo && curSelectedNote[0] == daStrumTime && curSelectedNote[2] == daSus)
			{
				note.blend = DARKEN;
			}

			if (daSus > 1)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2) - 4,
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)),
					strumColors[daNoteInfo % 4]);
				if (secOffset > 0)
					sustainVis.alpha = 0.4;
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] < note.strumTime + 0.01 && i[0] > note.strumTime - 0.01 && i[1] == note.absoluteNumber)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		// trace('Trying: ' + note.strumTime);

		for (i in _song.notes[curSection].sectionNotes)
		{
			// trace("Testing: " + i[0]);
			if (i[0] < note.strumTime + 0.01 && i[0] > note.strumTime - 0.01 && i[1] == note.absoluteNumber)
			{
				// trace('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(_noteStrum:Float, _noteData:Int):Void
	{
		var noteAdjust:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8];

		if (_song.notes[curSection].mustHitSection)
		{
			noteAdjust = [4, 5, 6, 7, 0, 1, 2, 3, 8];
		}

		var noteData = noteAdjust[_noteData];
		var noteStrum = _noteStrum;
		var noteSus = 0;

		// DD: Added note pitch stuff here too
		_song.notes[curSection].sectionNotes.push([
			noteStrum,
			noteData,
			noteSus,
			curSelectedPitch,
			curSelectedSyllable,
			curSelectedVolume
		]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.TAB && noteData != 8)
		{
			_song.notes[curSection].sectionNotes.push([
				noteStrum,
				(noteData + 4) % 8,
				noteSus,
				curSelectedPitch,
				curSelectedSyllable,
				curSelectedVolume
			]);
		}

		trace(noteStrum);
		trace(curSection);

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;
			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;
				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;
				daLength += swagLength;
				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}
			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase() + diffDropFinal, song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + diffDropFinal + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function swapSections()
	{
		for (i in 0..._song.notes[curSection].sectionNotes.length)
		{
			var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
			if (note[1] < 8)
				note[1] = (note[1] + 4) % 8;
			_song.notes[curSection].sectionNotes[i] = note;
			updateGrid();
		}
	}

	override function beatHit()
	{
		super.beatHit();
	}

	override function switchTo(nextState:FlxState):Bool
	{
		stopSamples();
		return super.switchTo(nextState);
	}

	override public function destroy()
	{
		for (i in 0...allSyllableSounds.length)
		{
			allSyllableSounds[i].delete();
		}
		allSyllableSounds.resize(0);
		AL.sourceStop(pluck);
		AL.deleteSource(pluck);
		AL.deleteBuffer(pluckbuffer);
		super.destroy();
	}

	function stopSamples()
	{
		for (i in allSyllableSounds)
		{
			i.stop();
			// i.loopOff();
		}
	}
}
