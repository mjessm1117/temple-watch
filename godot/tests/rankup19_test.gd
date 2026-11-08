extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const OUT = "/home/jess/projects/tw-logs/w19/rankup/"
var checks := 0
var failures := 0
var capture := false

func _initialize() -> void:
    capture = "--capture" in OS.get_cmdline_user_args()
    run.call_deferred()

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("RANKUP19: " + message)

func resize_to(value: Vector2i) -> void:
    DisplayServer.window_set_size(value)
    root.size = value
    root.content_scale_size = value
    await process_frame

func touch(at: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = 0
    event.position = at
    event.pressed = pressed
    root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = 0
    event.position = to
    event.relative = to - from
    root.push_input(event, true)

func shot(label: String) -> void:
    if not capture: return
    for i in 6: await process_frame
    await create_timer(0.2).timeout
    check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "capture " + label)

func screen_for(c, id: String) -> Control:
    var screen := Promotion.new()
    root.add_child(screen)
    screen.setup(c, id)
    for i in 5: await process_frame
    return screen

func within(node: Control, bounds: Vector2) -> bool:
    var rect := node.get_global_rect()
    return rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= bounds.x + 1 and rect.end.y <= bounds.y + 1

func portrait_fits(screen: Control) -> bool:
    var portrait: TextureRect = screen.find_child("UnitPortrait", true, false)
    if portrait.texture == null: return false
    return portrait.texture.get_size().x >= portrait.size.x and portrait.texture.get_size().y >= portrait.size.y

func card_text_fits(card: Control) -> bool:
    var area := card.get_global_rect()
    for label in card.find_children("*", "Label", true, false):
        if label.get_global_rect().end.y > area.end.y - 3: return false
    return true

