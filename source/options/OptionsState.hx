package options;

#if desktop
import DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class OptionsState extends MusicBeatState
{

	var kId = 0;
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Optimization', 'Game Rendering', 'Visuals and UI', 'Gameplay', 'Misc'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	public var enteringDebugMenu:Bool = false;
	private var mainCamera:FlxCamera;
	private var subCamera:FlxCamera;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Optimization':
				openSubState(new options.OptimizationSubState());
			case 'Game Rendering':
				openSubState(new options.GameRendererSettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(() -> new options.NoteOffsetState());
			case 'Misc':
				openSubState(new options.MiscSettingsSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		mainCamera = new FlxCamera();
		subCamera = new FlxCamera();
		subCamera.bgColor.alpha = 0;

		FlxG.cameras.reset(mainCamera);
		FlxG.cameras.add(subCamera, false);

		FlxG.cameras.setDefaultDrawTarget(mainCamera, true);
		CustomFadeTransition.nextCamera = subCamera;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.follow(camFollowPos, null, 1);

		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var yScroll:Float = Math.max(0.25 - (0.05 * (options.length - options.length)), 0.1);
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.scrollFactor.set(0, 0);

		bg.screenCenter();
		bg.y -= 5;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.scrollFactor.set(0, yScroll*1.5);
			grpOptions.add(optionText);
		}
		//I TOOK THIS FROM THE MAIN MENU STATE, NOT FROM DENPA ENGINE
		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scrollFactor.set(0, yScroll*1.5);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scrollFactor.set(0, yScroll*1.5);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(PauseSubState.inPause)
			{
				PauseSubState.inPause = false;
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(PlayState.new);
				FlxG.sound.music.volume = 0;
			}
			else FlxG.switchState(MainMenuState.new);
		}
		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			var thing:Float = 0;
			if (item.targetY == 0) {
				item.alpha = 1;
				if(grpOptions.members.length > 4) {
					thing = grpOptions.members.length * 8;
				}
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y - thing);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}