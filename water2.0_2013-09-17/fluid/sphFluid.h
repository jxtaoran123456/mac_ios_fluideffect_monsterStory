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
#import "FluidHashList.h"
#import "GLES-Render.h"

#include <iostream>
#include <vector>
#include <stdlib.h>

//#define m_world->GetGravity() world_g
//m_world->GetGravity()


@class DLRenderTexture;
@class SPHNode;
//@class DLRenderTexture2;
//@class DLRenderTexture3;

// SPH node for simulating Smoothed-Particle hydrodynamics
// Individual particles are stored as struct, to keep things as simple as possible

// Everything is just a copy-paste of the ElectroDruid code from this post: http://www.box2d.org/forum/viewtopic.php?f=3&t=574&sid=0f208bac89ee07a05d5a524ef3b652cc&start=70

//#define VERLET_INTEGRATION

using namespace std;

//#define VERLET_INTEGRATION 1
//#define nParticles		(1000)
#define hashWidth		(100)//25   这里其实表示的是有多少列 128 32 128
#define hashHeight		(100)//40   表示有多少行 和矩阵正好相反 64 16 64
#define PTM_RATIO 32.f

#define eps 1e-8
#define zero(x) (((x)>0?(x):-(x))<eps)
#define zOrder -100


#define buddleVelocity 0.f

const int nominalNeighbourListLength = 256;

struct sParticle
{
	sParticle() : mPosition(0,0), mOldPosition(0,0), mVelocity(0,0),
    mAcceleration(0,0),	mForce(0,0), mMass(1.0f), mRestitution(1.0f), mFriction(0.0f) {}
	~sParticle() {}
    
    b2Vec2 mPrePosition;
	b2Vec2 mPosition;
	b2Vec2 mOldPosition;
	b2Vec2 mVelocity;
	b2Vec2 mAcceleration;
	b2Vec2 mForce;
    CCSprite *sp; //核心粒子
    CCSprite *sp2;//外围粒子
    CCSprite *buddleSp;//气泡粒子 根据速度随机显示
    
	// electrodruid TODO - these can probably be moved out as global values to save storing them
	float mMass;
	float mRestitution;
	float mFriction;
    
    int inittick;
    bool isAwake;
    bool ifFanDeHuaForce;//是否受到范德华力标志 用于判断每一帧的单独水滴粒子是否变形
    bool isBuddlePraticle;//是否为气泡粒子
    int buddleTick;//作为气泡粒子的tick 到时间消除 也许尝试根据速度来消除更合理
    
    int type;//水滴的颜色或者所属性质标记 2为烟雾粒子
    int allowTolCount;
    int xuanwoTick;
    int xuanwoTickCount;
   
};

struct singleVec
{
    b2Vec2 vec1;
    b2Vec2 vec2;
};

class QueryWorldInteractions : public b2QueryCallback {
public:
    QueryWorldInteractions(cFluidHashList (*grid)[hashHeight], sParticle *particles) {
        hashGridList = grid;
        liquid = particles;
    };
    
    bool ReportFixture(b2Fixture* fixture);
    int x, y;
    float deltaT;
    
protected:
    cFluidHashList (*hashGridList)[hashHeight];
    sParticle *liquid;
};

class QueryWorldPostIntersect : public b2QueryCallback {
public:
    QueryWorldPostIntersect(cFluidHashList (*grid)[hashHeight], sParticle *particles) {
        hashGridList = grid;
        liquid = particles;
    };
    
    bool ReportFixture(b2Fixture* fixture);
    int x, y;
    float deltaT;
    
protected:
    cFluidHashList (*hashGridList)[hashHeight];
    sParticle *liquid;
};

//extern liquid[nParticles];


extern int nParticles;
extern int nAwakeParticles;//当前游戏视图活动水滴个数
extern int haveAwakeParticlesNum;//总共激活过的水滴的个数
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

//render sprite
extern CCSpriteBatchNode *ParticleBatch;
extern CCSpriteBatchNode *ParticleBatch2;
extern CCSpriteBatchNode *smokeParticleBatch;
extern CCSpriteBatchNode *ParticleBuddleBatch;
extern CCRenderTexture *renderTexture;
extern CCRenderTexture *renderTexture2;
extern SPHNode *gameLayer;

extern float fpressure;
extern float fpresnear;

//extern DLRenderTexture2 *renderTexture2;
//extern DLRenderTexture3 *renderTexture3;

//fluid praticle object array
extern sParticle *liquid;
extern float *vlenBuffer;

