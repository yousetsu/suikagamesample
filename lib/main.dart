import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:forge2d/forge2d.dart' as forge2d;

///scale
double scale = 10;
///重力
double dbGravity = 20.0 ;//9.8
double width = 0;
double height = 0;
double widthBase = 392.0;
double heightBase = 826.0;
double widthPer = 1;
double heightPer = 1;
double allPer = 1;
double firstSpeed = 40;
double LineY = -135/scale;//境界線 （落とす目安）
double xStart = -171/scale;
double xEnd = 144/scale;
double yStart = -150/scale;
double yEnd = 250/scale;
double yDrop = LineY - (50/scale); //落とす位置

int starRandomNum = 1;
int randomNum = 2;
double certainTime = 0.5;//落とす待ち時間

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final TenkaGame _game = TenkaGame();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])//横回転禁止
      .then((_) {
    runApp(
      GameWidget<TenkaGame>(game: _game,),
    );
  });
}
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: TenkaGame(),
      ),
    );
  }
}

class TenkaGame extends Forge2DGame with TapCallbacks,HasCollisionDetection ,WidgetsBindingObserver{
  TenkaGame() : super(zoom: scale,gravity: Vector2(0, dbGravity));
  final List<ball> ballToRemove = [];
  final List<ball> ballToAdd = [];
  List<ball> allballs = [];
  final Random rng = Random();
  bool tapOK = true;
  int firstType = 1;
  int secondType = 1;
  late TextComponent scoreText;
  int score = 0;
  late TextComponent hiScoreText;
  int hiScore = 0;
  late TextComponent rankText;
  late TextComponent firstText;
  late TextComponent secondText;
  late Offset position;
  double touchX = 0.0;
  double touchY = 0.0;
  Vector2 topLeft = Vector2.zero();
  Vector2 topRight = Vector2.zero();
  Vector2 bottomRight = Vector2.zero();
  Vector2 bottomLeft = Vector2.zero();
  @override
  void dispose() {
  }
  ///バックグラウンドでBGM停止
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
  }
  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final screenWidth = gameSize.x;
    final screenHeight = gameSize.y;
    ///座標の倍率計算
    widthPer = screenWidth / widthBase;
    heightPer = screenHeight / heightBase;
    allPer =  (widthPer + heightPer)/2;
    // 縦横比を使用する処理
  }
  late final CameraComponent cameraComponent;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    WidgetsBinding.instance.addObserver(this);
    await images.loadAll([
      '01.png', '02.png', '03.png', 'underbar.png','verticalbar.png'
    ]);
    firstType =  rng.nextInt(randomNum) + starRandomNum;  // 1～4のランダムな整数
    secondType =  rng.nextInt(randomNum) + starRandomNum;  // 1～4のランダムな整数
    final visibleRect = camera.visibleWorldRect;
    topLeft = visibleRect.topLeft.toVector2();
    topRight = visibleRect.topRight.toVector2();
    bottomRight = visibleRect.bottomRight.toVector2() ;
    bottomLeft = visibleRect.bottomLeft.toVector2();
    ///背景表示
    final bgSprite = await loadSprite('background.png');
    final backgroundSize = canvasSize; // canvasSizeはBaseGameクラスに由来する
    // 画面全体に画像を表示するSpriteComponentを作成
    final backgroundComponent = SpriteComponent(
      sprite: bgSprite,
      position: topLeft,
      size: backgroundSize / scale,
    );
    // ゲームエンジンにコンポーネントを追加
    world.add(backgroundComponent);
     ///下のバー
    await world.add(underBar(gridPosition: Vector2(xStart * widthPer, yEnd * heightPer), xOffset: 0/scale ,xSize: 325/scale *widthPer ,ySize: 10/scale*heightPer));
    ///左のバー
    await world.add(verticalBar(gridPosition: Vector2(xStart * widthPer, yStart * heightPer ), xOffset: 0 ,xSize: 10/scale*widthPer ,ySize: 400/scale*heightPer));
    ///右のバー
    await world.add(verticalBar(gridPosition: Vector2(xEnd * widthPer, yStart * heightPer), xOffset: 0 ,xSize: 10/scale*widthPer ,ySize: 400/scale*heightPer)   );

  }
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    double hitSize = 0.0;
    double typeSize = 0.0;
    double xPosi = 0.0;
    if (!event.handled && tapOK) {
      final touchPoint =  event.canvasPosition;
      touchX = touchPoint.x/scale - bottomRight.x;
      touchY = touchPoint.y/scale - bottomRight.y;
      typeSize = calcTypeSize(firstType ,allPer);
      hitSize =typeSize;
      if(touchX >  xStart  && touchX < xEnd  ) {
        if(touchX >  ( (xStart*widthPer + hitSize/2 + 10/scale*widthPer ))  && touchX < ( xEnd* widthPer - hitSize/2 ) ){
          xPosi = touchX;
        }else if (touchX <=  ( xStart*widthPer + hitSize/2 + 10/scale*widthPer) ){
          xPosi =  (xStart*widthPer + hitSize/2 + 10/scale*widthPer );
        }else if(touchX >= ( xEnd* widthPer - hitSize/2 )  ){
          xPosi = ( xEnd* widthPer - hitSize/2 ) ;
        }else {
          xPosi = touchX;
        }
        world.add(ball(posi:Vector2(xPosi, yDrop*heightPer), type:firstType, typeSize: typeSize, hitSize: hitSize, speed:   firstSpeed, firstTouch:  false));
        tapOK = false;

        ///次のballを決定する
        firstType = secondType;
        secondType = rng.nextInt(randomNum) + starRandomNum;
      }
    }
  }
  @override
  void update(double dt) {
    super.update(dt);
    // 保留されたエンティティの削除
    if (ballToRemove.isNotEmpty) {
      ballToRemove.forEach((ball) {
        ball.removeFromParent();
      });
      ballToRemove.clear();
    }
    // 保留されたエンティティの追加
    if (ballToAdd.isNotEmpty) {
      ballToAdd.forEach(world.add);
      ballToAdd.clear();
    }
  }
  // 衝突検知時に呼ばれるメソッド
  void onballCollision() {
    // tapOKの状態を変更する
    tapOK = true;
  }
}
class ball extends PositionComponent with HasGameRef<TenkaGame>,ContactCallbacks{
  late final SpriteComponent spriteComponent;
  late final BodyComponent bodyComponent;
  final Vector2 posi;
  int type ;
  double typeSize;
  double hitSize;
  double speed ;
  bool firstTouch;
  bool isSpriteLoaded = false; // スプライトの読み込み状態を追跡
  ball({required this.posi, required this.type, required this.typeSize, required this.hitSize, required this.speed, required this.firstTouch}) {
    String strImage = getImagePNG(type);
    _loadSprite(strImage).then((_) {
      gameRef.allballs.add(this); // ballが追加されたときにリストに追加
      _createBody();
      add(spriteComponent); // スプライトコンポーネントを追加
      add(bodyComponent); // ボディコンポーネントを追加
    });
  }
  bool hasCombined = false;
  double timeElapsed = 0.0; // 時間追跡用の変数
  Future<void> _loadSprite(String imagePath) async {
    spriteComponent = SpriteComponent()
      ..sprite = await Sprite.load(imagePath)
      ..anchor = Anchor.center // ここでアンカーを中心に設定
      ..size = Vector2.all(typeSize);
    isSpriteLoaded = true; // スプライトの読み込み完了
  }
  void _createBody() {
    bodyComponent = ballBody(parentball: this, posi: posi, type:type, typeSize: typeSize, hitSize: hitSize, speed: speed, firstTouch: firstTouch);
  }
  @override
  void update(double dt) {
    super.update(dt);
    if (isSpriteLoaded) {
      if (isSpriteLoaded && bodyComponent != null) {
        spriteComponent.position = bodyComponent.body.position;
        spriteComponent.angle = bodyComponent.body.angle;
      }
    }
    if(firstTouch){
      if(bodyComponent.body.position.y + hitSize/2 <=  LineY * heightPer){
        timeElapsed += dt;
        if (timeElapsed > certainTime) {
          timeElapsed = 0.0;
        }
      }else{
        timeElapsed = 0;
      }
    }
  }
  @override
  void onRemove() {
    super.onRemove();
    gameRef.allballs.remove(this); // ballが削除されるときにリストから削除
  }
  @override
  void beginContact(Object other, Contact contact) {
    int newType = 1;
    double newSize = 10.0;
    double newHitSize = 10.0;
    if (other is underBar) {
      if(!firstTouch){
        firstTouch = true;
        gameRef.onballCollision();
      }
    }
    if (other is ball) {
      if (!firstTouch) {
        firstTouch = true;
        gameRef.onballCollision();
      }
      if (other.type == type && !other.hasCombined && !hasCombined) {
        // ballAとballBの現在位置から新しい位置を計算
        Vector2 newPosition = (other.bodyComponent.body.position+ bodyComponent.body.position) / 2;
        hasCombined = true;
        other.hasCombined = true;
        // ballAとballBをゲームから削除
        gameRef.ballToRemove.add(other);
        gameRef.ballToRemove.add(this);
        if (type < 3) {
          newType = type + 1;
          newSize = calcTypeSize(newType, allPer);
          newHitSize = newSize;
          gameRef.ballToAdd.add(ball(posi: newPosition, type: newType, typeSize: newSize, hitSize: newHitSize, speed: 0.0, firstTouch: true));
        }
      }
    }
  }
}
class ballBody extends BodyComponent with ContactCallbacks {
  final ball parentball; // ballのインスタンスを保持
  final Vector2 posi;
  int type ;
  double typeSize;
  double hitSize;
  double speed ;
  bool firstTouch;
  ballBody({required this.parentball, required this.posi,  required this.type,required this.typeSize,required this.hitSize,required this.speed,required this.firstTouch}){
    opacity = 0.0 ;
  }
  bool onGround = false;
  bool onBar = false;
  double prePositionY = 0;
  double timeElapsed = 0.0; // 時間追跡用の変数
  double certainTime = 1.0;
  bool hasCombined = false;
  String strImage = "";
  @override
  Body createBody() {
    final shape = CircleShape()..radius =  (hitSize)  / 2;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.05, //反発係数
      density: 120.0, //密度5.8
      friction: 0.1, //摩擦
    );
    final bodyDef = BodyDef(
      userData: parentball,
      linearVelocity:Vector2(0,speed),
      position: posi, // 初期位置を設定,
      linearDamping:0.1,// 線形減衰の値を設定
      angularDamping:0.3, // 角減衰の値を設定
      type: BodyType.dynamic,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class underBar extends SpriteComponent with HasGameRef<TenkaGame> {
  late forge2d.Body body; // Forge2DのBodyオブジェクト
  final Vector2 gridPosition;
  double xOffset;
  double xSize;
  double ySize;
  final Vector2 velocity = Vector2.zero();

  underBar({
    required this.gridPosition,
    required this.xOffset,
    required this.xSize,
    required this.ySize,
  }) : super(size: Vector2(xSize ,ySize)); // 325,10

  @override
  void onLoad() {
    final platformImage = game.images.fromCache('underbar.png');
    sprite = Sprite(platformImage);
    position = Vector2(gridPosition.x ,gridPosition.y);

    // Forge2D WorldにBodyを追加
    final bodyDef = forge2d.BodyDef()
      ..type = forge2d.BodyType.static
      ..position = forge2d.Vector2(position.x, position.y) // 初期位置を設定
      ..allowSleep = false;
    body = gameRef.world.createBody(bodyDef);

    final shape = PolygonShape()..setAsBox(xSize/2, ySize/2,Vector2(xSize/2,ySize/2,),0);
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.1
      ..friction = 4.0
      ..userData = this;
    body.createFixture(fixtureDef);
  }
}
class verticalBar extends SpriteComponent
    with HasGameRef<TenkaGame> {

  late forge2d.Body body; // Forge2DのBodyオブジェクト
  final Vector2 gridPosition;
  double xOffset;
  double xSize;
  double ySize;
  final Vector2 velocity = Vector2.zero();
  verticalBar({
    required this.gridPosition,
    required this.xOffset,
    required this.xSize,
    required this.ySize,
  }) : super(size: Vector2(xSize ,ySize)); //10,400

  @override
  void onLoad() {
    final platformImage = game.images.fromCache('verticalbar.png');
    sprite = Sprite(platformImage);
    position = Vector2(gridPosition.x ,gridPosition.y);

    // Forge2D WorldにBodyを追加
    final bodyDef = forge2d.BodyDef()
      ..type = forge2d.BodyType.static
      ..position = forge2d.Vector2(position.x, position.y) // 初期位置を設定
      ..allowSleep = false;
    body = gameRef.world.createBody(bodyDef);

    // final shape = PolygonShape()..setAsBoxXY(300, 5);
    final shape = PolygonShape()..setAsBox(xSize/2, ySize/2,Vector2(xSize/2, ySize/2),0);
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.01
      ..friction = 1.0
      ..userData = this;
    body.createFixture(fixtureDef);
  }
}
double calcTypeSize(int type, double per){
  double typeSize = 0.0;
  switch (type) {
    case 1:
      typeSize = 25.0/scale * per;
      break;
    case 2:
      typeSize = 30.0/scale* per;
      break;
    case 3:
      typeSize = 35.0/scale* per;
      break;
    default:
  }
  return typeSize;
}
String getImagePNG(int type){
  String strImage = '';
  switch (type) {
    case 1: // value1に対する処理
      strImage = '01.png';
      break;
    case 2: // value2に対する処理
      strImage = '02.png';
      break;
    case 3: // value2に対する処理
      strImage = '03.png';
      break;
    default:
  }
  return strImage;
}