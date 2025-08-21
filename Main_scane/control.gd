extends Control
class_name PWAInstaller

@export var install_button_path: NodePath = NodePath()
var _install_button: Button

var _poll_timer := 0.0
var _ios_hint_shown := false

func _ready() -> void:
	if !OS.has_feature("web"):
		return

	# найдём кнопку (если путь указан)
	if install_button_path != NodePath():
		_install_button = get_node_or_null(install_button_path)
		if _install_button:
			_install_button.pressed.connect(_on_install_pressed)

	# JS окружение + iOS детект и утилиты
	JavaScriptBridge.eval("""
		window._pwaState = {
		  deferred: null,
		  supported: false,
		  installed: (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true)
		};

		window.addEventListener('beforeinstallprompt', (e) => {
		  e.preventDefault();
		  window._pwaState.deferred = e;
		  window._pwaState.supported = true;
		});

		window.addEventListener('appinstalled', () => {
		  window._pwaState.installed = true;
		});

		const isIOS = () => /iphone|ipad|ipod/i.test(navigator.userAgent) ||
			(navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

		window.godotPWA = {
		  isStandalone: () => (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true),
		  isInstalled:  () => !!window._pwaState.installed,
		  isIOS:        () => isIOS(),
		  canInstall:   () => (!!window._pwaState.deferred && !window._pwaState.installed),
		  isSupported:  () => (window._pwaState.supported || 'BeforeInstallPromptEvent' in window),
		  install: async () => {
			const ev = window._pwaState.deferred;
			if (!ev) return 'no_prompt';
			window._pwaState.deferred = null;
			try {
			  ev.prompt();
			  const choice = await ev.userChoice;
			  return (choice && choice.outcome) ? choice.outcome : 'unknown';
			} catch (err) {
			  return 'error:' + err;
			}
		  }
		};
	""", true)

	_update_button_visibility(true)

func _process(delta: float) -> void:
	if !OS.has_feature("web"):
		return
	_poll_timer += delta
	if _poll_timer >= 0.5:
		_poll_timer = 0.0
		_update_button_visibility()

func _update_button_visibility(force := false) -> void:
	if !_install_button:
		return

	var standalone  = JavaScriptBridge.eval("window.godotPWA.isStandalone()", true)
	var can_install = JavaScriptBridge.eval("window.godotPWA.canInstall()", true)
	var is_ios      = JavaScriptBridge.eval("window.godotPWA.isIOS()", true)
	var is_installed= JavaScriptBridge.eval("window.godotPWA.isInstalled()", true)

	# Правила:
	# 1) Если уже standalone/installed — скрываем.
	# 2) Если есть реальный beforeinstallprompt — показываем обычную кнопку.
	# 3) На iOS (нет prompt’а) показываем кнопку-«подсказку».
	if bool(standalone) or bool(is_installed):
		_install_button.visible = false
		return

	if bool(can_install):
		_install_button.visible = true
		if _install_button.text == "" or _install_button.text.begins_with("Добавить"):
			_install_button.text = "Установить приложение"
	else:
		# iOS режим — показать кнопку, которая откроет help
		if bool(is_ios):
			_install_button.visible = true
			if _install_button.text == "" or _install_button.text.begins_with("Установить"):
				_install_button.text = "Добавить на Домой (iOS)"
			# Можно один раз авто-подсказать без клика, если нужно:
			if !_ios_hint_shown:
				_ios_hint_shown = true
				_show_ios_help()
		else:
			_install_button.visible = false

func _on_install_pressed() -> void:
	var can_install = JavaScriptBridge.eval("window.godotPWA.canInstall()", true)
	var is_ios      = JavaScriptBridge.eval("window.godotPWA.isIOS()", true)

	if bool(can_install):
		var result = JavaScriptBridge.eval("window.godotPWA.install()", true)
		match str(result):
			"accepted":
				_install_button.visible = false
			"dismissed":
				pass
			"no_prompt":
				_show_ios_help()
			_:
				if str(result).begins_with("error:"):
					push_warning("PWA install error: %s" % result)
	elif bool(is_ios):
		_show_ios_help()
	else:
		# Не iOS и нет prompt — значит условия PWA не выполнены (манифест/СВ/HTTPS/иконки)
		_show_generic_help()

func _show_ios_help() -> void:
	_show_toast("iOS: откройте меню «Поделиться» и выберите «На экран “Домой”».")

func _show_generic_help() -> void:
	_show_toast("Нужно: HTTPS, валидный webmanifest, Service Worker и иконки. Тогда появится кнопка установки.")

func _show_toast(msg: String, seconds: float = 4.0) -> void:
	var label := Label.new()
	label.text = msg
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.theme_type_variation = "HeaderSmall"
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0,0,0,0.7))
	label.add_theme_constant_override("outline_size", 2)

	# фон
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _toast_stylebox())
	panel.add_child(label)

	# разместим как тост внизу по центру
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_bottom = 1.0
	panel.anchor_top = 1.0
	panel.offset_bottom = -24
	panel.offset_top = -96

	var parent := get_tree().current_scene if get_tree().current_scene else self
	parent.add_child(panel)
	panel.top_level = true

	await get_tree().create_timer(seconds).timeout
	panel.queue_free()

func _toast_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0,0,0,0.8)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb
