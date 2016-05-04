//
//  SPHNode.h
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2d.h"
#import "sphFluid.h"
#import "sphSmoke.h"
#import "CCSpriteWaveGenerator.h"


#import "CCRotationStick.h"
#import "CCShiZi.h"
#import "CCDangBan.h"
#import "CCXiTieShi.h"
#import "CCDianFengShan.h"
#import "CCXuanWo.h"


@class DLRenderTexture;
//@class DLRenderTexture2;
//@class DLRenderTexture3;
//@class SPHNode;

extern int nParticles;
extern int nAwakeParticles;
extern int haveAwakeParticlesNum;
extern int fluidPraNum;//当前关卡给与的水滴数量
extern int buddleNum;//气泡个数
extern int lastFallPraticleIndex;//最后一个下落水滴的是索引 为产生平滑水流参数
extern bool isWaitForSmoothFlow;
extern float rad;
extern float visc;
extern float idealRad;
extern float totalMass;
extern cFluidHashList hashGridList[hashWidth][hashHeight];
extern b2Shape *mNeighboursBuffer[nominalNeighbourListLength];
extern int groupID;//簇ID

extern float fpressure;
extern float fpresnear;

//render sprite
extern CCSpriteBatchNode *ParticleBatch;
extern CCSpriteBatchNode *ParticleBatch2;
extern CCSpriteBatchNode *smokeParticleBatch;
extern CCSpriteBatchNode *ParticleBuddleBatch;
extern CCRenderTexture *renderTexture;
extern CCRenderTexture *renderTexture2;
extern SPHNode *gameLayer;

//fluid praticle object array
extern sParticle *liquid;
extern float *vlenBuffer;

//box2d physical
extern b2World *m_world;
extern GLESDebugDraw *m_debugDraw;
extern QueryWorldInteractions *intersectQueryCallback;
extern QueryWorldPostIntersect *eulerIntersectQueryCallback;

extern int vertsNum;//地形线数量
extern b2Vec2 *verts;
//extern b2Vec2 verts[12];//地形指针
extern int vertsNum1;//地形线数量
extern b2Vec2 *verts1;

extern int vertsNum2;//地形线数量
extern b2Vec2 *verts2;

extern int singleVerNum;//两条地形线数量
extern singleVec *singleVers;

extern float collisionFactor;

@interface SPHNode : CCLayer<CCMouseEventDelegate>
{

//    b2World *m_world;
//    QueryWorldInteractions *intersectQueryCallback;
//    QueryWorldPostIntersect *eulerIntersectQueryCallback;
    
//    CCSpriteBatchNode *ParticleBatch;
//    CCSpriteBatchNode *ParticleBatch2;
//    DLRenderTexture *renderTexture;
//    DLRenderTexture *renderTexture2;
    
    int daoju;//1十字 2挡板 3吸铁石 4电风扇 5漩涡
    CCDangBan *dang;
    CCDianFengShan *dfs;
    CCXuanWo *xw;
    CCShiZi *sz;
    CCXiTieShi *xts;
    NSMutableArray *daojuArr;
    
    CCSprite *backgroundSprite;
    CCLabelTTF *scoreLabel;
    GLfloat alphaValueLocation;
    
    //水波滤镜特效
    CCRenderTexture* rippleRender;
    CCSpriteWaveGenerator *swg;
    NSMutableArray *rippleSprArr;
    
    //event varible
    int mousePressedTick;
    
    //记分系统
    int toolsNum;
    int usedToolsNum;
    int result;//-1 fail 0 in game 1 win
    float deltaTime;
    int score;
    int mousePriority;
    
    int colorState;//颜色状态的改变
    
    b2Body *ylBody1;//引流挡板

}

@property(assign,nonatomic) int usedToolsNum;
@property(assign,nonatomic) CCDangBan *dang;
@property(assign,nonatomic) CCDianFengShan *dfs;
@property(assign,nonatomic) CCXuanWo *xw;
@property(assign,nonatomic) CCShiZi *sz;
@property(assign,nonatomic) CCXiTieShi *xts;
@property(assign,nonatomic) int colorState;
@property(assign,nonatomic) b2Body *ylBody1;

+(CCScene *) scene;

//init the UI
-(void)initMenu;

-(void)addDangban:(CGPoint)ps event:(NSEvent*)event;
-(void)addDXF:(CGPoint)ps event:(NSEvent*)event;
-(void)addXW:(CGPoint)ps event:(NSEvent*)event;
-(void)addShiZi:(CGPoint)ps event:(NSEvent*)event;
-(void)addXTS:(CGPoint)ps event:(NSEvent*)event;
-(void)toolsForce;

-(void)updatePhysicalWorld:(float)dt;

//effect
-(void)initRippleRender;
-(void)rippleEffect:(ccTime)dt;
-(void)setColorState:(int)fluidPraticleIndex color:(ccColor3B)color;


-(void)reductionColorState:(int)fluidPraticleIndex;
- (void)drawLiquid;

//碰撞事件处理
-(void)collisionHandle:(b2Body*)body index:(int)fluidPraticleIndex;

//共定义了三套无连接地图边界检测和一套线段边界检测 这个在子类中实现
-(void)addMap;
-(void)addMap1;
-(void)addMap2;
-(void)addSingleMap;

-(int)winJudge;//1 赢 0 正常游戏 －1 输了
-(void)updateUI;
-(int)computeScore;

@end
