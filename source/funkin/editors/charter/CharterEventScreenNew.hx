package funkin.editors.charter;

import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.chart.EventsData;
import funkin.backend.system.Conductor;
import funkin.game.Character;
import funkin.game.Stage;

using StringTools;

class CharterEventScreenNew extends MusicBeatSubstate {
	public var cam:FlxCamera;
	public var chartEvent:CharterEvent;

	public var events:Array<ChartEvent> = [];
	public var eventsList:UIButtonList<EventButtonNew>;

	public var eventName:UIText;

	public var paramsPanel:FlxGroup;
	public var paramsFields:Array<FlxBasic> = [];

	public var xPos:Float;
	public var yPos:Float;

	public var bWidth:Float;

	var bg:UISliceSprite;

	public function new(xPos:Float, yPos:Float, ?chartEvent:Null<CharterEvent>) {
		if (chartEvent != null) this.chartEvent = chartEvent;
		this.xPos = xPos; this.yPos = yPos;
		super();
	}

	public override function create() {
		super.create();

		FlxG.sound.music.pause(); // prevent the song from continuing
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		events = chartEvent.events.copy();

		FlxG.state.persistentUpdate = true;

		camera = cam = new FlxCamera(xPos, yPos, 0, 0);
		cam.bgColor = 0;
		FlxG.cameras.add(cam, false);

		bg = new UISliceSprite(xPos + 100, yPos, 0, 0, 'editors/ui/inputbox');
		bg.alpha = 0.75;
		bg.cameras = [cam];
		cam.x = bg.getScreenPosition(Charter.instance.charterCamera).x;
		cam.y = bg.getScreenPosition(Charter.instance.charterCamera).y;
		bg.setPosition(0, 0);
		add(bg);

		paramsPanel = new FlxGroup();
		paramsPanel.cameras = [cam];
		add(paramsPanel);

		eventName = new UIText(95, 10, 0, "", 24);
		eventName.cameras = [cam];
		add(eventName);

		eventsList = new UIButtonList<EventButtonNew>(10,-20,75, 570, null, FlxPoint.get(75, 40), null, 0);
		eventsList.alpha = 0;
		eventsList.cameras = [cam];
		eventsList.addButton.callback = () -> openSubState(new CharterEventTypeSelection(function(eventName) {
			events.push({
				time: Conductor.getTimeForStep(chartEvent.step),
				params: [],
				name: eventName
			});
			eventsList.add(new EventButtonNew(events[events.length-1], CharterEvent.generateEventIcon(events[events.length-1]), events.length-1, this, eventsList));
			changeTab(events.length-1);
		}));
		for (k=>i in events)
			eventsList.add(new EventButtonNew(i, CharterEvent.generateEventIcon(i), k, this, eventsList));
		add(eventsList);

		changeTab(0);
	}

	public var curEvent:Int = -1;

	public function changeTab(id:Int, save:Bool = true) {
		if (save)
			saveCurTab();

		// destroy old elements
		paramsFields = [];
		for(e in paramsPanel) {
			e.destroy();
			paramsPanel.remove(e);
		}

		if (id >= 0 && id < events.length) {
			curEvent = id;
			var curEvent = events[curEvent];
			eventName.text = curEvent.name;
			// add new elements
			var y:Float = eventName.y + eventName.height + 10;
			for(k=>param in EventsData.getEventParams(curEvent.name)) {
				function addLabel() {
					var label:UIText = new UIText(eventName.x, y, 0, param.name);
					y += label.height + 4;
					paramsPanel.add(label);
				};

				var value:Dynamic = CoolUtil.getDefault(curEvent.params[k], param.defValue);
				var lastAdded = switch(param.type) {
					case TString:
						addLabel();
						var textBox:UITextBox = new UITextBox(eventName.x, y, cast value);
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					case TBool:
						var checkbox = new UICheckbox(eventName.x, y, param.name, cast value);
						paramsPanel.add(checkbox); paramsFields.push(checkbox);
						checkbox;
					case TInt(min, max, step):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x, y, cast value, step.getDefault(1), 0, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TFloat(min, max, step, precision):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x, y, cast value, step.getDefault(1), precision, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TStrumLine:
						addLabel();
						var dropdown = new UIDropDown(eventName.x, y, 320, 32, [for(k=>s in cast(FlxG.state, Charter).strumLines.members) 'Strumline #${k+1} (${s.strumLine.characters[0]})'], cast value);
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					case TColorWheel:
						addLabel();
						var colorWheel = new UIColorwheel(eventName.x, y, value is String ? FlxColor.fromString(value) : Std.int(value));
						paramsPanel.add(colorWheel); paramsFields.push(colorWheel);
						colorWheel;
					case TDropDown(options):
						addLabel();
						var optionIndex = options.indexOf(cast value);
						if(optionIndex < 0) {
							optionIndex = 0;
						}
						var dropdown = new UIDropDown(eventName.x, y, 320, 32, options, optionIndex);
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					case TCharacter:
						addLabel();
						var charFileList = Character.getList(false);
						var textBox:UIAutoCompleteTextBox = new UIAutoCompleteTextBox(eventName.x, y, cast value);
						textBox.suggestItems = charFileList;
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					case TStage:
						addLabel();
						var stageFileList = Stage.getList(false);
						var textBox:UIAutoCompleteTextBox = new UIAutoCompleteTextBox(eventName.x, y, cast value);
						textBox.suggestItems = stageFileList;
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					default:
						paramsFields.push(null);
						null;
				}
				if (lastAdded is UISliceSprite) {
					y += cast(lastAdded, UISliceSprite).bHeight + 4;
					bWidth = Math.max(bWidth, cast(lastAdded, UISliceSprite).bWidth + eventName.x + 10);
				}
				else if (lastAdded is FlxSprite) {
					y += cast(lastAdded, FlxSprite).height + 6;
					bWidth = Math.max(bWidth, cast(lastAdded, UISliceSprite).width + eventName.x + 10);
				}
			}

			y = Math.max(y, eventsList.buttonSize.y * (eventsList.buttons.length + 1));
			
			if (bg.getScreenPosition(Charter.instance.charterCamera).y + y > FlxG.height) {
				var ychange = (bg.getScreenPosition(Charter.instance.charterCamera).y + y) - FlxG.height;
				cam.y -= ychange;
				bg.y -= ychange;
			}

			bg.bWidth = cast bWidth;
			bg.bHeight = cast y + 10;
			cam.width = cast bWidth;
			cam.height = cast y + 10;
			eventsList.bHeight = cast y + 30;
		} else {
			eventName.text = "No event";
			curEvent = -1;
		}
		update(0);
	}

