//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "sphFluid.h"
#import "DLRenderTexture.h"
#import "SPHNode.h"
//#import "DLRenderTexture2.h"
//#import "DLRenderTexture3.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>

int nParticles = 0;
int nAwakeParticles;
int haveAwakeParticlesNum;
int fluidPraNum;
int buddleNum = 0;
int lastFallPraticleIndex = -1;//最后一个下落水滴的是索引 为产生平滑水流参数
bool isWaitForSmoothFlow;
float rad;
float visc;
float idealRad;
float totalMass;
cFluidHashList hashGridList[hashWidth][hashHeight];
b2Shape *mNeighboursBuffer[nominalNeighbourListLength];
int groupID;//簇ID

float fpressure = 2.f;
float fpresnear = 2.f;

//render sprite
CCSpriteBatchNode *ParticleBatch;
CCSpriteBatchNode *ParticleBatch2;
CCSpriteBatchNode *smokeParticleBatch;
CCSpriteBatchNode *ParticleBuddleBatch;
CCRenderTexture *renderTexture;
CCRenderTexture *renderTexture2;
SPHNode *gameLayer;
//DLRenderTexture2 *renderTexture2;
//DLRenderTexture3 *renderTexture3;

//fluid praticle object array
sParticle *liquid;
float *vlenBuffer;

//box2d physical
b2World *m_world;
GLESDebugDraw *m_debugDraw;
QueryWorldInteractions *intersectQueryCallback;
QueryWorldPostIntersect *eulerIntersectQueryCallback;

int vertsNum;//地形线数量
b2Vec2 *verts;

int vertsNum1;//地形线数量
b2Vec2 *verts1;

int vertsNum2;//地形线数量
b2Vec2 *verts2;
//b2Vec2 verts[12];//地形指针

int singleVerNum;//两条地形线数量
singleVec *singleVers;

float collisionFactor;

bool ParticleSolidCollision(b2Fixture* fixture, b2Vec2& particlePos, b2Vec2& nearestPos, b2Vec2& impactNormal,int particleIdx);
void SeparateParticleFromBody(int particleIdx, b2Vec2& nearestPos, b2Vec2& normal, sParticle *liquid);

bool QueryWorldInteractions::ReportFixture(b2Fixture* fixture) {
    // electrodruid: Handy debug code to show which grid cells are being considered.
    // How well this technique will scale depends on a few factors - number (and radius) of the
    // particles, the size of the grid, the number of shapes in the b2broadphase, but in general
    // it seems to be quicker to do things this way than to have particles exist in the broadphase
    // and to test for pairs.
    
    // 					b2Color red(1.0f, 0.0f, 0.0f);
    // 					b2Vec2 v1(minX, maxY);
    // 					b2Vec2 v2(maxX, maxY);
    // 					b2Vec2 v3(maxX, minY);
    // 					b2Vec2 v4(minX, minY);
    // 					m_debugDraw.DrawSegment(v1, v2, red);
    // 					m_debugDraw.DrawSegment(v2, v3, red);
    // 					m_debugDraw.DrawSegment(v3, v4, red);
    // 					m_debugDraw.DrawSegment(v4, v1, red);
    
    int numParticles = hashGridList[x][y].GetSize();
    hashGridList[x][y].ResetIterator();
    
    // Iterate through all the particles in this cell
    for(int i = 0; i < numParticles; i++)
    {
//        if(liquid[i].isAwake == false) continue;
        
        int particleIdx = hashGridList[x][y].GetNext();
        
        b2Vec2 particlePos = liquid[particleIdx].mPosition;
        if(fixture->GetBody()->GetType() == b2_staticBody || fixture->GetBody()->GetType() == b2_kinematicBody)//|| fixture->GetBody()->GetType() == b2_kinematicBody
        {
            b2Vec2 nearestPos(0,0);
            b2Vec2 normal(0,0);
            
            // electrodruid TODO: moving particles out to the nearest edge in this way
            // can cause leaking and tunnelling, particularly for high-velocity particles.
            // Perhaps some kind of approach involving raycasting between the old particle
            // position and the current one would work better?
            bool inside = ParticleSolidCollision(fixture, particlePos, nearestPos, normal,particleIdx);
            
            if (inside)
            {
                SeparateParticleFromBody(particleIdx, nearestPos, normal, liquid);
            }
        }
        else//不明白非静态物体为什么要用以下算法 我认为和静态算法一样的物理计算才是符合规律的 非静态物体 相互之间产生冲力
        {
            b2Vec2 nearestPos(0,0);
            b2Vec2 normal(0,0);
            bool inside = ParticleSolidCollision(fixture, particlePos, nearestPos, normal,particleIdx);
            
            if (inside)
            {
                b2Vec2 particleVelocity = liquid[particleIdx].mVelocity;
                
                // electrodruid: I think this does need to be here
                particleVelocity *= deltaT;
                // electrodruid: not sure if this should be here
                //									particleVelocity *= liquid[particleIdx].mMass;
                
                // electrodruid: Still not sure exactly what the paper meant by
                // "intersection position", but taking the current particle position
                // seems to give the least-bad results
                b2Vec2 impulsePos = particlePos;
                //									b2Vec2 impulsePos = nearestPos;
                
                b2Vec2 pointVelocity = fixture->GetBody()->GetLinearVelocityFromWorldPoint(impulsePos);
                b2Vec2 pointVelocityAbsolute = pointVelocity;
                // electrodruid: I think this does need to be here
                pointVelocity *= deltaT;
                
                //changed by tr 2013-10-09
                b2Vec2 relativeVelocity;
//                if(collisionFactor == 0.f)
//                {
//                    relativeVelocity = 8.f*particleVelocity - pointVelocity;
//                }
//                else
//                {
//                    relativeVelocity = collisionFactor*particleVelocity - pointVelocity;
//                }
                relativeVelocity = collisionFactor*particleVelocity - pointVelocity;
                
                b2Vec2 pointVelNormal = normal;
                pointVelNormal *= b2Dot(relativeVelocity, normal);
                b2Vec2 pointVelTangent = relativeVelocity - pointVelNormal;
                
                // Should be a value between 0.0f and 1.0f
                const float slipFriction = 0.3f;//0.3f
                
                pointVelTangent *= slipFriction;
                b2Vec2 impulse = 1.f*(pointVelNormal - pointVelTangent);
                
                // electrodruid: not sure if this should be here
                //									impulse *= deltaT;
                
                // electrodruid: Don't know if this should be a force or an impulse...
                fixture->GetBody()->ApplyLinearImpulse(impulse, impulsePos);//changed by tr 2013-08-10
                //									 pShape->GetBody()->ApplyForce(impulse, impulsePos);
                
                // electrodruid: Bodies with low mass don't float, they just spin too
                // fast because of low rotational inertia. As well as fudging for the
                // spinning, try to add buoyancy by adding a force to negate (some of)
                // the gravity affecting the body. This needs to be tuned properly
                // for different bodies
//                b2Vec2 buoyancy = -m_world->GetGravity();
                b2Vec2 buoyancy = b2Vec2(0.f, 10.f);
                const float buoyancyAdjuster = 0.3f;
                buoyancy *= buoyancyAdjuster;
                
                fixture->GetBody()->ApplyForce(buoyancy, fixture->GetBody()->GetPosition());
                
                // move the particles away from the body
#ifdef VERLET_INTEGRATION
                SeparateParticleFromBody(particleIdx, nearestPos, normal, liquid);
#else
                liquid[particleIdx].mVelocity -= impulse;
                liquid[particleIdx].mVelocity += pointVelocityAbsolute;
#endif
            }
        }
    }
    return true;
    
}

bool QueryWorldPostIntersect::ReportFixture(b2Fixture *fixture)
{
    int numParticles = hashGridList[x][y].GetSize();
    hashGridList[x][y].ResetIterator();

    for(int i = 0; i < numParticles; i++)
    {
//        if(liquid[i].isAwake == false) continue;
        int particleIdx = hashGridList[x][y].GetNext();
        
        b2Vec2 particlePos = liquid[particleIdx].mPosition;
        if(fixture->GetBody()->GetType() == b2_dynamicBody)
        {
            b2Vec2 nearestPos(0,0);
            b2Vec2 normal(0,0);
            bool inside = ParticleSolidCollision(fixture, particlePos, nearestPos, normal,particleIdx);
            
            if (inside)
            {
                SeparateParticleFromBody(particleIdx, nearestPos, normal, liquid);
            }
        }
    }
    return true;
    
}

inline float b2Random(float lo, float hi)
{
    return ((hi - lo) * CCRANDOM_0_1() + lo);;
}

const float fluidMinX = -10.0f;
const float fluidMaxX = 45;//grid的总高度 对应多少行 这里切忌搞反！40.0f
const float fluidMinY = -5.0f;
const float fluidMaxY = 30.5;//grid的总宽度 对应多少列 20.0f


inline float myMap(float val, float minInput, float maxInput, float minOutput, float maxOutput)
{
    float result = (val - minInput) / (maxInput - minInput);
    result *= (maxOutput - minOutput);
    result += minOutput;
    return result;
    
}

inline int hashX(float x)
{
    float f = myMap(x, fluidMinX, fluidMaxX, 0, hashWidth-.001f);
    return (int)f;
}

inline int hashY(float y)
{
    float f = myMap(y, fluidMinY, fluidMaxY, 0, hashHeight-.001f);
    return (int)f;
}

void initFluidPraticles(float prad,float pvisc,float pidealRad, float ptotalMass,float ppraticlesN,NSString *spSprName,NSString *sp2SprName)
{
    //common para
//    rad = .6f;
//    visc = .002f;//.0002f
//    idealRad = 60.0f;
//    totalMass = 0.f;
    rad = prad;
    visc = pvisc;//.0002f
    idealRad = pidealRad;
    totalMass = ptotalMass;
    nParticles = ppraticlesN;
    
    liquid = (sParticle*)malloc(sizeof(sParticle)*nParticles);
    vlenBuffer = (float *)malloc(sizeof(float)*nParticles);
    for (int i = 0; i < nParticles; ++i)
	{        
        //liquid[i].mPosition = b2Vec2( b2Random(-10,-10),b2Random(-10, -10));//( b2Random(-20, -10),b2Random(-20, -10))
        liquid[i].mPosition = b2Vec2( -10, -10);
        liquid[i].mPrePosition = liquid[i].mPosition;
		liquid[i].mOldPosition = liquid[i].mPosition;
		liquid[i].mVelocity = b2Vec2(0.0f, -0.0f);
		liquid[i].mAcceleration = b2Vec2(0, -10.0f);
        liquid[i].buddleSp = nil;
        
		liquid[i].mMass = totalMass/nParticles;
		liquid[i].mRestitution = 0.4f;
		liquid[i].mFriction = 0.0f;
        liquid[i].isAwake = false;
        liquid[i].ifFanDeHuaForce = true;
        liquid[i].isBuddlePraticle = false;
        liquid[i].mForce = b2Vec2(0,-0);
        
        liquid[i].inittick = 0;
        liquid[i].buddleTick = 0;
        liquid[i].xuanwoTick = 60 + rand()%240;
        if(ParticleBatch != nil && spSprName != nil)
        {
            liquid[i].sp = [CCSprite spriteWithFile:spSprName];
            [ParticleBatch addChild:liquid[i].sp];
        }
        else
        {
            liquid[i].sp = nil;
        }
//        if(ParticleBatch2 != nil && sp2SprName != nil)
//        {
//             liquid[i].sp2 = [CCSprite spriteWithFile:sp2SprName];
//             [ParticleBatch2 addChild:liquid[i].sp2];
//        }
//        else
//        {
//            liquid[i].sp2 = nil;
//        }
	}
    
}

void awakePraticles(int awakeNum)
{
    int countNum = awakeNum;
    int numAve =0;
    for (int i = 0; i < nParticles; ++i)
	{
        if(liquid[i].isAwake == false)
        {
            //y = -3/8x+30
//            liquid[i].mPosition = b2Vec2( b2Random(4,16),b2Random(12, 14));
//            numAve++;
//            if(numAve < awakeNum/3)
//            {
//                float x = 3*32+i*2;
//                float y = -3.f/8*x+30;
//                liquid[i].mPosition = b2Vec2(x/32.f,y/32.f);
//            }
//            else if(numAve >= awakeNum/3 && i < 2*awakeNum/3)
//            {
//                float x = 3*32+i*2;
//                float y = -3.f/8*x+25;
//                liquid[i].mPosition = b2Vec2(x/32.f,y/32.f);
//            }
//            else
//            {
//                float x = 3*32+i*5;
//                float y = -3.f/8*x+20;
//                liquid[i].mPosition = b2Vec2(x/32.f,y/32.f);
//            }
            
            //liquid[i].mPosition = b2Vec2(b2Random(18,24),b2Random(20, 40));
            //liquid[i].isAwake = true;
            liquid[i].mPosition = b2Vec2(b2Random(14,20),b2Random(20, 40));
            liquid[i].mOldPosition = liquid[i].mPosition;
            liquid[i].mVelocity = b2Vec2(.0f, -20.0f);
            liquid[i].mForce = b2Vec2(0,0);
            countNum--;
        }
        if(countNum == 0)break;
    }
    
}