func run() -> void:
    ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
    var c = Campaign.new()
    var flow = root.get_node("CampaignFlow")
    flow.campaign = c
    flow.active = true
    var jedi: Dictionary = c.soldier("u1")
    jedi.rank = 3
    jedi.picks = ["guardian_deflect", "guardian_brace"]
    jedi.pick = Progression.pending_rank(jedi)
    for value in [Vector2i(667, 375), Vector2i(844, 390), Vector2i(1366, 768)]:
        await resize_to(value)
        var screen := await screen_for(c, "u1")
        check(within(screen, value), "%s full screen bounds" % value)
        check(within(screen.confirm, value), "%s confirm bounds" % value)
        check(within(screen.new_badge, value), "%s badge bounds" % value)
        check(portrait_fits(screen), "%s portrait source covers displayed rect" % value)
        if value.x == 667:
            touch(Vector2(20, 20), true)
            touch(Vector2(20, 20), false)
            check(screen.new_badge.modulate.a == 1.0, "tap skips promotion flourish")
        var card: Button = screen.cards["guardian_soresu_circle"]
        var grid: GridContainer = screen.rank_rows[3].find_child("ChoiceGrid", true, false)
        check(grid.columns == (1 if value.x == 667 else 2), "%s choice columns" % value)
        for choice in screen.cards.values():
            check(card_text_fits(choice), "%s choice text fits card" % value)
            if value.x == 844:
                var bounds: Rect2 = screen.scroll.get_global_rect()
                var rect: Rect2 = choice.get_global_rect()
                check(rect.position.y >= bounds.position.y - 1 and rect.end.y <= bounds.end.y + 1, "844 current rank card fully visible")
        check(card.get_global_rect().position.x >= 0 and card.get_global_rect().end.x <= value.x + 1, "%s choice card horizontal bounds" % value)
        var effect: Label = card.find_child("Effect_guardian_soresu_circle", true, false)
        check(effect.get_global_rect().end.y <= screen.scroll.get_global_rect().end.y + 1, "%s effect line visible" % value)
        check(card.find_children("*", "Label", true, false)[0].get_global_rect().size.y >= 18, "%s ability title legible" % value)
        if value.x == 667: await shot("jedi-knight-667")
        if value.x == 844: await shot("jedi-knight-844")
        screen.queue_free()
        await process_frame
    await resize_to(Vector2i(844, 390))
    var screen := await screen_for(c, "u1")
    var earned: Control = screen.rank_rows[1].find_child("Card_guardian_deflect", true, false)
    check(earned.modulate.a == 1.0, "earned ability remains lit")
    var locked: Control = screen.rank_rows[7]
    check(locked.find_children("*", "Button", true, false).is_empty(), "locked rank has no selectable card")
    screen._select("guardian_citadel_oath")
    check(screen.chosen == "", "locked rank cannot be selected through handler")
    var card: Button = screen.cards["guardian_soresu_circle"]
    var start := card.get_global_rect().get_center()
    var before_drag: int = screen.scroll.scroll_vertical
    touch(start, true)
    var previous := start
    var last_scroll := before_drag
    for i in 8:
        var next := start + Vector2(0, -15 * (i + 1))
        drag(previous, next)
        previous = next
        await process_frame
        check(screen.scroll.scroll_vertical >= last_scroll, "drag never resets scroll position mid-gesture")
        last_scroll = screen.scroll.scroll_vertical
    touch(previous, false)
    await process_frame
    check(screen.scroll.scroll_vertical > before_drag, "drag from card scrolls grid")
    check(screen.chosen == "", "drag from card does not select")
    var scrolled: int = screen.scroll.scroll_vertical
    await process_frame
    check(screen.scroll.scroll_vertical == scrolled, "scroll position stays after drag")
    screen.scroll.scroll_vertical = before_drag
    await process_frame
    var tap_at := card.get_global_rect().get_center()
    touch(tap_at, true)
    touch(tap_at, false)
    await process_frame
    check(screen.chosen == "guardian_soresu_circle" and not screen.confirm.disabled, "tap selects and enables confirm")
    screen.confirm.pressed.emit()
    check(jedi.picks.has("guardian_soresu_circle") and jedi.spec == "a" and jedi.pick == 0, "confirm applies choice through promotion flow")
    screen.queue_free()
    await process_frame
    jedi.xp = 160
    check(Progression.promote(jedi, c.state.roster) and jedi.rank == 4 and jedi.pick == 4, "campaign promotion advances rank and creates next choice")
    screen = await screen_for(c, "u1")
    check(screen.cards.has("guardian_interpose"), "promoted unit returns to rank choice")
    screen.cards["guardian_interpose"].pressed.emit()
    screen.confirm.pressed.emit()
    check(jedi.picks.has("guardian_interpose") and jedi.pick == 0, "existing promotion flow completes end to end")
    screen.queue_free()
    await process_frame
    var soldier: Dictionary = c.soldier("u3")
    soldier.cls = "Trooper"
    soldier.classes = ["trooper"]
    soldier.rank = 2
    soldier.picks = ["trooper_thermal_detonator"]
    soldier.pick = Progression.pending_rank(soldier)
    screen = await screen_for(c, "u3")
    check(portrait_fits(screen), "soldier portrait source covers displayed rect")
    var soldier_image: TextureRect = screen.find_child("UnitPortrait", true, false)
    check(soldier_image.texture is AtlasTexture and soldier_image.texture.region.position.y >= 18, "soldier crop removes magenta top strip")
    var soldier_text := ""
    for label in screen.find_children("*", "Label", true, false): soldier_text += label.text
    check(not soldier_text.contains("NO CHAIN TAG"), "empty chain tag has no developer copy")
    await shot("soldier-844")
    screen.queue_free()
    await process_frame
    for value in [Vector2i(667, 375), Vector2i(1366, 768)]:
        await resize_to(value)
        screen = await screen_for(c, "u3")
        check(portrait_fits(screen), "%s soldier portrait source covers displayed rect" % value)
        screen.queue_free()
        await process_frame
    await resize_to(Vector2i(844, 390))
    jedi.rank = 8
    jedi.spec = "a"
    jedi.picks = ["guardian_deflect", "guardian_brace", "guardian_soresu_circle", "guardian_interpose", "guardian_living_rampart", "guardian_bastion_wave", "guardian_citadel_oath"]
    jedi.pick = Progression.pending_rank(jedi)
    screen = await screen_for(c, "u1")
    await shot("grand-master-844")
    check(screen.cards.has("guardian_grand_aegis"), "Grand Master choice shown")
    screen.queue_free()
    await process_frame
    print("RANKUP19: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
