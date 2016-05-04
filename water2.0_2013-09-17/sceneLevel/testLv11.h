//
//  SPHNode.h
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCRenderTexture.h"
#import "Box2d.h"
#import "sphFluid.h"
#import "VRope.h"


@class DLRenderTexture;

extern int nParticles;
extern int nAwakeParticles;
extern int haveAwakeParticlesNum;
extern int fluidPraNum;//当前关卡给与的水滴数量
extern int buddleNum;//气泡个数
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
extern CCSpriteBatchNode *ParticleBuddleBatch;
extern SPHNode *gameLayer;
//extern DLRenderTexture *renderTexture;
//extern DLRenderTexture2 *renderTexture2;

//fluid praticle object array
extern sParticle *liquid;
extern float *vlenBuffer;

//box2d physical
extern b2World *m_world;
extern GLESDebugDraw *m_debugDraw;
extern QueryWorldInteractions *intersectQueryCallback;
extern QueryWorldPostIntersect *eulerIntersectQueryCallback;

//extern int vertsNum;//地形线数量
//extern b2Vec2 verts[12];//地形指针

@class a;
@class b;
@interface testLv11 : SPHNode
{
    CGPoint prePoint;
    bool ifMove;
    
    CCSprite* backgroundSprite1;

    
    //UIKit
    CCSprite *releaseFluidBt;
    BOOL ifFluidBtPressed;
    
    b2Vec2 unusedSection1[4];
    
    CGPoint shushuiPs;
    
    b2Body* bianseBox;
    
    
    CCRenderTexture *fluidRender;
    
    
    int colorRampUniformLocation;  //2
    CCTexture2D *colorRampTexture; //3
    
    
}

+(CCScene *) scene;
-(void)createSliderCrank;


@end