//void awakePraticles(int awakeNum,b2Vec2 position,float width,float height,b2Vec2 initVelocity,float angle,int allowTolCount = 0,bool ifContinueSmoothFlow = false)
//{
////    extern int nParticles;
////    extern int nAwakeParticles;//当前游戏视图活动水滴个数
////    extern int haveAwakeParticlesNum;//总共激活过的水滴的个数
////    extern int fluidPraNum;//当前关卡给与的水滴数量
//    
//    if(fluidPraNum > haveAwakeParticlesNum)
//    {
//        for (int i = 0; i < nParticles; ++i)
//        {
//            if(liquid[i].isAwake == false)
//            {
//                liquid[i].allowTolCount = allowTolCount;
//                liquid[i].mPosition = b2Vec2(b2Random(position.x/PTM_RATIO-5.f, position.x/PTM_RATIO+5.f),b2Random(position.y/PTM_RATIO+1.f, position.y/PTM_RATIO+30.f));;//b2Vec2((((awakeNum-countNum)%rowNum)*width/rowNum+position.x)/PTM_RATIO,(((awakeNum-countNum)/rowNum)*fluidColumnHei*-1.f+position.y)/PTM_RATIO);
//                liquid[i].mPrePosition = liquid[i].mPosition;
//                liquid[i].mOldPosition = liquid[i].mPosition;
//                liquid[i].mVelocity = b2Vec2(0.0f, 0.0f);
//                haveAwakeParticlesNum++;
//                if(fluidPraNum <= haveAwakeParticlesNum) break;
//            }
//        }
//        
//    }
//    
//}

void awakePraticles(int awakeNum,b2Vec2 position,float width,float height,b2Vec2 initVelocity,float angle,int allowTolCount = 0,bool ifContinueSmoothFlow = false)
{
    //angle为倾斜角度 width为宽度 height为每一列或每一行间隔长度 为负数时为横向 注意横纵 会改变宽度和长度的算法
    position.x = position.x-100;
    int countNum = awakeNum;
    //这两个参数为了产生的水流能形成一个类似瀑布或者均匀流体的效果
    int rowNum = 2;//产生水流时 每一行的水滴粒子个数
    float fluidColumnHei = -10;//产生水流时 每行高度 为负数时表示横向向左累积 正数表述纵向向上累积 height
    
//    if(lastFallPraticleIndex != -1 && liquid[lastFallPraticleIndex].isAwake == false && liquid[lastFallPraticleIndex].mPosition.y*PTM_RATIO > position.y)
//    {
//        position.y = liquid[lastFallPraticleIndex].mPosition.y*PTM_RATIO+fluidColumnHei;
//    }
//    else if(ifContinueSmoothFlow == false)
//    {
//        lastFallPraticleIndex = -1;
//    }
    if(ifContinueSmoothFlow == true)
    {
        for (int i = 0; i < nParticles; ++i)
        {
            if(liquid[i].isAwake == false)
            {
                liquid[i].mPosition = b2Vec2(-10, -10);
                liquid[i].mPrePosition = liquid[i].mPosition;
                liquid[i].mOldPosition = liquid[i].mPosition;
                liquid[i].mVelocity = b2Vec2(0.0f, -0.0f);
            }
        }
    }
    for (int i = 0; i < nParticles; ++i)
	{
        if(liquid[i].isAwake == false)
        {
            liquid[i].allowTolCount = allowTolCount;
            if(height > 0)
            {
                liquid[i].mPosition = b2Vec2((((awakeNum-countNum)%rowNum)*width/rowNum+position.x)/PTM_RATIO,(((awakeNum-countNum)/rowNum)*fluidColumnHei+position.y+280)/PTM_RATIO);
            }
            else if(height <= 0)
            {
                liquid[i].mPosition = b2Vec2((((awakeNum-countNum)%rowNum)*width/rowNum+position.x)/PTM_RATIO,(((awakeNum-countNum)/rowNum)*fluidColumnHei*-1.f+position.y)/PTM_RATIO+280);
            }
            liquid[i].mPrePosition = liquid[i].mPosition;
            liquid[i].mOldPosition = liquid[i].mPosition;
            liquid[i].mVelocity = initVelocity;
            liquid[i].mForce = b2Vec2(0,0);
            countNum--;
        }
        if(countNum == 0 || (haveAwakeParticlesNum+awakeNum-countNum)>=fluidPraNum )
        {
            break;
        }
    }

}

void resetAllFluid()
{
    for (int i = 0; i < nParticles; ++i)
	{
        liquid[i].isAwake = true;
        liquid[i].mPosition = b2Vec2(b2Random(-20, -10),b2Random(-20, -10));
        liquid[i].mVelocity = b2Vec2(0.0f, 0.0f);
        liquid[i].inittick = 0;
    }
    haveAwakeParticlesNum = 0;
    
}

void clearMemory()
{
    nParticles = 0;
    haveAwakeParticlesNum = 0;
    if(liquid != NULL)
    {
        free(liquid);
        liquid = NULL;
    }
    if(vlenBuffer != NULL)
    {
        free(vlenBuffer);
        vlenBuffer = NULL;
    }
    
}

void updateFluidStep(float dt)
{
    hashLocations();
    applyLiquidConstraint(dt);
    processWorldInteractions(dt);
    dampenLiquid();
    resolveIntersections(dt);
    
    groupID = 0;//不能放在聚类函数体内 内部存在迭代
    cateGory(0,0);
    
    stepFluidParticles(dt);
   
}

void clearHashGrid()
{
	for(int a = 0; a < hashWidth; a++)
	{
		for(int b = 0; b < hashHeight; b++)
		{
			hashGridList[a][b].Clear();
		}
	}
    
}

void hashLocations()
{
    clearHashGrid();
    nAwakeParticles = 0;//每一帧开始运算前重新将active水滴数清零 然后重新统计
	for(int a = 0; a < nParticles; a++)
	{
		int hcell = hashX(liquid[a].mPosition.x);
		int vcell = hashY(liquid[a].mPosition.y);
        
		if(hcell > -1 && hcell < hashWidth && vcell > -1 && vcell < hashHeight)
		{
            if(liquid[a].isAwake == false)
            {
                liquid[a].isAwake = true;
                haveAwakeParticlesNum++;
            }
			hashGridList[hcell][vcell].PushBack(a);
            nAwakeParticles++;
            
		}
        else
        {
            //added by tr 2013-10-03
            if(liquid[a].inittick != 0)//防止弹出又被弹回来的水滴加入计算
            {
                liquid[a].mPosition = b2Vec2(-10,-10);
                liquid[a].mPrePosition = liquid[a].mPosition;
                liquid[a].mOldPosition = liquid[a].mPosition;
                
            }
            //ended by tr 2013-10-03
        
            liquid[a].isAwake = false;
            liquid[a].buddleTick = 0;
            liquid[a].inittick = 0;
            
            //移出之前产生的气泡
            if(liquid[a].buddleSp != nil)
            {
                [liquid[a].buddleSp removeFromParentAndCleanup:YES];
                liquid[a].buddleSp = nil;
            }
            //还原变色后的水滴颜色状态
            if(liquid[a].type != 0)
            {
                [gameLayer reductionColorState:a];
            }
        }
	}
//    NSLog(@"%d",nAwakeParticles);
//    buddleNum = nAwakeParticles/150;//产生气泡的上限
    
}

// Fix up the tail pointers for the hashGrid cells after we've monkeyed with them to
// make the neighbours list for a particle
void resetGridTailPointers(int particleIdx)
{
	int hcell = hashX(liquid[particleIdx].mPosition.x);
	int vcell = hashY(liquid[particleIdx].mPosition.y);
    
	for(int nx = -1; nx < 2; nx++)
	{
		for(int ny = -1; ny < 2; ny++)
		{
			int xc = hcell + nx;
			int yc = vcell + ny;
            
			if(xc > -1 && xc < hashWidth && yc > -1 && yc < hashHeight)
			{
				if(!hashGridList[xc][yc].IsEmpty())
				{
					hashGridList[xc][yc].UnSplice();
				}
			}
		}
	}
}

void applyLiquidConstraint(float deltaT)
{
    // * Unfortunately, this simulation method is not actually scale
    // * invariant, and it breaks down for rad < ~3 or so.  So we need
    // * to scale everything to an ideal rad and then scale it back after.
    
	float multiplier = idealRad / rad;
    
    //changed by tr 2013-08-23
	float xchange[nParticles];//={0.0};
	float ychange[nParticles];//={0.0};
    for(int m = 0; m < nParticles;m++)
    {
        xchange[m] = 0.f;
        ychange[m] = 0.f;
    }
    
	float xs[nParticles];
	float ys[nParticles];
	float vxs[nParticles];
	float vys[nParticles];
    
	for (int i=0; i<nParticles; ++i)
	{
		xs[i] = multiplier*liquid[i].mPosition.x;
		ys[i] = multiplier*liquid[i].mPosition.y;
		vxs[i] = multiplier*liquid[i].mVelocity.x;
		vys[i] = multiplier*liquid[i].mVelocity.y;
	}
    
	cFluidHashList neighbours;
    
	float* vlen = vlenBuffer;
    
	for(int i = 0; i < nParticles; i++)
	{
//        if(liquid[i].isAwake == false) continue;
        
		// Populate the neighbor list from the 9 proximate cells
		int hcell = hashX(liquid[i].mPosition.x);
		int vcell = hashY(liquid[i].mPosition.y);
        
		bool bFoundFirstCell = false;
		for(int nx = -1; nx < 2; nx++)
		{
			for(int ny = -1; ny < 2; ny++)
			{
				int xc = hcell + nx;
				int yc = vcell + ny;
				if(xc > -1 && xc < hashWidth && yc > -1 && yc < hashHeight)
				{
					if(!hashGridList[xc][yc].IsEmpty())
					{
						if(!bFoundFirstCell)
						{
							// Set the head and tail of the beginning of our neighbours list
							neighbours.SetHead(hashGridList[xc][yc].pHead());
							neighbours.SetTail(hashGridList[xc][yc].pTail());
							bFoundFirstCell = true;
						}
						else
						{
							// We already have a neighbours list, so just add this cell's particles onto
							// the end of it.
							neighbours.Splice(hashGridList[xc][yc].pHead(), hashGridList[xc][yc].pTail());
						}
					}
				}
			}
		}
        
		int neighboursListSize = neighbours.GetSize();
		neighbours.ResetIterator();
        
		// Particle pressure calculated by particle proximity
		// Pressures = 0 if all particles within range are idealRad distance away
		float p = 0.0f;
		float pnear = 0.0f;
		for(int a = 0; a < neighboursListSize; a++)
		{
			int n = neighbours.GetNext();
            
			int j = n;
            
			float vx = xs[j]-xs[i];//liquid[j]->GetWorldCenter().x - liquid[i]->GetWorldCenter().x;
			float vy = ys[j]-ys[i];//liquid[j]->GetWorldCenter().y - liquid[i]->GetWorldCenter().y;
            
			//early exit check
			if(vx > -idealRad && vx < idealRad && vy > -idealRad && vy < idealRad)
			{
				float vlensqr = (vx * vx + vy * vy);
				//within idealRad check
				if(vlensqr < idealRad*idealRad)
				{
					vlen[a] = b2Sqrt(vlensqr);
					if (vlen[a] < b2_linearSlop)
					{
                        //						vlen[a] = idealRad-.01f;
                        vlen[a] = idealRad-.01f;//b2_linearSlop;
					}
					float oneminusq = 1.0f-(vlen[a] / idealRad);
					p = (p + oneminusq*oneminusq);
					pnear = (pnear + oneminusq*oneminusq*oneminusq);
				}
				else
				{
					vlen[a] = MAXFLOAT;
				}
			}
		}
        
		// Now actually apply the forces
		float pressure = (p - 5.0f) / fpressure;//8.0f; //normal pressure term2
		float presnear = pnear / fpresnear;//8.0f; //near particles term2
		float changex = 0.0f;
		float changey = 0.0f;
        
		neighbours.ResetIterator();
        
		for(int a = 0; a < neighboursListSize; a++)
		{
			int n = neighbours.GetNext();
            
			int j = n;
            
			float vx = xs[j]-xs[i];//liquid[j]->GetWorldCenter().x - liquid[i]->GetWorldCenter().x;
			float vy = ys[j]-ys[i];//liquid[j]->GetWorldCenter().y - liquid[i]->GetWorldCenter().y;
			if(vx > -idealRad && vx < idealRad && vy > -idealRad && vy < idealRad)
			{
				if(vlen[a] < idealRad)
				{
					float q = vlen[a] / idealRad;
					float oneminusq = 1.0f-q;
					float factor = oneminusq * (pressure + presnear * oneminusq) / (2.0f*vlen[a]);
					float dx = vx * factor;
					float dy = vy * factor;
					float relvx = vxs[j] - vxs[i];
					float relvy = vys[j] - vys[i];
					factor = visc * oneminusq * deltaT;
					dx -= relvx * factor;
					dy -= relvy * factor;
                    
					xchange[j] += dx;
					ychange[j] += dy;
					changex -= dx;
					changey -= dy;
				}
			}
		}

        xchange[i] += changex;
        ychange[i] += changey;
		//xchange[i] += (changex > 0.05f?0.05f:changex);//changex;
		//ychange[i] += (changey > 0.05f?0.05f:changey);//changey;
		// We've finished with this neighbours list, so go back and re-null-terminate all of the
		// grid cells lists ready for the next particle's neighbours list.
        resetGridTailPointers(i);
	}
	
	for (int i=0; i<nParticles; ++i)
	{
        if(fabs(xchange[i]) < 1e-8 && fabs(ychange[i]) < 1e-8)//不受范德华力的粒子进行变形渲染
        {
            liquid[i].ifFanDeHuaForce = false;
            
        }
        liquid[i].mPrePosition = liquid[i].mPosition;
        liquid[i].mPosition += b2Vec2(xchange[i] / multiplier, ychange[i] / multiplier);
		liquid[i].mVelocity += b2Vec2(xchange[i] / (multiplier*deltaT), ychange[i] / (multiplier*deltaT));
	}
    
}