	var clickedWhileHovering = false;
	override public function update(elapsed:Float) {
		var mousepoint = FlxG.mouse.getPositionInCameraView(cam);
		if (FlxG.mouse.justPressed && (FlxMath.inBounds(mousepoint.x, 0, cam.width) && FlxMath.inBounds(mousepoint.y, 0, cam.height))) clickedWhileHovering = true;

		if (FlxMath.inBounds(mousepoint.x, 0, cam.width) && FlxMath.inBounds(mousepoint.y, 0, cam.height)) {
			Charter.instance.shouldScroll = false;
		}
		else if (Charter.instance.curContextMenu == null && ((FlxG.mouse.justReleased && !clickedWhileHovering) || FlxG.mouse.wheel != 0)) {
			Charter.instance.shouldScroll = true;
			quit();
		}
		super.update(elapsed);
		
		if (FlxG.mouse.justReleased) clickedWhileHovering = false;
	}

	public function quit() {
		saveCurTab();
		chartEvent.refreshEventIcons();

		if (events.length <= 0)
			Charter.instance.deleteSelection([chartEvent]);
		else if (events.length > 0) {
			chartEvent.events = [for (i in eventsList.buttons.members) i.event];
			var oldEvents:Array<ChartEvent> = chartEvent.events.copy();
			chartEvent.refreshEventIcons();
			Charter.instance.updateBPMEvents();

			Charter.undos.addToUndo(CEditEvent(chartEvent, oldEvents, [for (event in events) Reflect.copy(event)]));
		}

		close();
	}

	public function saveCurTab() {
		if (curEvent < 0) return;

		events[curEvent].params = [
			for(p in paramsFields) {
				if (p is UIDropDown) {
					var dataParams = EventsData.getEventParams(events[curEvent].name);
					if (dataParams[paramsFields.indexOf(p)].type == TStrumLine) cast(p, UIDropDown).index;
					else cast(p, UIDropDown).label.text;
				}
				else if (p is UINumericStepper) {
					var stepper = cast(p, UINumericStepper);
					@:privateAccess stepper.__onChange(stepper.label.text);
					if (stepper.precision == 0) // int
						Std.int(stepper.value);
					else
						stepper.value;
				}
				else if (p is UITextBox)
					cast(p, UITextBox).label.text;
				else if (p is UICheckbox)
					cast(p, UICheckbox).checked;
				else if (p is UIColorwheel)
					cast(p, UIColorwheel).curColor;
				else
					null;
			}
		];
	}
	public override function destroy() {
		super.destroy();
		FlxG.cameras.remove(cam);
	}
}

class EventButtonNew extends UIButton {
	public var icon:FlxSprite = null;
	public var event:ChartEvent = null;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(event:ChartEvent, icon:FlxSprite, id:Int, substate:CharterEventScreenNew, parent:UIButtonList<EventButtonNew>) {
		this.icon = icon;
		this.event = event;
		super(0, 0, null, function() {
			substate.changeTab(id);
			for(i in parent.buttons.members)
				i.alpha = i == this ? 1 : 0.25;
		}, 73, 40);
		autoAlpha = false;

		members.push(icon);
		icon.setPosition(18 - icon.width / 2, 20 - icon.height / 2);

		deleteButton = new UIButton(bWidth - 30, y + (bHeight - 26) / 2, null, function () {
			substate.events.splice(id, 1);
			substate.changeTab(id, false);
			parent.remove(this);
		}, 26, 26);
		deleteButton.color = FlxColor.RED;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 4).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	override function update(elapsed) {
		super.update(elapsed);

		deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		icon.setPosition(x + (18 - icon.width / 2),y + (20 - icon.height / 2));
		deleteButton.setPosition(x + (bWidth - 30), y + (bHeight - 26) / 2);
		deleteIcon.setPosition(deleteButton.x + (10/2), deleteButton.y + 4);
	}
}