//box2d physical
extern b2World *m_world;
extern GLESDebugDraw *m_debugDraw;
extern QueryWorldInteractions *intersectQueryCallback;
extern QueryWorldPostIntersect *eulerIntersectQueryCallback;

//这三个地形边界一般用于多线条封闭式地形的碰撞检测地形
extern int vertsNum;//地形线数量
extern b2Vec2 *verts;

extern int vertsNum1;//地形线数量
extern b2Vec2 *verts1;

extern int vertsNum2;//地形线数量
extern b2Vec2 *verts2;
//extern b2Vec2 verts[12];//地形指针

extern int singleVerNum;//两条地形线数量
extern singleVec *singleVers;

extern float collisionFactor;


//fluid step compute function
void initFluidPraticles(float prad,float pvisc,float pidealRad, float ptotalMass,float ppraticlesN,NSString *spSprName,NSString *sp2SprName);
void awakePraticles(int awakeNum);
void awakePraticles(int awakeNum,b2Vec2 position,float width,float height,b2Vec2 initVelocity,float angle,int allowTolCount,bool ifContinueSmoothFlow);
void resetAllFluid();
void clearMemory();
void updateFluidStep(float dt);
void clearHashGrid();
void hashLocations();
void resetGridTailPointers(int particleIdx);
void applyLiquidConstraint(float deltaT);
void checkBounds();
void dampenLiquid();
void processWorldInteractions(float deltaT);
bool ParticleSolidCollision(b2Fixture* fixture, b2Vec2& particlePos, b2Vec2& nearestPos, b2Vec2& impactNormal,int particleIdx);
void SeparateParticleFromBody(int particleIdx, b2Vec2& nearestPos, b2Vec2& normal, sParticle *liquid);
void outBoundsHandle(int gay,b2Vec2 newP ,int praticleIndex);
void outBoundsHandle1(int gay,b2Vec2 newP ,int praticleIndex);
void outBoundsHandle2(int gay,b2Vec2 newP ,int praticleIndex);
void outBoundsHandleSingleVer(int gay,b2Vec2 newP,int praticleIndex,float deltaT);
void SeparatePraticleFromEdge(int praticleIndex,b2Vec2 newV,float deltaT,b2Vec2 vec1,b2Vec2 vec2);
void stepFluidParticles(float deltaT);
void addBuddle(int i,float vSqr,int hcell,int vcell);//随着水滴一起运动的气泡
void addBuddle2(int i,float vSqr,int hcell,int vcell);//气泡2 匀速上升运动气泡
void resolveIntersections(float deltaT);
void cateGory(int xIndex, int yIndex);

//越界 定义了最多三个边界地图的处理情况 一般用于多线条封闭式地形的碰撞检测地形
int tolCT(int praticleIndex, b2Vec2 newP);//边界地图1
int tolCT1(int praticleIndex, b2Vec2 newP);//边界地图2
int tolCT2(int praticleIndex, b2Vec2 newP);//边界地图3
int tolCTSingleVer(int praticleIndex, b2Vec2 newP);//单条边界的碰撞检测反应 用于非闭合碰撞区间
//交点
void jiaoPoint(int i, vector<ccVertex2F>& BoundsPointVec, int boundsFlag); //上下左右 4,3,2,1

//math function
//计算交叉乘积(P1-P0)x(P2-P0)
double xmult(b2Vec2 p1,b2Vec2 p2,b2Vec2 p0);

//判点是否在线段上,包括端点
int dot_online_in(b2Vec2 p,b2Vec2 l1,b2Vec2 l2);

//判两点在线段同侧,点在线段上返回0
int same_side(b2Vec2 p1,b2Vec2 p2,b2Vec2 l1,b2Vec2 l2);

//判三点共线
int dots_inline(b2Vec2 p1,b2Vec2 p2,b2Vec2 p3);

//判两线段相交,包括端点和部分重合
int intersect_in(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2);

//计算两线段交点,请判线段是否相交(同时还是要判断是否平行!)
b2Vec2 intersection(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2);

//直线与线段交点 前两个为直线坐标 后两个为线段坐标
b2Vec2 intersectionStraight(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2);

//判断某点是否在多边形区域内

//判断点pt在有向线段p1p2的哪一侧
//返回值1左侧、0在直线上、-1右侧
int SideOfLine(b2Vec2 p1, b2Vec2 p2, b2Vec2 pt);
//判断给定点pt是否在多边形poly内
//返回0在内部，-1在外面
//返回 > 0表示点在第几条有向线段上
int PtInPoly(b2Vec2 pt, b2Vec2 *poly,int count);
bool PtInPolygon(b2Vec2 p,b2Vec2* ptPolygon,int nCount);