void checkBounds()
{
	float massPerParticle = totalMass / nParticles;
    
	for (int i=0; i<nParticles; ++i)
	{
		if (liquid[i].mPosition.y < -1.0f)
		{
            float cx = -5.0f;
            float cy = 15.0f;
            
            liquid[i].mPosition = b2Vec2( b2Random(4.f, 13.f),
                                         b2Random(11.f, 15.f));
			liquid[i].mOldPosition = liquid[i].mPosition;
            liquid[i].mPrePosition = liquid[i].mPosition;
			liquid[i].mVelocity = b2Vec2(0.0f, 0.0f);
			liquid[i].mAcceleration = b2Vec2(0, -10.0f);
            
			liquid[i].mMass = massPerParticle;
			liquid[i].mRestitution = 0.4f;
			liquid[i].mFriction = 0.0f;
		}
	}
    
}

void dampenLiquid()
{
	for (int i=0; i<nParticles; ++i)
	{
		liquid[i].mVelocity.x *= 0.995f;
		liquid[i].mVelocity.y *= 0.995f;
        if(liquid[i].isAwake == true)liquid[i].inittick++;
	}
}

// Handle interactions with the world
void processWorldInteractions(float deltaT)
{
	// Iterate through the grid, and do an AABB test for every grid containing particles
	for (int x = 0; x < hashWidth; ++x)
	{
		for (int y = 0; y < hashHeight; ++y)//hashWidth?????
		{
			if(!hashGridList[x][y].IsEmpty())
			{
				float minX = myMap((float)x, 0, hashWidth, fluidMinX, fluidMaxX);
				float maxX = myMap((float)x+1, 0, hashWidth, fluidMinX, fluidMaxX);
				float minY = myMap((float)y, 0, hashHeight, fluidMinY, fluidMaxY);
				float maxY = myMap((float)y+1, 0, hashHeight, fluidMinY, fluidMaxY);
                
				b2AABB aabb;
                
				aabb.lowerBound.Set(minX, minY);
				aabb.upperBound.Set(maxX, maxY);
                
                intersectQueryCallback->x = x;
                intersectQueryCallback->y = y;
                intersectQueryCallback->deltaT = deltaT;
                m_world->QueryAABB(intersectQueryCallback, aabb);
			}
		}
	}
    
}

// Detect an intersection between a particle and a b2Shape, and also try to suggest the nearest
// point on the shape to move the particle to, and the shape normal at that point

bool ParticleSolidCollision(b2Fixture* fixture, b2Vec2& particlePos, b2Vec2& nearestPos, b2Vec2& impactNormal,int particleIdx)
{
    const float particleRadius = .2f;
    
	if (fixture->GetShape()->GetType() == b2Shape::e_circle)
	{
		b2CircleShape* pCircleShape = static_cast<b2CircleShape*>(fixture->GetShape());
		const b2Transform& xf = fixture->GetBody()->GetTransform();
		float radius = pCircleShape->m_radius + particleRadius;
		b2Vec2 circlePos = xf.p + pCircleShape->m_p;
		b2Vec2 delta = particlePos - circlePos;
		if (delta.LengthSquared() > radius * radius)
		{
			return false;
		}
        
		delta.Normalize();
		delta *= radius;
		nearestPos = delta + circlePos;//pCircleShape->m_p;//m_p == b2Vec(0,0) why?
		impactNormal = (nearestPos - circlePos);
		impactNormal.Normalize();
        
//        NSLog(@"x:%f y:%f nearPosX:%f nearPosY:%f %f %f %f %f",liquid[particleIdx].mPosition.x,liquid[particleIdx].mPosition.y,nearestPos.x,nearestPos.y,pCircleShape->m_p.x,pCircleShape->m_p.y,xf.p.x,xf.p.y);
        
        //added by tr 2013-10-07
        [gameLayer setColorState:particleIdx];
        [gameLayer collisionHandle:fixture->GetBody() index:particleIdx];
        //ended by tr 2013-10-07
        
		return true;
		
	}
	else if (fixture->GetShape()->GetType() == b2Shape::e_polygon)
	{
		b2PolygonShape* pPolyShape = static_cast<b2PolygonShape*>(fixture->GetShape());
		const b2Transform& xf = fixture->GetBody()->GetTransform();
		int numVerts = pPolyShape->GetVertexCount();
        
		b2Vec2 vertices[b2_maxPolygonVertices];
		b2Vec2 normals[b2_maxPolygonVertices];
        
		for (int32 i = 0; i < numVerts; ++i)
		{
			vertices[i] = b2Mul(xf, pPolyShape->m_vertices[i]);
			normals[i] = b2Mul(xf.q, pPolyShape->m_normals[i]);
		}
        
		float shortestDistance = 99999.0f;
        
		for (int i = 0; i < numVerts ; ++i)
		{
            b2Vec2 vertex = vertices[i] + particleRadius * normals[i] - particlePos;
			float distance = b2Dot(normals[i], vertex);//当前水滴点到向外长度为水滴半径的法线形成的外边缘的距离
            
			if (distance < 0.0f)
			{
				return false;//定理证明 当延各个顶点的当前边做向外方向的法线的时候 法线长度为归一化或者等值长度 则在该两个顶点法线形成的矩形区域内的点和该多边形任意一条法线顶点形成的夹角一定小雨90度 该多边形必须为凸多边形(凹多边形除外)
			}
            
			if (distance < shortestDistance)
			{
				shortestDistance = distance;//离最近一条边的距离
				
				nearestPos = b2Vec2(
                                    normals[i].x * distance + particlePos.x,
                                    normals[i].y * distance + particlePos.y);//这时候位置变为了多边形的边缘 如果后续的地s探测的距离更小 这个边缘位置仍然会在循环种调整
                
				impactNormal = normals[i];
			}
		}
        
        //added by tr 2013-10-07
        [gameLayer setColorState:particleIdx];
        [gameLayer collisionHandle:fixture->GetBody() index:particleIdx];
        //ended by tr 2013-10-07
        
		return true;
        
	}
    else if (fixture->GetShape()->GetType() == b2Shape::e_edge)//放弃box2d的方法 使用自己写的边缘反弹
	{
//        //added by tr 2013-08-08
//        b2EdgeShape* pEdgeShape = static_cast<b2EdgeShape*>(fixture->GetShape());
//        float A, B, C, D,x1,y1,x2,y2,x3,y3;
//        x1 = pEdgeShape->m_vertex1.x;
//        y1 = pEdgeShape->m_vertex1.y;
//        x2 = pEdgeShape->m_vertex2.x;
//        y2 = pEdgeShape->m_vertex2.y;
//        x3 = particlePos.x;
//        y3 = particlePos.y;
//
//        //直线与线段交点 前两个为直线坐标 后两个为线段坐标
//        //b2Vec2 intersectionStraight(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
//        //判断点垂直这条线段的直线是否又交点
//        float k1;
//        if(fabs(x1-x2) < 1e-8)
//        {
//            k1 = 100000.f;
//        }
//        else k1 = (y1-y2)/(x1-x2);
//        float k2 = -1.f/k1;
//        float b2 = y3 - k2*x3;
//        b2Vec2 jiaoB2 = intersectionStraight(particlePos,b2Vec2((particlePos.x+10.f),k2*(particlePos.x+10.f)+b2),pEdgeShape->m_vertex1,pEdgeShape->m_vertex2);
//        if(fabs(jiaoB2.x)<1e-12 && fabs(jiaoB2.y)<1e-12)//无交点 直接返回
//        {
//            return false;
//        }
//        
//        A = y1 - y2;
//        B = x2 - x1;
//        C = x1 * y2 - x2 * y1;
//        D = fabs(A * x3 + B * y3 + C) / sqrt(A * A + B * B);
//        if(D > (particleRadius))
//        {
//            return false;
//        }
//        
//        b2Vec2 delta;
//        b2Vec2 unrealCircleP;
//        
//        b2Vec2 reBoundPos;
//        if(fabs(y1 - y2) < 1e-6)//水平线
//        {
//            if(y1 > y3)
//            {
//                delta.Set(0.f,-D);
//                unrealCircleP.Set(x3,y3+D);
//                reBoundPos = b2Vec2(x3,y3-2.f*(particleRadius-D));
//                
//            }
//            else
//            {
//                delta.Set(0.f, D);
//                unrealCircleP.Set(x3,y3-D);
//                reBoundPos = b2Vec2(x3,y3+2.f*(particleRadius-D));
//            }
//        }
//        else if (fabs(x1 - x2) < 1e-6)//垂直线
//        {
//            if(x1 > x3)
//            {
//               delta.Set(-D,0.f);
//               unrealCircleP.Set(x3+D,y3);
//               reBoundPos = b2Vec2(x3-2.f*(particleRadius-D),y3);
//            }
//            else
//            {
//                delta.Set(D, 0.f);
//                unrealCircleP.Set(x3-D,y3);
//                reBoundPos = b2Vec2(x3+2.f*(particleRadius-D),y3);
//            }
//        }
//        else
//        {
//            float edgeK = (y2-y1)/(x2-x1);
//            float unrealK = -1.f/edgeK;
//            // y = unrealK*x + b ;
//            // b1 = y3 - unrealK*x;
//            
//            float b1 = y1 - edgeK*x1;
//            float b2 = y3 - unrealK*x3;
//            
//            float jiaoPX = edgeK*(b2-b1)/(edgeK * edgeK + 1);
//            float jiaoPY = unrealK*jiaoPX+b2;
//            unrealCircleP.Set(jiaoPX, jiaoPY);
//            delta.Set(x3 - jiaoPX, y3 - jiaoPY);
//            
//            //求解一元二次方程解求还原两倍的距离
//            float dis = particleRadius - D;
//            float m = b2 - y3;
//            float a4 = unrealK*unrealK+1.f;
//            float b4 = 2.f*unrealK*m-2.f*x3;
//            float c4 = x3*x3 + m*m - dis*dis;
//            
//            float reX1 = (-1.f*b4+sqrt(fabs(b4*b4-4.f*a4*c4)))/(2.f*a4);//一元二次方程解
//            float reX2 = (-1.f*b4-sqrt(fabs(b4*b4-4.f*a4*c4)))/(2.f*a4);
//            
//            float reY1 = unrealK*reX1+b2;
//            float reY2 = unrealK*reX2+b2;
//            
//            if((b2Vec2(reX1,reY1)- b2Vec2(jiaoPX,jiaoPY)).Length() > (b2Vec2(reX2,reY2)- b2Vec2(jiaoPX,jiaoPY)).Length())
//            {
//                reBoundPos = 1.f*(b2Vec2(reX1,reY1)-particlePos)*1.f*liquid[particleIdx].mRestitution+particlePos;
//            }
//            else
//            {
//                reBoundPos = 1.f*(b2Vec2(reX2,reY2)-particlePos)*1.f*liquid[particleIdx].mRestitution+particlePos;
//            }
//        }
//        
//        delta.Normalize();
//		delta *= D;//radius;
//        nearestPos = reBoundPos;//particlePos+2*(particleRadius -.2f);
//		impactNormal = (nearestPos - unrealCircleP);
//		impactNormal.Normalize();
		return false;
            
        
//        //added by tr 2013-08-08
//        b2EdgeShape* pEdgeShape = static_cast<b2EdgeShape*>(fixture->GetShape());
//        float A, B, C, D,x1,y1,x2,y2,x3,y3;
//        x1 = pEdgeShape->m_vertex1.x;
//        y1 = pEdgeShape->m_vertex1.y;
//        x2 = pEdgeShape->m_vertex2.x;
//        y2 = pEdgeShape->m_vertex2.y;
//        x3 = particlePos.x;
//        y3 = particlePos.y;
//
//		b2Transform xf;
//        xf.p.Set((x1+x2)/2,(y1+y2)/2);
//        if(fabs(y2-y1) < 1e-12)//平行
//        {
//            xf.q.Set(0.f);
//        }
//        else if(fabs(x2-x1) < 1e-12)//垂直
//        {
//            xf.q.Set(3.1415926f/2.f);
//        }
//        else
//        {
//            xf.q.Set(asin((y1+y2)/(x1+x2)));
//        }
//        
//		b2Vec2 vertices = b2Mul(xf, b2Vec2(x1,x2));;
//		b2Vec2 normals = b2Mul(xf.q, pPolyShape->m_normals);
//        
//        float shortestDistance = 99999.0f;
//        b2Vec2
//        
//		for (int32 i = 0; i < numVerts; ++i)
//		{
//			vertices[i] = b2Mul(xf, b2Vec2(x1,x2));
//			normals[i] = b2Mul(xf.q, pPolyShape->m_normals[i]);
//		}
//        
//		float shortestDistance = 99999.0f;
//        
//		for (int i = 0; i < numVerts ; ++i)
//		{
//            b2Vec2 vertex = vertices[i] + particleRadius * normals[i] - particlePos;
//			float distance = b2Dot(normals[i], vertex);
//            
//			if (distance < 0.0f)
//			{
//				return false;
//			}
//            
//			if (distance < shortestDistance)
//			{
//				shortestDistance = distance;
//				
//				nearestPos = b2Vec2(
//                                    normals[i].x * distance + particlePos.x,
//                                    normals[i].y * distance + particlePos.y);
//                
//				impactNormal = normals[i];
//			}
//		}
//		return true;
        
    }
	else
	{
		// Unrecognised shape type
		assert(false);
		return false;
	}
    
}

