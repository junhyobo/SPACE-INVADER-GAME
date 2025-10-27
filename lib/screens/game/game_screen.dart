import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' show PointerDeviceKind;

import '../../assets.dart';
import '../../actors/player.dart';
import '../../systems/controller/game_controller.dart';
import '../../util/game_tuning.dart';
import '../../services/sfx_service.dart'; 
import 'game_hud.dart';
import 'game_sprites.dart';
import 'game_overlays.dart';

class GameScreen extends StatefulWidget {
  final String selectedShip;
  final String playerName;

  const GameScreen({
    super.key,
    required this.selectedShip,
    required this.playerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late GameController controller;
  late final Ticker _ticker;

  late DateTime _last;
  double _acc = 0.0;
  static const double _fixedDt = 1.0 / 60.0; // 60Hz
  static const int _maxStepsPerTick = 3;     

  Size? _lastSize;
  bool _started = false;
  final FocusNode _focusNode = FocusNode();

  int? _movePid;
  int? _shootPid;

  Offset? _tapStartPos;
  bool _tapMoved = false;

  @override
  void initState() {
    super.initState();

    FlutterError.onError = (details) {};
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) => true;

    controller = GameController(
      Player(position: const Offset(200, 520)),
      currentShipAsset: widget.selectedShip,
      playerName: widget.playerName,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheAssets(context);
      _focusNode.requestFocus();
    });

    _last = DateTime.now();
    _ticker = createTicker((_) {
      final now = DateTime.now();
      double frameDt = now.difference(_last).inMicroseconds / 1e6;
      _last = now;

      if (frameDt > 0.1) frameDt = 0.1;

      _acc += frameDt;
      int steps = 0;
      while (_acc >= _fixedDt && steps < _maxStepsPerTick) {
        try {
          controller.update(_fixedDt);
        } catch (_) {}
        _acc -= _fixedDt;
        steps++;
      }

      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _precacheAssets(BuildContext context) {
    final toCache = <String>[
      Assets.bg,
      widget.selectedShip,
      Assets.enemyAlien,
      Assets.asteroid,
      Assets.bulletEnemy,
      Assets.bulletPlayer,
      Assets.powerUpBox,
      Assets.fxShieldBreakGif,
      Assets.fxHitGif,
      Assets.fxPickupHealPng,
      Assets.fxPickupAmmoPng,
      Assets.fxPickupShieldPng,
    ];
    for (final p in toCache) {
      precacheImage(AssetImage(p), context);
    }
  }

  void _handleReset() {
    controller.startGame();
    setState(() {});
  }

  void _handleMenu() {
    Navigator.pop(context, {
      'score': controller.score.value,
      'playerName': widget.playerName,
    });
  }

  bool _pointInsidePlayer(Offset p) {
    final s = controller.player.size;
    final c = controller.player.position;
    final r = Rect.fromCenter(
      center: c,
      width:  s.width  * 0.6, // thu nhỏ 60% 
      height: s.height * 0.6,
    );
    return r.contains(p);
  }

 @override
Widget build(BuildContext context) {
  return KeyboardListener(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: (KeyEvent e) {
      if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.space) {
        _handleMenu();
      }
    },
    child: LayoutBuilder(
      builder: (_, constraints) {
        final winSize = Size(constraints.maxWidth, constraints.maxHeight);
        final pad = MediaQuery.viewPaddingOf(context);
        final playSize = Size(
          (winSize.width  - pad.left - pad.right).clamp(0.0, double.infinity),
          (winSize.height - pad.top  - pad.bottom).clamp(0.0, double.infinity),
        );

        GameTuning.setScaleBy(playSize);
        if (_lastSize != playSize) {
          controller.setPlayArea(playSize);
          _lastSize = playSize;
        }
        if (!_started) {
          controller.startGame();
          _started = true;
        }

        return Scaffold(
          body: Padding(
            padding: EdgeInsets.only(
              left: pad.left, right: pad.right, top: pad.top, bottom: pad.bottom,
            ),
            child: Listener(
              behavior: HitTestBehavior.translucent,

              // Chuột: bám tức thời, fire khi giữ trái
              onPointerHover: (e) {
                controller.input.setTarget(e.localPosition, playSize, pad: GameTuning.playerPad);
                controller.input.setMoveActive(true);
              },

              onPointerDown: (e) {
                final pos = e.localPosition;

                if (e.kind == PointerDeviceKind.touch) {
                  // Ngón 1: candidate cho di chuyển hoặc tap-bắn
                  if (_movePid == null) {
                    _movePid = e.pointer;
                    _tapStartPos = pos;
                    _tapMoved = false;   // chưa kéo => chuẩn bị tap
                    return;
                  }
                  // Ngón 2: bắn liên tục khi giữ
                  if (_shootPid == null) {
                    _shootPid = e.pointer;
                    controller.input.setFireActive(true);
                    return;
                  }
                  return;
                }

                if (e.kind == PointerDeviceKind.mouse) {
                  controller.input.setTarget(pos, playSize, pad: GameTuning.playerPad);
                  controller.input.setMoveActive(true);
                  controller.input.setFireActive((e.buttons & 0x01) != 0);
                }
              },

              onPointerMove: (e) {
                final pos = e.localPosition;

                if (e.kind == PointerDeviceKind.touch) {
                  if (_movePid == e.pointer) {
                    if (!_tapMoved && _tapStartPos != null) {
                      final moved = (pos - _tapStartPos!).distance;
                      if (moved > GameTuning.sx(14)) {
                        _tapMoved = true;
                        controller.input.setMoveActive(true);
                      }
                    }
                    if (_tapMoved) {
                      controller.input.setTarget(pos, playSize, pad: GameTuning.playerPad);
                    }
                  }
                  return;
                }

                if (e.kind == PointerDeviceKind.mouse) {
                  controller.input.setTarget(pos, playSize, pad: GameTuning.playerPad);
                  controller.input.setMoveActive(true);
                  controller.input.setFireActive((e.buttons & 0x01) != 0);
                }
              },

              onPointerUp: (e) {
                if (e.kind == PointerDeviceKind.touch) {
                  if (_movePid == e.pointer) {
                
                    if (!_tapMoved && _tapStartPos != null && _shootPid == null && _pointInsidePlayer(_tapStartPos!)) {
                      if (controller.player.canShoot()) {
                        SfxService.I.playShoot();
                        controller.player.shoot(controller.spawn);
                      }
                    }
                    _movePid = null;
                    _tapStartPos = null;
                    _tapMoved = false;
                    controller.input.setMoveActive(false);
                  }
                  if (_shootPid == e.pointer) {
                    _shootPid = null;
                    controller.input.setFireActive(false);
                  }
                  return;
                }

                if (e.kind == PointerDeviceKind.mouse) {
                  controller.input.setFireActive(false);
                }
              },

              onPointerCancel: (e) {
                if (e.kind == PointerDeviceKind.touch) {
                  if (_movePid == e.pointer) {
                    _movePid = null;
                    _tapStartPos = null;
                    _tapMoved = false;
                    controller.input.setMoveActive(false);
                  }
                  if (_shootPid == e.pointer) {
                    _shootPid = null;
                    controller.input.setFireActive(false);
                  }
                } else if (e.kind == PointerDeviceKind.mouse) {
                  controller.input.setFireActive(false);
                }
              },

              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Image.asset(Assets.bg, fit: BoxFit.cover),
                    ),
                  ),
                  GameSprites(controller: controller),
                  GameHUD(controller: controller, onExit: _handleMenu),
                  GameOverlays(
                    controller: controller,
                    onReset: _handleReset,
                    onMenu: _handleMenu,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}