// Move the particle from inside a body to the nearest point outside, and (if appropriate), adjust
// the particle's velocity
void SeparateParticleFromBody(int particleIdx, b2Vec2& nearestPos, b2Vec2& normal, sParticle *liquid)
{
        liquid[particleIdx].mPosition = nearestPos;
	// input velocities
	b2Vec2 V = liquid[particleIdx].mVelocity;
	float vn = b2Dot(V, normal);	 // impact speed 点乘求向量延反弹方向的转化值 normal为反弹方向的归一化
	//					V -= (2.0f * vn) * normal;
    
	b2Vec2 Vn = vn * normal; // impact velocity vector
	b2Vec2 Vt = V - Vn; // tangencial veloctiy vector (across the surface of collision).
    
	// now the output velocities ('r' for response).
	float restitution = liquid[particleIdx].mRestitution;
	b2Vec2 Vnr = -Vn;
	Vnr.x *= restitution;
	Vnr.y *= restitution;
    
	float invFriction = 1.0f - liquid[particleIdx].mFriction;
	b2Vec2 Vtr = Vt;
	Vtr.x *= invFriction;
	Vtr.y *= invFriction;
    
	// resulting velocity
	V = Vnr + Vtr;
    
	liquid[particleIdx].mVelocity = V;
    //liquid[particleIdx].mPosition = nearestPos;
    
//    
//#ifndef VERLET_INTEGRATION
//	// input velocities
//	b2Vec2 V = liquid[particleIdx].mVelocity;
//	float vn = b2Dot(V, normal);	 // impact speed
//	//					V -= (2.0f * vn) * normal;
//    
//	b2Vec2 Vn = vn * normal; // impact velocity vector
//	b2Vec2 Vt = V - Vn; // tangencial veloctiy vector (across the surface of collision).
//    
//	// now the output velocities ('r' for response).
//	float restitution = liquid[particleIdx].mRestitution;
//	b2Vec2 Vnr = -Vn;
//	Vnr.x *= restitution;
//	Vnr.y *= restitution;
//    
//	float invFriction = 1.0f - liquid[particleIdx].mFriction;
//	b2Vec2 Vtr = Vt;
//	Vtr.x *= invFriction;
//	Vtr.y *= invFriction;
//    
//	// resulting velocity
//	V = Vnr + Vtr;
//    
//	liquid[particleIdx].mVelocity = V;
//#endif
    
    
}

void outBoundsHandle(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
{
    b2Vec2 lastCheckP;
    if(gay != vertsNum - 1)
    {
        if(fabs(verts[gay].x - verts[gay+1].x) < 1e-8)//垂直
        {
            float newX = (verts[gay].x-newP.x)+verts[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
            
        }
        else if(fabs(verts[gay].y - verts[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts[gay].y-newP.y)+verts[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
            
        }
        else
        {
            float k1 = (verts[gay].y - verts[gay+1].y)/(verts[gay].x - verts[gay+1].x);
            float b1 = verts[gay].y - k1*verts[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
        }
        
    }
    else if(gay == vertsNum - 1)
    {
        if(fabs(verts[gay].x - verts[0].x) < 1e-8)//垂直
        {
            float newX = (verts[gay].x-newP.x)+verts[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
            
        }
        else if(fabs(verts[gay].y - verts[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts[gay].y-newP.y)+verts[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
        }
        else
        {
            float k1 = (verts[gay].y - verts[0].y)/(verts[gay].x - verts[0].x);
            float b1 = verts[gay].y - k1*verts[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity += b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
        }
        
    }
    
    if(tolCT(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        liquid[praticleIndex].mPosition = liquid[praticleIndex].mPrePosition;
        //liquid[praticleIndex].mPosition = b2Vec2(-10,-10);
        liquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        liquid[praticleIndex].mOldPosition = liquid[praticleIndex].mPosition;
        liquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void outBoundsHandle1(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
{
    b2Vec2 lastCheckP;
    if(gay != vertsNum1 - 1)
    {
        if(fabs(verts1[gay].x - verts1[gay+1].x) < 1e-8)//垂直
        {
            float newX = (verts1[gay].x-newP.x)+verts1[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts1[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
            
        }
        else if(fabs(verts1[gay].y - verts1[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts1[gay].y-newP.y)+verts1[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts1[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
            
        }
        else
        {
            float k1 = (verts1[gay].y - verts1[gay+1].y)/(verts1[gay].x - verts1[gay+1].x);
            float b1 = verts1[gay].y - k1*verts1[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
        }
        
    }
    else if(gay == vertsNum1 - 1)
    {
        if(fabs(verts1[gay].x - verts1[0].x) < 1e-8)//垂直
        {
            float newX = (verts1[gay].x-newP.x)+verts1[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts1[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
            
        }
        else if(fabs(verts1[gay].y - verts1[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts1[gay].y-newP.y)+verts1[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts1[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
        }
        else
        {
            float k1 = (verts1[gay].y - verts1[0].y)/(verts1[gay].x - verts1[0].x);
            float b1 = verts1[gay].y - k1*verts1[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
        }
        
    }
    
    if(tolCT1(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是咬做特殊处理
        liquid[praticleIndex].mPosition = liquid[praticleIndex].mPrePosition;
        //liquid[praticleIndex].mPosition = b2Vec2(-10,-10);
        liquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        liquid[praticleIndex].mOldPosition = liquid[praticleIndex].mPosition;
        liquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void outBoundsHandle2(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
{
    b2Vec2 lastCheckP;
    if(gay != vertsNum2 - 1)
    {
        if(fabs(verts2[gay].x - verts2[gay+1].x) < 1e-8)//垂直
        {
            float newX = (verts2[gay].x-newP.x)+verts2[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts2[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
            
        }
        else if(fabs(verts2[gay].y - verts2[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts2[gay].y-newP.y)+verts2[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts2[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
            
        }
        else
        {
            float k1 = (verts2[gay].y - verts2[gay+1].y)/(verts2[gay].x - verts2[gay+1].x);
            float b1 = verts2[gay].y - k1*verts2[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
        }
        
    }
    else if(gay == vertsNum2 - 1)
    {
        if(fabs(verts2[gay].x - verts2[0].x) < 1e-8)//垂直
        {
            float newX = (verts2[gay].x-newP.x)+verts2[gay].x;
            float newY = newP.y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts2[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
            
        }
        else if(fabs(verts2[gay].y - verts2[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts2[gay].y-newP.y)+verts2[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts2[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
        }
        else
        {
            float k1 = (verts2[gay].y - verts2[0].y)/(verts2[gay].x - verts2[0].x);
            float b1 = verts2[gay].y - k1*verts2[gay].x;
            float k2 = -1.f/k1;
            float b2 = newP.y - k2*newP.x;
            float newJiaoX = k1*(b2-b1)/(k1*k1+1);
            float newJiaoY = k2*newJiaoX+b2;
            float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
            float newY = 2.f*newJiaoY-newP.y;
            lastCheckP = b2Vec2(newX,newY);
            
            float k3;
            if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
//            liquid[praticleIndex].mVelocity += b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
            SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
        }
        
    }
    
    if(tolCT2(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        liquid[praticleIndex].mPosition = liquid[praticleIndex].mPrePosition;
        //liquid[praticleIndex].mPosition = b2Vec2(-10,-10);
        liquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        liquid[praticleIndex].mOldPosition = liquid[praticleIndex].mPosition;
        liquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void outBoundsHandleSingleVer(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
{
    b2Vec2 lastCheckP;
    if(fabs(singleVers[gay].vec1.x - singleVers[gay].vec2.x) < 1e-8)//垂直
    {
        float newX = (singleVers[gay].vec1.x-newP.x)+singleVers[gay].vec2.x;
        float newY = newP.y;
        lastCheckP = b2Vec2(newX,newY);
        float newVX,newVY;
        float k1;
        if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k1 = 1000000;
        }
        else
        {
            k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
        }
        float jiaoPX = singleVers[gay].vec1.x;
        float jiaoB = newP.y - k1*newP.x;
        float jiaoPY = k1*jiaoPX+jiaoB;
        newVX = (newX-jiaoPX)/deltaT;
        newVY = (newY-jiaoPY)/deltaT;
        
//        liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
        SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
        
    }
    else if(fabs(singleVers[gay].vec1.y - singleVers[gay].vec2.y) < 1e-8)//平行
    {
        float newX = newP.x;
        float newY = (singleVers[gay].vec1.y-newP.y)+singleVers[gay].vec1.y;
        lastCheckP = b2Vec2(newX,newY);
        float newVX,newVY;
        
        float k1;
        if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k1 = 1000000;
        }
        else
        {
            k1 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
        }
        
        float jiaoPY = singleVers[gay].vec1.y;
        float jiaoB = newP.y - k1*newP.x;
        float jiaoPX = (jiaoPY-jiaoB)/k1;
        
        newVX = (newX-jiaoPX)/deltaT;
        newVY = (newY-jiaoPY)/deltaT;
        
//        liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
        SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
        
    }
    else
    {
        float k1 = (singleVers[gay].vec1.y - singleVers[gay].vec2.y)/(singleVers[gay].vec1.x - singleVers[gay].vec2.x);
        float b1 = singleVers[gay].vec1.y - k1*singleVers[gay].vec1.x;
        float k2 = -1.f/k1;
        float b2 = newP.y - k2*newP.x;
        float newJiaoX = k1*(b2-b1)/(k1*k1+1);
        float newJiaoY = k2*newJiaoX+b2;
        float newX = 2.f*newJiaoX-newP.x;     //2.f*newJiaoX - newP.x;
        float newY = 2.f*newJiaoY-newP.y;
        lastCheckP = b2Vec2(newX,newY);
        
        float k3;
        if(fabs(newP.x - liquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k3 = 100000.f;
        }
        else
        {
            k3 = (newP.y - liquid[praticleIndex].mPrePosition.y)/(newP.x - liquid[praticleIndex].mPrePosition.x);
        }
        float b3 = newP.y - k3*newP.x;
        float jiangluoPX = (b3-b1)/(k1-k3);
        float jiangluoPY = k3*jiangluoPX+b3;
        
        float newVX = (newX-jiangluoPX)/(deltaT);
        float newVY = (newY-jiangluoPY)/(deltaT);
        
//        float newVX = (newX-liquid[praticleIndex].mPrePosition.x)/(deltaT);
//        float newVY = (newY-liquid[praticleIndex].mPrePosition.y)/(deltaT);
        
//        liquid[praticleIndex].mVelocity = b2Vec2(newVX,newVY)*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution;//+m_world->GetGravity();
        SeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
    
    }
    if(tolCTSingleVer(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        liquid[praticleIndex].mPosition = liquid[praticleIndex].mPrePosition;
        //liquid[praticleIndex].mPosition = b2Vec2(-10,-10);
        liquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        liquid[praticleIndex].mOldPosition = liquid[praticleIndex].mPosition;
        liquid[praticleIndex].mPosition = lastCheckP;
        
    }

}

void SeparatePraticleFromEdge(int praticleIndex,b2Vec2 newV,float deltaT,b2Vec2 vec1,b2Vec2 vec2)
{

//    //this is the 1 Algorithm 摩擦力和反弹力无法分开
    float lenV = liquid[praticleIndex].mVelocity.Length();
    newV.Normalize();
    newV = newV*lenV;//先求出虚拟无能量损失的反弹速度
    
//    liquid[praticleIndex].mVelocity = newV;

    //边缘水平方向速度
    b2Vec2 level = vec2 - vec1;
    level.Normalize();
    float levelVS = b2Dot(newV, level);
    if(levelVS < 0)
    {
        level = vec1 - vec2;
        level.Normalize();
        levelVS = -1.f*levelVS;
    }
    
    b2Vec2 levelVec = levelVS*level*(1-liquid[praticleIndex].mFriction);//水平方向速度
    
    //边缘垂直反弹方向速度
//    float cosa = fabs(levelVS/(lenV*level.Length()));
//    float angle =  acos(cosa);  //边缘与反弹后的速度的cos夹角
//    float sina =  fabs(sin(angle));
    
    b2Vec2 Vertical = b2Vec2(-level.y,level.x);
    float VerticalVS = b2Dot(newV, Vertical);
    if(VerticalVS < 0)
    {
        Vertical = b2Vec2(level.y,-level.x);
        VerticalVS = -1.f*VerticalVS;
    }
    
    b2Vec2 VerticalVec = VerticalVS*Vertical*liquid[praticleIndex].mRestitution;//水平方向速度
    
    liquid[praticleIndex].mVelocity = levelVec+VerticalVec;//+m_world->GetGravity()*deltaT+liquid[praticleIndex].mForce*deltaT;//VerticalVec; levelVec
    
//    liquid[praticleIndex].mVelocity = newV*lenV*liquid[praticleIndex].mRestitution + (liquid[praticleIndex].mVelocity-newV*lenV*liquid[praticleIndex].mRestitution)*(1-liquid[praticleIndex].mFriction) + m_world->GetGravity()*deltaT+liquid[praticleIndex].mForce*deltaT;//*(1-liquid[praticleIndex].mFriction)*liquid[praticleIndex].mRestitution+m_world->GetGravity()*deltaT;
    
//    b2Vec2 V = liquid[praticleIndex].mVelocity;
//    float lenV = liquid[praticleIndex].mVelocity.Length();
//    newV.Normalize();
//    float vn = b2Dot(V, newV);
//    b2Vec2 Vn = vn * newV;
//    b2Vec2 Vt = V - Vn;
//    
//    // now the output velocities ('r' for response).
//	float restitution = liquid[praticleIndex].mRestitution;
//	b2Vec2 Vnr = -Vn;
//	Vnr.x *= restitution;
//	Vnr.y *= restitution;
//    
//    float invFriction = 1.0f - liquid[praticleIndex].mFriction;
//	b2Vec2 Vtr = Vt;
//	Vtr.x *= invFriction;
//	Vtr.y *= invFriction;
//    
//    // resulting velocity
//	V = Vnr + Vtr;
//    
//    liquid[praticleIndex].mVelocity = V+m_world->GetGravity()*deltaT;


    
    //this is the 2 Algorithm 模仿球和多边形的分离算法 镜面反弹使用反弹力系数 其他方向速度使用摩擦系数衰减
//    b2Vec2 V = liquid[praticleIndex].mVelocity;
//    newV.Normalize();//归一化
//    float vn = b2Dot(V, newV);//点积 求出归一化反弹方向的弹力
//    b2Vec2 Vn = vn * newV;
//    b2Vec2 Vt = V - Vn;
//    
//    // now the output velocities ('r' for response).
//	float restitution = liquid[praticleIndex].mRestitution;
//	b2Vec2 Vnr = -Vn;
//	Vnr.x *= restitution;
//	Vnr.y *= restitution;
//    
//    float invFriction = 1.0f - liquid[praticleIndex].mFriction;
//	b2Vec2 Vtr = Vt;
//	Vtr.x *= invFriction;
//	Vtr.y *= invFriction;
//    
//    // resulting velocity
//	V = Vnr + Vtr;
//
//	liquid[praticleIndex].mVelocity = V+m_world->GetGravity()*deltaT;
    
    
//    b2Vec2 V = liquid[particleIdx].mVelocity;
//	float vn = b2Dot(V, normal);	 // impact speed 点乘求向量延反弹方向的转化值 normal为反弹方向的归一化
//	//					V -= (2.0f * vn) * normal;
//    
//	b2Vec2 Vn = vn * normal; // impact velocity vector
//	b2Vec2 Vt = V - Vn; // tangencial veloctiy vector (across the surface of collision).
//    
//	// now the output velocities ('r' for response).
//	float restitution = liquid[particleIdx].mRestitution;
//	b2Vec2 Vnr = -Vn;
//	Vnr.x *= restitution;
//	Vnr.y *= restitution;
//    
//	float invFriction = 1.0f - liquid[particleIdx].mFriction;
//	b2Vec2 Vtr = Vt;
//	Vtr.x *= invFriction;
//	Vtr.y *= invFriction;
//    
//	// resulting velocity
//	V = Vnr + Vtr;
//    
//	liquid[particleIdx].mVelocity = V;
//    liquid[particleIdx].mPosition = nearestPos;
    
    
    
//    b2PolygonShape* pPolyShape = static_cast<b2PolygonShape*>(fixture->GetShape());
//    const b2Transform& xf = fixture->GetBody()->GetTransform();
//    int numVerts = pPolyShape->GetVertexCount();
//    
//    b2Vec2 vertices[b2_maxPolygonVertices];
//    b2Vec2 normals[b2_maxPolygonVertices];
//    
//    for (int32 i = 0; i < numVerts; ++i)
//    {
//        vertices[i] = b2Mul(xf, pPolyShape->m_vertices[i]);
//        normals[i] = b2Mul(xf.q, pPolyShape->m_normals[i]);
//    }
//    
//    float shortestDistance = 99999.0f;
//    
//    for (int i = 0; i < numVerts ; ++i)
//    {
//        b2Vec2 vertex = vertices[i] + particleRadius * normals[i] - particlePos;
//        float distance = b2Dot(normals[i], vertex);
//        
//        if (distance < 0.0f)
//        {
//            return false;
//        }
//        
//        if (distance < shortestDistance)
//        {
//            shortestDistance = distance;
//            
//            nearestPos = b2Vec2(
//                                normals[i].x * distance + particlePos.x,
//                                normals[i].y * distance + particlePos.y);
//            
//            impactNormal = normals[i];
//        }
//    }
    
}

void stepFluidParticles(float deltaT)
{
	for (int i = 0; i < nParticles; ++i)
	{
        BOOL tolEdge;//是否穿越边界 穿越的桢不产生变形
//        if(liquid[i].isAwake == false) continue;
		// Old-Skool Euler stuff
        b2Vec2 g = m_world->GetGravity();
        liquid[i].mVelocity.x += (g.x * deltaT );
		liquid[i].mVelocity.y += (g.y * deltaT );
        
        liquid[i].mVelocity.x += liquid[i].mForce.x * deltaT;
		liquid[i].mVelocity.y += liquid[i].mForce.y * deltaT;
        
        b2Vec2 newP = liquid[i].mPosition + liquid[i].mVelocity*deltaT;
        
        int gay = tolCT(i,newP);
        int gay1 = tolCT1(i,newP);
        int gay2 = tolCT2(i,newP);
        int gay3 = tolCTSingleVer(i,newP);
        
        if(gay != -1)
        {
            if(liquid[i].allowTolCount > 0)
            {
                liquid[i].allowTolCount--;
                liquid[i].mOldPosition = liquid[i].mPosition;
                liquid[i].mPosition = newP;
            }
            else
            {
                outBoundsHandle(gay,newP,i,deltaT);
                tolEdge = YES;
            }
        }
        else if(gay1 != -1)
        {
            if(liquid[i].allowTolCount > 0)
            {
                liquid[i].allowTolCount--;
                liquid[i].mOldPosition = liquid[i].mPosition;
                liquid[i].mPosition = newP;
            }
            else
            {
                outBoundsHandle1(gay1,newP,i,deltaT);
                tolEdge = YES;
            }
        }
        
        else if(gay2 != -1 )
        {
            if(liquid[i].allowTolCount > 0)
            {
                liquid[i].allowTolCount--;
                liquid[i].mOldPosition = liquid[i].mPosition;
                liquid[i].mPosition = newP;
            }
            else
            {
                outBoundsHandle2(gay2,newP,i,deltaT);
                tolEdge = YES;
            }
        }
        
        else if(gay3 != -1)
        {
            if(liquid[i].allowTolCount > 0)
            {
                liquid[i].allowTolCount--;
                liquid[i].mOldPosition = liquid[i].mPosition;
                liquid[i].mPosition = newP;
            }
            else
            {
                outBoundsHandleSingleVer(gay3,newP,i,deltaT);
                tolEdge = YES;
            }
        }
        else
        {
            liquid[i].mOldPosition = liquid[i].mPosition;
            liquid[i].mPosition = newP;//liquid[i].mVelocity;
        }
        
//        if(gay != -1 || gay1 != -1 || gay2 != -1 || gay3 != -1)
//        {
//            if(liquid[i].allowTolCount > 0)
//            {
//                liquid[i].allowTolCount--;
//                break;
//            }
//            if(gay != -1 && gay1 == -1 && gay2 == -1 && gay3 == -1)
//            {
//                outBoundsHandle(gay,newP,i,deltaT);
//                tolEdge = YES;
//            }
//            if(gay == -1 && gay1 != -1 && gay2 == -1 && gay3 == -1)
//            {
//                outBoundsHandle1(gay,newP,i,deltaT);
//                tolEdge = YES;
//            }
//            if(gay == -1 && gay1 == -1 && gay2 != -1 && gay3 == -1)
//            {
//                outBoundsHandle2(gay,newP,i,deltaT);
//                tolEdge = YES;
//            }
//            if(gay == -1 && gay1 == -1 && gay2 == -1 && gay3 != -1)
//            {
//                outBoundsHandleSingleVer(gay3,newP,i,deltaT);
//                tolEdge = YES;
//            }
//            else
//            {
//                liquid[i].mPosition = b2Vec2(-10,-10);
//                liquid[i].mOldPosition = liquid[i].mPosition;
//                liquid[i].mPrePosition = liquid[i].mPosition;
//            }
//        }
//        else
//        {
//            liquid[i].mOldPosition = liquid[i].mPosition;
//            liquid[i].mPosition = newP;//liquid[i].mVelocity;
//        }
        
        int hcell = hashX(liquid[i].mPosition.x);
		int vcell = hashY(liquid[i].mPosition.y);

        float vSqr = liquid[i].mVelocity.LengthSquared();

        addBuddle2(i,vSqr,hcell,vcell);
        
        if(liquid[i].ifFanDeHuaForce == false && liquid[i].isAwake == true)// || liquid[i].inittick < 60))//变形
        {
            if(liquid[i].sp != nil)liquid[i].sp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
            liquid[i].sp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
        }
        else
        {
            if(liquid[i].sp != nil)liquid[i].sp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
            liquid[i].sp.scaleX = clampf(1.f, 1.f, 1.f);
            liquid[i].sp.scale = 1.0;
        }
        liquid[i].ifFanDeHuaForce = true;
        liquid[i].mForce = b2Vec2(0,0);
    }
    
}

//气泡
void addBuddle(int i,float vSqr,int hcell,int vcell)
{
    //气泡粒子检测和显示
    //处于水流中央 ID处于簇内 速度在限定范围内 当前气泡个数小于上线值 则产生新气泡 否则产生
    if( hashGridList[hcell][vcell].groupFlag == 255 && hashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity &&buddleNum <= nAwakeParticles/250 && liquid[i].isBuddlePraticle == false && liquid[i].inittick > 60)//
    {
        liquid[i].buddleSp = [CCSprite spriteWithFile:@"blue_circle_small.png"];
        [ParticleBuddleBatch addChild:liquid[i].buddleSp];
        liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
        liquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
        liquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
        liquid[i].buddleSp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
        
        liquid[i].isBuddlePraticle = true;
        liquid[i].buddleTick++;
        buddleNum++;
    }
    //消除旧的不合格气泡
    else if((liquid[i].isBuddlePraticle == true) && (hashGridList[hcell][vcell].groupFlag != 255 || hashGridList[hcell][vcell].groupID == -1 || vSqr < buddleVelocity))
    {
        if(liquid[i].buddleSp != nil)
        {
            [liquid[i].buddleSp removeFromParentAndCleanup:YES];
            liquid[i].buddleSp = nil;
        }
        liquid[i].buddleTick = 0;
        liquid[i].isBuddlePraticle = false;
        buddleNum--;
    }
    //气泡运动和大小变化
    else if(liquid[i].isBuddlePraticle == true && hashGridList[hcell][vcell].groupFlag == 255 &&  hashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity)
    {
        if(liquid[i].buddleSp == nil)
        {
            liquid[i].buddleSp = [CCSprite spriteWithFile:@"blue_circle_big,png"];
            [ParticleBuddleBatch addChild:liquid[i].buddleSp];
            liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
            liquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
            liquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
            liquid[i].buddleSp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
            
        }
        else
        {
            liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
            liquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
            liquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
            liquid[i].buddleSp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
        }
        liquid[i].buddleTick++;
    }
    
}

//气泡2 匀速上升运动气泡
void addBuddle2(int i,float vSqr,int hcell,int vcell)
{
    //气泡粒子检测和显示
    //处于水流中央 ID处于簇内 速度在限定范围内 当前气泡个数小于上限值 则产生新气泡 否则禁止
    if(hcell < 0 ||  vcell < 0 || fabs(vSqr) < 1e-12 || hcell > hashWidth  || vcell > hashHeight)return;
    
    int buddlehcell = 0;
    int buddlevcell = 0;
    if(liquid[i].buddleSp != nil)
    {
        buddlehcell = hashX(liquid[i].buddleSp.position.x/PTM_RATIO);
        buddlevcell = hashY(liquid[i].buddleSp.position.y/PTM_RATIO);
    }
    
    if( hashGridList[hcell][vcell].groupFlag == 255 && hashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity && buddleNum <= nAwakeParticles/350 && liquid[i].isBuddlePraticle == false && liquid[i].inittick > 60)//
    {
        liquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
        liquid[i].buddleSp.opacity = 160;
        [ParticleBuddleBatch addChild:liquid[i].buddleSp];
        //liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
        liquid[i].buddleSp.scaleX = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
        liquid[i].buddleSp.scaleY = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
        liquid[i].buddleSp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
        
        liquid[i].isBuddlePraticle = true;
        liquid[i].buddleTick++;
        buddleNum++;
    }
    else if(nAwakeParticles > 200 && buddleNum <= nAwakeParticles/350 && hashGridList[hcell][vcell].groupFlag == 255 && hashGridList[hcell][vcell].groupID != -1 && liquid[i].isBuddlePraticle == false && liquid[i].inittick > 60)
    {
        liquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
        liquid[i].buddleSp.opacity = 160;
        [ParticleBuddleBatch addChild:liquid[i].buddleSp];
        //liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
        liquid[i].buddleSp.scale = (.5f+.1f*(float)(rand()%5))/8.f;
        liquid[i].buddleSp.position = ccp(32.f * liquid[i].mPosition.x, 32.f * liquid[i].mPosition.y);
        
        liquid[i].isBuddlePraticle = true;
        liquid[i].buddleTick++;
        buddleNum++;
    }
    
    //消除旧的不合格气泡 假设气泡属于匀速上升运动
    //表面张力逐渐扩大 气泡大小逐渐扩大
    //消除的可能性为气泡上升过程中
    //1自动破裂或者上升到流体 2与空气接触面时马上破裂
    //else if((liquid[i].isBuddlePraticle == true) && (hashGridList[hcell][vcell].groupFlag != 255 || hashGridList[hcell][vcell].groupID == -1 || vSqr < buddleVelocity))
    else if((liquid[i].isBuddlePraticle == true) && liquid[i].buddleSp != nil && (hashGridList[buddlehcell][buddlevcell].groupFlag&255) == 0)//&8
    {
        if(liquid[i].buddleSp != nil)
        {
            [liquid[i].buddleSp removeFromParentAndCleanup:YES];
            liquid[i].buddleSp = nil;
        }
        liquid[i].buddleTick = 0;
        liquid[i].isBuddlePraticle = false;
        buddleNum--;
    }
    //气泡运动 匀速上升运动 直至到达流体表面破裂
    //else if(liquid[i].isBuddlePraticle == true && hashGridList[hcell][vcell].groupFlag == 255 &&  hashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity)
    else if(liquid[i].isBuddlePraticle == true)
    {
        if(liquid[i].buddleSp == nil)
        {
            liquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
            liquid[i].buddleSp.opacity = 160;
            [ParticleBuddleBatch addChild:liquid[i].buddleSp];
            //liquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(liquid[i].mVelocity.x, liquid[i].mVelocity.y)));
            liquid[i].buddleSp.scaleX = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
            liquid[i].buddleSp.scaleY = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
            
        }
        liquid[i].buddleSp.position = ccp(liquid[i].buddleSp.position.x,liquid[i].buddleSp.position.y+rand()%2+1);
        liquid[i].buddleTick++;
    }
    
}

void resolveIntersections(float deltaT)
{
	// Iterate through the grid, and do an AABB test for every grid containing particles
	for (int x = 0; x < hashWidth; ++x)
	{
		for (int y = 0; y < hashHeight; ++y)//hashWidth?why
		{
			if(!hashGridList[x][y].IsEmpty())
			{
				float minX = myMap((float)x, 0, hashWidth, fluidMinX, fluidMaxX);
				float maxX = myMap((float)x+1, 0, hashWidth, fluidMinX, fluidMaxX);
				float minY = myMap((float)y, 0, hashHeight, fluidMinY, fluidMaxY);
				float maxY = myMap((float)y+1, 0, hashHeight, fluidMinY, fluidMaxY);
                
				b2AABB aabb;
                
				aabb.lowerBound.Set(minX, minY);
				aabb.upperBound.Set(maxX, maxY);
                
                eulerIntersectQueryCallback->x = x;
                eulerIntersectQueryCallback->y = y;
                eulerIntersectQueryCallback->deltaT = deltaT;
                m_world->QueryAABB(eulerIntersectQueryCallback, aabb);
			}
		}
	}
    
}

int tolCT(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum == 0) return -1;
    for(int j = 0; j < vertsNum;j++)
    {
        if(j != vertsNum-1)
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts[j],verts[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts[j],verts[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

int tolCT1(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum1 == 0) return -1;
    for(int j = 0; j < vertsNum1;j++)
    {
        if(j != vertsNum1-1)
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts1[j],verts1[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts1[j],verts1[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

int tolCT2(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum2 == 0) return -1;
    for(int j = 0; j < vertsNum2;j++)
    {
        if(j != vertsNum2-1)
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts2[j],verts2[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(intersect_in(newP,liquid[praticleIndex].mPrePosition,verts2[j],verts2[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

//单条边界的碰撞检测反应 用于非闭合碰撞区间
int tolCTSingleVer(int praticleIndex, b2Vec2 newP)
{
    if(singleVerNum == 0) return -1;
    for(int j = 0; j < singleVerNum;j++)
    {
        if(intersect_in(newP,liquid[praticleIndex].mPrePosition,singleVers[j].vec1,singleVers[j].vec2) != 0)
        {
            return j;
        }
    }
    return -1;
    
}


//计算交叉乘积(P1-P0)x(P2-P0)
double xmult(b2Vec2 p1,b2Vec2 p2,b2Vec2 p0)
{
    return (p1.x-p0.x)*(p2.y-p0.y)-(p2.x-p0.x)*(p1.y-p0.y);
}

//判点是否在线段上,包括端点
int dot_online_in(b2Vec2 p,b2Vec2 l1,b2Vec2 l2)
{
    return zero(xmult(p,l1,l2))&&(l1.x-p.x)*(l2.x-p.x)<eps&&(l1.y-p.y)*(l2.y-p.y)<eps;
}

//判两点在线段同侧,点在线段上返回0
int same_side(b2Vec2 p1,b2Vec2 p2,b2Vec2 l1,b2Vec2 l2)
{
    return xmult(l1,p1,l2)*xmult(l1,p2,l2)>eps;
}

//判三点共线
int dots_inline(b2Vec2 p1,b2Vec2 p2,b2Vec2 p3)
{
    return zero(xmult(p1,p2,p3));
}

//判两线段相交,包括端点和部分重合
int intersect_in(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
{
    if (!dots_inline(u1,u2,v1)||!dots_inline(u1,u2,v2))
        return !same_side(u1,u2,v1,v2)&&!same_side(v1,v2,u1,u2);
    return dot_online_in(u1,v1,v2)||dot_online_in(u2,v1,v2)||dot_online_in(v1,u1,u2)||dot_online_in(v2,u1,u2);
}

//计算两线段交点,请判线段是否相交(同时还是要判断是否平行!)
b2Vec2 intersection(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
{
    if(intersect_in(u1,u2,v1,v2)==0)return b2Vec2(0,0);
    
    b2Vec2 ret=u1;
    double t=((u1.x-v1.x)*(v1.y-v2.y)-(u1.y-v1.y)*(v1.x-v2.x))
    /((u1.x-u2.x)*(v1.y-v2.y)-(u1.y-u2.y)*(v1.x-v2.x));
    ret.x+=(u2.x-u1.x)*t;
    ret.y+=(u2.y-u1.y)*t;
    return ret;
}

//直线与线段交点 前两个为直线坐标 后两个为线段坐标
b2Vec2 intersectionStraight(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
{
    float x,y,k1,k2;
    
    if(fabs(u1.x-u2.x) < b2_epsilon && fabs(v1.x-v2.x) < b2_epsilon)//两条都是平行线
    {
        return b2Vec2(0.f,0.f);
    }
    if(fabs(u1.x-u2.x) < b2_epsilon)//直线垂直线的特殊处理
    {
        x = u1.x;
        y = ((v1.y-v2.y)/(v1.x-v2.x))*x;
        return b2Vec2(x,y);
    }
    if(fabs(v1.x-v2.x) < b2_epsilon)//线段垂直线的特殊处理
    {
        x = v1.x;
        y = ((u1.y-u2.y)/(u1.x-u2.x))*x;
        return b2Vec2(x,y);
    }
    
    k1=(u1.y-u2.y)/(u1.x-u2.x);
    k2=(v1.y-v2.y)/(v1.x-v2.x);
    
    if(k1 == k2)return b2Vec2(0.f,0.f);//平行线做特殊处理
    
    x=(k1*u1.x-k2*v1.x+v1.y-u1.y)/(k1-k2);
    y=u1.y+(x-u1.x)*k1;
    
    //前面求的是两条直线的交点 如果该点在后者线段线段上
    if(dot_online_in(b2Vec2(x,y),v1,v2)!=0)
        return b2Vec2(x,y);
    else
        return b2Vec2(0.f,0.f);
    return b2Vec2(x,y);
    
}


//判断给定点pt是否在多边形poly内

//返回0在内部，-1在外面
//返回> 0表示点在第几条有向线段上

int SideOfLine(b2Vec2 p1, b2Vec2 p2, b2Vec2 pt)
{
    enum POS {RR =-1, ON = 0, LL = 1};
    //右侧、线上、左侧
    //叉积的两个子项
    double c1 = (p2.x - pt.x) * (pt.y - p1.y);
    double c2 = (p2.y - pt.y) * (pt.x - p1.x);
    return c1 > c2 ? LL : (c1 < c2 ? RR : ON);
    
}
// 判断给定点 pt 是否在多边形 poly 内 // 返回 0 在内部，-1 在外面
// 返回 > 0 表示点在第几条有向线段上

//int PtInPoly(b2Vec2 pt, POLY *poly)
int PtInPoly(b2Vec2 pt, b2Vec2 *poly,int count)
{
    int i;
    int status, lastStauts;
    int cnt = 0;
    int pos, temp;
    lastStauts = (poly[0].y > pt.y) ? 1: ((poly[0].y == pt.y) ? 0 : -1);
    for(i = 1; i < count; ++i)
    //for(i = 0; i < count; ++i)
    {
        status = (poly[i].y > pt.y) ? 1: ((poly[i].y < pt.y) ? -1 : 0);
        temp = status - lastStauts;
        lastStauts = status;
        pos = SideOfLine(poly[i-1], poly[i], pt);
        
        //点在有向线段上
        if(pos == 0 && ((poly[i-1].x <= pt.x &&  pt.x <= poly[i].x)|| (poly[i-1].x >= pt.x && pt.x >= poly[i].x))&& ((poly[i-1].y <= pt.y &&  pt.y <= poly[i].y)|| (poly[i-1].y >= pt.y && pt.y >= poly[i].y)))
            return i;
        //跨越
        if((temp > 0&&pos == 1)||(temp < 0&&pos == -1))
            cnt += temp;
    }
    return cnt == 0 ? -1 : 0;
    
}

// 功能：判断点是否在多边形内
// 方法：求解通过该点的水平线与多边形各边的交点
// 结论：单边交点为奇数，成立!
//参数：
// POINT p 指定的某个点
// LPPOINT ptPolygon 多边形的各个顶点坐标（首末点可以不一致）
// int nCount 多边形定点的个数
bool PtInPolygon(b2Vec2 p,b2Vec2* ptPolygon,int nCount)
{
    int nCross = 0;
    for (int i = 0; i < nCount; i++)
    {
        b2Vec2 p1 = ptPolygon[i];
        b2Vec2 p2 = ptPolygon[(i + 1) % nCount];
        // 求解 y=p.y 与 p1p2 的交点
        if ( p1.y == p2.y ) // p1p2 与 y=p0.y平行
            continue;
        if ( p.y < min(p1.y, p2.y) ) // 交点在p1p2延长线上
            continue;
        if ( p.y >= max(p1.y, p2.y) ) // 交点在p1p2延长线上
            continue;
        // 求交点的 X 坐标 --------------------------------------------------------------
        double x = (double)(p.y - p1.y) * (double)(p2.x - p1.x) / (double)(p2.y - p1.y) + p1.x;
        if ( x > p.x )
            nCross++; // 只统计单边交点
    }
    // 单边交点为偶数，点在多边形之外 ---
    return (nCross % 2 == 1);
    
}

void drawTestGrid()
{
    float dX = fluidMaxX*32/hashWidth; //40;//(fluidMaxX - fluidMinX);
    float dY = fluidMaxY*32/hashHeight;//40;//(fluidMaxY - fluidMinY);
    
    for(int i = 0; i < hashWidth; i++)
    {
        ccDrawLine(ccp((i+1)*dX,0), ccp((i+1)*dX,hashHeight*dY));
    }
    for(int i = 0; i < hashHeight; i++)
    {
         ccDrawLine(ccp(0,(i+1)*dX), ccp(hashWidth*dX,(i+1)*dX));
    }

}


//聚簇操作
void cateGory(int xIndex, int yIndex)
{
    int groupNumWeights = 0;//设定一个网格最少有多少个粒子才能成为聚类条件网格

    for(int i = xIndex; i < hashWidth; i++)
    {
        for(int j = yIndex; j < hashHeight; j++)
        {
//            int pNum = hashGridList[i][j].GetSize();
            if(hashGridList[i][j].ifNOCountineIterator == true && (xIndex != 0 || yIndex != 0) && hashGridList[i][j].GetSize() > groupNumWeights)
            {
                //if(pNum != 0)NSLog(@"haha1 x:%d y:%d groupid:%d pNum:%d",i,j,groupID,pNum);
                
                if((i+1) < hashWidth)//继续迭代右边聚类判断
                {
                    if(hashGridList[i+1][j].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|1;
                        hashGridList[i+1][j].groupFlag = hashGridList[i+1][j].groupFlag|2;
                        hashGridList[i+1][j].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i+1][j].neiGroupFlag = hashGridList[i+1][j].neiGroupFlag|2;
                    }
                }
                //只做一次左边情况的特殊判断 这个是否会打乱分组还需研究 打乱的话 将改组单独分出
                if((i-1) > -1)
                {
                    if(hashGridList[i-1][j].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|2;
                        hashGridList[i-1][j].groupFlag = hashGridList[i-1][j].groupFlag|1;
                        hashGridList[i-1][j].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i-1][j].neiGroupFlag = hashGridList[i-1][j].neiGroupFlag|1;
                    }
                }
                
                if((j+1) < hashHeight)//继续迭代上边聚类判断
                {
                    if(hashGridList[i][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|8;
                        hashGridList[i][j+1].groupFlag = hashGridList[i][j+1].groupFlag|4;
                        hashGridList[i][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i][j+1].neiGroupFlag = hashGridList[i][j+1].neiGroupFlag|4;
                    }
                }
                //只做一次下边情况的特殊判断  打乱的话 将改组单独分出
                if((j-1) > -1)
                {
                    if(hashGridList[i][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|4;
                        hashGridList[i][j-1].groupFlag = hashGridList[i][j-1].groupFlag|8;
                        hashGridList[i][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i][j-1].neiGroupFlag = hashGridList[i][j-1].neiGroupFlag|8;
                    }
                }
                //左上
                if((i-1)>-1&&(j+1)<hashHeight)
                {
                    if(hashGridList[i-1][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|128;
                        hashGridList[i-1][j+1].groupFlag = hashGridList[i-1][j+1].groupFlag|64;
                        hashGridList[i-1][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i-1][j+1].neiGroupFlag = hashGridList[i-1][j+1].neiGroupFlag|64;
                    }
                }
                //右下
                if((i+1)<hashWidth&&(j-1)>-1)
                {
                    if(hashGridList[i+1][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|64;
                        hashGridList[i+1][j-1].groupFlag = hashGridList[i+1][j-1].groupFlag|128;
                        hashGridList[i+1][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i+1][j-1].neiGroupFlag = hashGridList[i+1][j-1].neiGroupFlag|128;
                    }
                }
                //右上
                if((i+1)<hashWidth&&(j+1)<hashHeight)
                {
                    if(hashGridList[i+1][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|32;
                        hashGridList[i+1][j+1].groupFlag = hashGridList[i+1][j+1].groupFlag|16;
                        hashGridList[i+1][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i+1][j+1].neiGroupFlag = hashGridList[i+1][j+1].neiGroupFlag|16;
                    }
                }
                //左下
                if((i-1)>-1&&(j-1)>-1)
                {
                    if(hashGridList[i-1][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|16;
                        hashGridList[i-1][j-1].groupFlag = hashGridList[i-1][j-1].groupFlag|32;
                        hashGridList[i-1][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i-1][j-1].neiGroupFlag = hashGridList[i-1][j-1].neiGroupFlag|32;
                    }
                }

                return;
            }
            else if(hashGridList[i][j].ifNOCountineIterator == true && (xIndex == 0 || yIndex == 0))
            {
                continue;
            }
            
            if(hashGridList[i][j].GetSize() <= groupNumWeights && (xIndex != 0 || yIndex != 0))
            {
                return;
            }
            else if(hashGridList[i][j].GetSize() <= groupNumWeights && (xIndex == 0 && yIndex == 0))//最早的第一次迭代 不能中断第一次循环
            {
                hashGridList[i][j].groupFlag = 0;
                hashGridList[i][j].groupID = -1;
                hashGridList[i][j].ifNOCountineIterator = true;
                continue;
            }
            else if(hashGridList[i][j].GetSize() > groupNumWeights && hashGridList[i][j].ifNOCountineIterator == false)
            {
                //hashGridList[i][j].groupFlag = 0;
                //here can't be 0  or miss last Iterator data
                //左上 右下 右上 左下 上 下 左 右 11111111
                hashGridList[i][j].ifNOCountineIterator = true;
                if(hashGridList[i][j].groupID == -1)
                {
                    hashGridList[i][j].groupID = (++groupID);
                }
                if((i+1) < hashWidth)//继续迭代右边聚类判断
                {
                    if(hashGridList[i+1][j].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|1;
                        hashGridList[i+1][j].groupFlag = hashGridList[i+1][j].groupFlag|2;
                        hashGridList[i+1][j].groupID = hashGridList[i][j].groupID;
                    }
                    else if(hashGridList[i+1][j].GetSize() == 0)
                    {
                        hashGridList[i+1][j].neiGroupFlag = hashGridList[i+1][j].neiGroupFlag|2;
                    }
                    //[self cateGory:(i+1) yIndex:j];
                    cateGory(i+1,j);
                }
                //只做一次左边情况的特殊判断 这个是否会打乱分组还需研究 打乱的话 将改组单独分出
                if((i-1) > -1)
                {
                    if(hashGridList[i-1][j].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|2;
                        hashGridList[i-1][j].groupFlag = hashGridList[i-1][j].groupFlag|1;
                        hashGridList[i-1][j].groupID = hashGridList[i][j].groupID;
                    }
                    else if(hashGridList[i-1][j].GetSize() == 0)
                    {
                         hashGridList[i-1][j].neiGroupFlag = hashGridList[i-1][j].neiGroupFlag|1;
                    }
                    //[self cateGory:(i-1) yIndex:j];
                    cateGory(i-1,j);
                }
                
                if((j+1) < hashHeight)//继续迭代上边聚类判断
                {
                    if(hashGridList[i][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|8;
                        hashGridList[i][j+1].groupFlag = hashGridList[i][j+1].groupFlag|4;
                        hashGridList[i][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else 
                    {
                        hashGridList[i][j+1].neiGroupFlag = hashGridList[i][j+1].neiGroupFlag|4;
                    }
                    //[self cateGory:i yIndex:(j+1)];
                    cateGory(i,j+1);
                }
                //只做一次下边情况的特殊判断  打乱的话 将改组单独分出
                if((j-1) > -1)
                {
                    if(hashGridList[i][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|4;
                        hashGridList[i][j-1].groupFlag = hashGridList[i][j-1].groupFlag|8;
                        hashGridList[i][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i][j-1].neiGroupFlag = hashGridList[i][j-1].neiGroupFlag|8;
                    }
                    //[self cateGory:i yIndex:(j-1)];
                    cateGory(i,j-1);
                }
                //左上
                if((i-1)>-1&&(j+1)<hashHeight)
                {
                    if(hashGridList[i-1][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|128;
                        hashGridList[i-1][j+1].groupFlag = hashGridList[i-1][j+1].groupFlag|64;
                        hashGridList[i-1][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i-1][j+1].neiGroupFlag = hashGridList[i-1][j+1].neiGroupFlag|64;
                    }
                    //[self cateGory:(i-1) yIndex:(j+1)];
                    cateGory(i-1,j+1);
                }
                //右下
                if((i+1)<hashWidth&&(j-1)>-1)
                {
                    if(hashGridList[i+1][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|64;
                        hashGridList[i+1][j-1].groupFlag = hashGridList[i+1][j-1].groupFlag|128;
                        hashGridList[i+1][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i+1][j-1].neiGroupFlag = hashGridList[i+1][j-1].neiGroupFlag|128;
                    }
                    //[self cateGory:(i+1) yIndex:(j-1)];
                    cateGory(i+1,j-1);
                }
                //右上
                if((i+1)<hashWidth&&(j+1)<hashHeight)
                {
                    if(hashGridList[i+1][j+1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|32;
                        hashGridList[i+1][j+1].groupFlag = hashGridList[i+1][j+1].groupFlag|16;
                        hashGridList[i+1][j+1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i+1][j+1].neiGroupFlag = hashGridList[i+1][j+1].neiGroupFlag|16;
                    }
                    //[self cateGory:(i+1) yIndex:(j+1)];
                    cateGory(i+1,j+1);
                }
                //左下
                if((i-1)>-1&&(j-1)>-1)
                {
                    if(hashGridList[i-1][j-1].GetSize() > groupNumWeights)
                    {
                        hashGridList[i][j].groupFlag = hashGridList[i][j].groupFlag|16;
                        hashGridList[i-1][j-1].groupFlag = hashGridList[i-1][j-1].groupFlag|32;
                        hashGridList[i-1][j-1].groupID = hashGridList[i][j].groupID;
                    }
                    else
                    {
                        hashGridList[i-1][j-1].neiGroupFlag = hashGridList[i-1][j-1].neiGroupFlag|32;
                    }
                    //[self cateGory:(i-1) yIndex:(j-1)];
                    cateGory(i-1,j-1);
                }
                
            }
        }
    }
    
    
//    if(groupID > 0)
//    {
//        int groupNum[groupID];
//        int groupLimitNum = 50;
//        for(int i = xIndex; i < hashWidth; i++)
//        {
//            for(int j = yIndex; j < hashHeight; j++)
//            {
//                for(int k = 1; k <= groupID; k++)
//                {
//                    if(hashGridList[i][j].groupID == groupID)
//                    {
//                        groupNum[k] = groupNum[k] + hashGridList[i][j].GetSize();
//                    }
//                    
//                }
//            }
//        }
    
//        for(int i = xIndex; i < hashWidth; i++)
//        {
//            for(int j = yIndex; j < hashHeight; j++)
//            {
//                for(int k = 1; k <= groupID; k++)
//                {
//                    if(hashGridList[i][j].groupID == groupID && groupNum[k] < groupLimitNum)
//                    {
//                        hashGridList[i][j].groupID = -2;
//                    }
//                    
//                }
//            }
//        }
//    }
    
}

ccVertex2F ccv(CGFloat x, CGFloat y)
{
    ccVertex2F p;
    p.x = x;
    p.y = y;
    return p;
}

struct rgba
{
    float r;
    float g;
    float b;
    float a;
};

typedef struct rgba rgba;


//求圆与网格的交点并且尝试绘制
void fluidRender5()
{
    int gridWi = fluidMaxX*32/hashWidth;;
    int gridHe = fluidMaxY*32/hashHeight;
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            for(int gID = 1; gID <= groupID;gID++)
            {
                if(hashGridList[i][j].groupID == gID)
                {
                    if((hashGridList[i][j].groupFlag) != 255 )
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*gridWi+gridWi/2,j*gridHe+gridHe/2);
                        segmentPos[1] = ccv(i*gridWi,(j+1)*gridHe);
                        segmentPos[2] = ccv((i+1)*gridWi,(j+1)*gridHe);
                        segmentPos[3] = ccv((i+1)*gridWi,(j)*gridHe);
                        segmentPos[4] = ccv((i)*gridWi,(j)*gridHe);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        glColor4ub( 255, 0, 0, 255 );
                        
                        glEnable( GL_TEXTURE_2D );

                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                }
            }
        }
    }
    
}

//求圆与网格的交点并且尝试绘制
void fluidRender4()
{
    float circleR = 60.f;
    for (int i = 0; i < nParticles; ++i)
    {
        //x2+y2=r2 
        float pX = liquid[i].mPosition.x*32.f;
        float pY = liquid[i].mPosition.y*32.f;
        
        int yuX = (int)pX%40;
        int yuY = (int)pY%40;
        
        int verNum = 0;
        
        //求解上下左右四根直线和水滴形成的圆的位置关系
        //上直线
        if((int)(pY+circleR/2)%40 == 0)//一个交点
        {
            verNum++;
        }
        else if(yuY+circleR/2 > 40)//两个交点；
        {
            verNum = verNum+2;
        }
        else 
        {
            
        }
        //下直线
        if((int)(pY-circleR/2)%40 == 0)//一个交点
        {
            verNum++;
        }
        else if(yuY < circleR/2)//两个交点；
        {
            verNum = verNum+2;
        }
        else
        {
            
        }
        //左直线
        if((int)(pX-circleR/2)%40 == 0)//一个交点
        {
            verNum++;
        }
        else if(yuX < circleR/2)//两个交点；
        {
            verNum = verNum+2;
        }
        else
        {
            
        }
        //右直线
        if((int)(pX+circleR/2)%40 == 0)//一个交点
        {
            verNum++;
        }
        else if(yuX+circleR/2 > 40)//两个交点；
        {
            verNum = verNum+2;
        }
        else
        {
            
        }
        
        ccVertex2F segmentPos[ verNum+2 ];
        ccVertex2F texturePos[ verNum+2 ];
        
        //求交点
        int k = 0;
        //上直线
        if((int)(pY+circleR/2)%40 == 0)//一个交点
        {
            segmentPos[++k] = ccv(pX,pY+circleR/2);
        }
        else if(yuY+circleR/2 > 40)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuY)*(40-yuY));
            segmentPos[++k] = ccv(pX + dis,pY+40-yuY);
            segmentPos[++k] = ccv(pX - dis,pY+40-yuY);
        }
        else
        {
            
        }
        //下直线
        if((int)(pY-circleR/2)%40 == 0)//一个交点
        {
            segmentPos[++k] = ccv(pX,pY-circleR/2);
        }
        else if(yuY < circleR/2)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(yuY)*(yuY));
            segmentPos[++k] = ccv(pX + dis,pY-yuY);
            segmentPos[++k] = ccv(pX - dis,pY-yuY);
        }
        else
        {
            
        }
        //左直线
        if((int)(pX-circleR/2)%40 == 0)//一个交点
        {
            segmentPos[++k] = ccv(pX-circleR/2,pY);
        }
        else if(yuX < circleR/2)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(yuX)*(yuX));
            segmentPos[++k] = ccv(pX-yuX,pY + dis);
            segmentPos[++k] = ccv(pX-yuX,pY - dis);
        }
        else
        {
            
        }
        //右直线
        if((int)(pX+circleR/2)%40 == 0)//一个交点
        {
            segmentPos[++k] = ccv(pX+circleR/2,pY);
        }
        else if(yuX+circleR/2 > 40)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuX)*(40-yuX));
            segmentPos[++k] = ccv(pX+40-yuX,pY + dis);
            segmentPos[++k] = ccv(pX+40-yuX,pY - dis);
        }
        else
        {
            
        }
        
        segmentPos[0] = ccv(pX,pY);
        texturePos[0] = ccv(.5f,.5f);
        float angAve = 2.f*3.1415926/verNum;
        for(int j = 1; j < verNum+1; j++)
        {
            texturePos[j] = ccv((sin(angAve*(j-1))+1.f)*.5f,cos((angAve*(j-1))+1.f)*.5f);
        }
        texturePos[verNum+1] = texturePos[1];
        segmentPos[verNum+1] = segmentPos[1];
        
        
        glColor4ub( 155, 210, 210, 255 );
        
        glEnable( GL_TEXTURE_2D );
        
        glDisableClientState( GL_COLOR_ARRAY );
        
        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
        
        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
        
        glDrawArrays( GL_TRIANGLE_FAN, 0, verNum+2);
    }
    
}

//给不同分组的水滴网格分配不同的颜色
void fluidRender3()
{
//    glBindTexture(GL_TEXTURE_2D, [texture name]);
    
    rgba x[] = {{255,255,110,255},{255,110,110,255},{110,255,255,255},{110,255,110,255},{255,110,110,255},{155,155,255,255},{155,255,155,255},{155,55,155,255},{155,255,55,255}};
    
    int gridWi = fluidMaxX*32/hashWidth;
    int gridHe = fluidMaxY*32/hashHeight;
    
    
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            for(int gID = 1; gID <= groupID;gID++)
            {
                if(hashGridList[i][j].groupID == gID)
                {
                    ccVertex2F segmentPos[ 6 ];
                    ccVertex2F texturePos[ 6 ];
                    
                    segmentPos[0] = ccv(i*gridWi+gridWi/2,j*gridHe+gridHe/2);
                    segmentPos[1] = ccv(i*gridWi,(j+1)*gridHe);
                    segmentPos[2] = ccv((i+1)*gridWi,(j+1)*gridHe);
                    segmentPos[3] = ccv((i+1)*gridWi,(j)*gridHe);
                    segmentPos[4] = ccv((i)*gridWi,(j)*gridHe);
                    segmentPos[5] = segmentPos[ 1 ];
                    
                    texturePos[0] = ccv(.5f,.5f);
                    texturePos[1] = ccv(0.f,1.f);
                    texturePos[2] = ccv(1.f,1.f);
                    texturePos[3] = ccv(1.f,0.f);
                    texturePos[4] = ccv(0.f,0.f);
                    texturePos[5] = ccv(0.f,1.f);
                    
                    glColor4ub( x[gID-1].r, x[gID-1].g, x[gID-1].b, x[gID-1].a );
                    
                    glEnable( GL_TEXTURE_2D );
                    
                    glDisableClientState( GL_COLOR_ARRAY );
                    
                    glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                    
                    glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                    
                    glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                }
            }
        }
    }
    
}

//上下左右是否有邻居水滴分配颜色
void fluidRender2()
{
//    glBindTexture(GL_TEXTURE_2D, [texture name]);
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            for(int gID = 1; gID <= groupID;gID++)
            {
                if(hashGridList[i][j].groupID == gID)
                {    


                    if(hashGridList[i][j].groupFlag == 15)//上下左右都有 红色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        glColor4ub( 255, 0, 0, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        //glBindTexture( GL_TEXTURE_2D, [texture name]);
                        
                        // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 14)//上下右有 右没有 蓝色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        glColor4ub( 0, 0, 255, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        //glBindTexture( GL_TEXTURE_2D, [texture name]);
                        
                        // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 13)//上下左有 左没有 绿色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        glColor4ub( 0, 255, 0, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        //glBindTexture( GL_TEXTURE_2D, [texture name]);
                        
                        // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 11)//下没有 桔黄色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        glColor4ub( 255, 111, 20, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 10)//下右没有 淡灰色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 110, 110, 155, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        //glBindTexture( GL_TEXTURE_2D, [texture name]);
                        
                        // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }                   
                    else if(hashGridList[i][j].groupFlag == 9)//左下没有 草绿色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 71, 234, 120, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 7)//上没有 黄色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 255, 255, 0, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    
                    else if(hashGridList[i][j].groupFlag == 6)//只有左下边有 浅紫色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 255, 0, 255, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    if(hashGridList[i][j].groupFlag == 5)//左上没有 深紫色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 160, 260, 255, 255 );
                        
                        glEnable( GL_TEXTURE_2D );

                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    if(hashGridList[i][j].groupFlag == 3)//只有左右 上下没有 淡肉色
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 189, 145, 135, 255 );
                        
                        glEnable( GL_TEXTURE_2D );

                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 2)//只有左有 暗淡蓝
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 30, 30, 115, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                    else if(hashGridList[i][j].groupFlag == 1)//只有右有 浅绿蓝
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                        
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 30, 210, 205, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                        
                    }
                }
            }
        }
    }
    
}

void fluidRender()
{
//    glBindTexture(GL_TEXTURE_2D, [texture name]);
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            for(int gID = 1; gID <= groupID;gID++)
            {
                if(hashGridList[i][j].groupID == gID)
                {
                    if(hashGridList[i][j].groupFlag == 15)
                    {
                        ccVertex2F segmentPos[ 6 ];
                        ccVertex2F texturePos[ 6 ];
                    
                        segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                        segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                        segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                        segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                        segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                        segmentPos[5] = segmentPos[ 1 ];
                        
                        texturePos[0] = ccv(.5f,.5f);
                        texturePos[1] = ccv(0.f,1.f);
                        texturePos[2] = ccv(1.f,1.f);
                        texturePos[3] = ccv(1.f,0.f);
                        texturePos[4] = ccv(0.f,0.f);
                        texturePos[5] = ccv(0.f,1.f);
                        
                        
                        glColor4ub( 255, 255, 255, 255 );
                        
                        glEnable( GL_TEXTURE_2D );
                        //glBindTexture( GL_TEXTURE_2D, [texture name]);
                        
                        // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                        glDisableClientState( GL_COLOR_ARRAY );
                        
                        glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                        
                        glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                        
                        glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                    }
                }
            }
        }
    }

}

void biheSection()
{
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            for(int i = 1;i <= groupID ; i++)
            {
                //对每个组的边缘进行连线
                std::vector<ccVertex2F> leftBoundsPointVec;
                std::vector<ccVertex2F> upBoundsPointVec;
                std::vector<ccVertex2F> rightBoundsPointVec;
                std::vector<ccVertex2F> downBoundsPointVec;
                std::vector<ccVertex2F> BoundsPointVec;
                if(hashGridList[i][j].groupID == i && hashGridList[i][j].groupFlag != 15)
                {
                    if((hashGridList[i][j].groupFlag&2)==0)//左边边缘提取
                    {
                        int praIndex = 0;
                        hashGridList[i][j].ResetIterator();
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)2];
                                jiaoPoint(praIndex,BoundsPointVec,2);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&1)==0)//右边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)1];
                                jiaoPoint(praIndex,BoundsPointVec,1);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&8)==0)//上边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)4];
                                jiaoPoint(praIndex,BoundsPointVec,4);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&4)==0)//下边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)3];
                                jiaoPoint(praIndex,BoundsPointVec,3);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    
                }
            }
        }
    }
    
}

void biheSection2()
{
    for(int k = 1;k <= groupID ; k++)
    {
        for(int i = 0; i < hashWidth; i++)
        {
            for(int j = 0; j < hashHeight; j++)
            {

                //对每个组的边缘进行连线
                std::vector<ccVertex2F> leftBoundsPointVec;
                std::vector<ccVertex2F> upBoundsPointVec;
                std::vector<ccVertex2F> rightBoundsPointVec;
                std::vector<ccVertex2F> downBoundsPointVec;
                std::vector<ccVertex2F> BoundsPointVec;
                if(hashGridList[i][j].groupID == k && hashGridList[i][j].groupFlag != 15)
                {
                    if((hashGridList[i][j].groupFlag&2)==0)//左边边缘提取
                    {
                        int praIndex = 0;
                        hashGridList[i][j].ResetIterator();
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)2];
                                jiaoPoint(praIndex,BoundsPointVec,2);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&1)==0)//右边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)1];
                                jiaoPoint(praIndex,BoundsPointVec,1);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&8)==0)//上边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)4];
                                jiaoPoint(praIndex,BoundsPointVec,4);
                            }
                            
                        } while (praIndex == -1);
                        
                    }
                    if((hashGridList[i][j].groupFlag&4)==0)//下边边缘提取
                    {
                        int praIndex = 0;
                        do
                        {
                            praIndex = hashGridList[i][j].GetNext();
                            if(praIndex == -1) break;
                            else//求出左侧交点 将求出的交点加入到最后需要排序的数组中去
                            {
                                //[self jiaoPoint:praIndex vector:BoundsPointVec boundsFlag:(int)3];
                                jiaoPoint(praIndex,BoundsPointVec,3);
                            }
                        } while (praIndex == -1);
                    }
                }
                //连线
                //NSLog(@"aaaa groupID : %d %ld",k,BoundsPointVec.size());
                
            }
        }
    }
    
}

void biheSection3()
{
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            if(hashGridList[i][j].groupID == -1)
            {
                if(hashGridList[i][j].neiGroupFlag != 0)
                {
                    ccVertex2F segmentPos[ 6 ];
                    ccVertex2F texturePos[ 6 ];
                    
                    segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                    segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                    segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                    segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                    segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                    segmentPos[5] = segmentPos[ 1 ];
                    
                    texturePos[0] = ccv(.5f,.5f);
                    texturePos[1] = ccv(0.f,1.f);
                    texturePos[2] = ccv(1.f,1.f);
                    texturePos[3] = ccv(1.f,0.f);
                    texturePos[4] = ccv(0.f,0.f);
                    texturePos[5] = ccv(0.f,1.f);
                    
                    
                    glColor4ub( 255, 255, 255, 255 );
                    
                    glEnable( GL_TEXTURE_2D );
                    //glBindTexture( GL_TEXTURE_2D, [texture name]);
                    
                    // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                    glDisableClientState( GL_COLOR_ARRAY );
                    
                    glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
                    
                    glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
                    
                    glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
                    
                }
                 
            }
            if(hashGridList[i][j].groupID != -1)
            {
                ccVertex2F segmentPos[ 6 ];
                ccVertex2F texturePos[ 6 ];
            
                segmentPos[0] = ccv(i*40.f+20.f,j*40.f+20.f);
                segmentPos[1] = ccv(i*40.f,(j+1)*40.f);
                segmentPos[2] = ccv((i+1)*40.f,(j+1)*40.f);
                segmentPos[3] = ccv((i+1)*40.f,(j)*40.f);
                segmentPos[4] = ccv((i)*40.f,(j)*40.f);
                segmentPos[5] = segmentPos[ 1 ];
            
                texturePos[0] = ccv(.5f,.5f);
                texturePos[1] = ccv(0.f,1.f);
                texturePos[2] = ccv(1.f,1.f);
                texturePos[3] = ccv(1.f,0.f);
                texturePos[4] = ccv(0.f,0.f);
                texturePos[5] = ccv(0.f,1.f);
            
                glColor4ub( 110, 0, 220, 255 );
            
                glEnable( GL_TEXTURE_2D );
                //glBindTexture( GL_TEXTURE_2D, [texture name]);
            
                // glDisableClientState( GL_TEXTURE_COORD_ARRAY );
                glDisableClientState( GL_COLOR_ARRAY );
            
                glTexCoordPointer( 2, GL_FLOAT, 0, texturePos );
            
                glVertexPointer( 2, GL_FLOAT, 0, segmentPos );
            
                glDrawArrays( GL_TRIANGLE_FAN, 0, 6);
            
            }
    
        }
    }

}


void biheSection4()
{
    //左上 右下 右上 左下 上 下 左 右 1 1 1 1 1 1 1 1
    //对每个边缘grid cell只取两个交点值
    for(int i = 0; i < hashWidth; i++)
    {
        for(int j = 0; j < hashHeight; j++)
        {
            vector<ccVertex2F>BoundsPointVec;
            if(hashGridList[i][j].groupID != -1 && hashGridList[i][j].neiGroupFlag != 255)
            {
                if((hashGridList[i][j].groupFlag&1) == 0)//左边网格加权
                {
                    
                }
                
            }
    
        }
    }
    
}

void jiaoPoint(int i, vector<ccVertex2F>& BoundsPointVec, int boundsFlag) //上下左右 4,3,2,1
{
    float circleR = 60.f;

    //x2+y2=r2
    float pX = liquid[i].mPosition.x*32.f;
    float pY = liquid[i].mPosition.y*32.f;
    
    int yuX = (int)pX%40;
    int yuY = (int)pY%40;

    if(boundsFlag == 4)//上
    {
        if((int)(pY+circleR/2)%40 == 0)//一个交点
        {
            BoundsPointVec.push_back(ccv(pX,pY+circleR/2));
        }
        else if(yuY+circleR/2 > 40)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuY)*(40-yuY));
            BoundsPointVec.push_back(ccv(pX + dis,pY+40-yuY));
            BoundsPointVec.push_back(ccv(pX - dis,pY+40-yuY));
            //NSLog(@"aaaa groupID : %d %ld",i,BoundsPointVec.size());
        }
    }
    else if(boundsFlag == 3)//下
    {
        if((int)(pY-circleR/2)%40 == 0)//一个交点
        {
            BoundsPointVec.push_back(ccv(pX,pY-circleR/2));
        }
        else if(yuY < circleR/2)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(yuY)*(yuY));
            BoundsPointVec.push_back(ccv(pX + dis,pY-yuY));
            BoundsPointVec.push_back(ccv(pX - dis,pY-yuY));
        }
        
    }
    else if(boundsFlag == 2)//左
    {
        if((int)(pX-circleR/2)%40 == 0)//一个交点
        {
            BoundsPointVec.push_back(ccv(pX-circleR/2,pY));
        }
        else if(yuX < circleR/2)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(yuX)*(yuX));
            BoundsPointVec.push_back(ccv(pX-yuX,pY + dis));
            BoundsPointVec.push_back(ccv(pX-yuX,pY - dis));
        }
        
    }
    else if(boundsFlag == 1)//右
    {
        if((int)(pX+circleR/2)%40 == 0)//一个交点
        {
            BoundsPointVec.push_back(ccv(pX+circleR/2,pY));
        }
        else if(yuX+circleR/2 > 40)//两个交点；
        {
            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuX)*(40-yuX));
            BoundsPointVec.push_back(ccv(pX+40-yuX,pY + dis));
            BoundsPointVec.push_back(ccv(pX+40-yuX,pY - dis));
        }
    }
    
}

