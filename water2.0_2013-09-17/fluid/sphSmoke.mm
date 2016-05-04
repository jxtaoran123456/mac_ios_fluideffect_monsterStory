//
//  SPHNode.m
//  SPH
//
//  Created by Vasiliy Yanushevich on 11/2/12.
//  Copyright 2012 Vasiliy Yanushevich. All rights reserved.
//

#import "sphSmoke.h"
#import "sphFluid.h"
#import "DLRenderTexture.h"
#import "SPHNode.h"

#include <GLUT/GLUT.h>
#include <OpenGL/glu.h>

int smnParticles = 0;
int smnAwakeParticles;
int smhaveAwakeParticlesNum;
int smfluidPraNum;
int smbuddleNum = 0;
int smlastFallPraticleIndex = -1;//最后一个下落水滴的是索引 为产生平滑水流参数
bool smisWaitForSmoothFlow;
float smrad;
float smvisc;
float smidealRad;
float smtotalMass;
cFluidHashList smhashGridList[hashWidth][hashHeight];
b2Shape *smNeighboursBuffer[smnominalNeighbourListLength];
int smgroupID;//簇ID

//render sprite
CCSpriteBatchNode *smokesmokeParticleBatch;
//SPHNode *gameLayer;

//fluid praticle object array
smParticle *smliquid;
float *smvlenBuffer;

////box2d physical
//b2World *m_world;
//GLESDebugDraw *m_debugDraw;
smQueryWorldInteractions *smintersectQueryCallback;
smQueryWorldPostIntersect *smeulerIntersectQueryCallback;
//
//int smvertsNum;//地形线数量
//b2Vec2 *smverts;
//
//int smvertsNum1;//地形线数量
//b2Vec2 *smverts1;
//
//int smvertsNum2;//地形线数量
//b2Vec2 *smverts2;
//
//int smsingleVerNum;//两条地形线数量
//singleVec *smsingleVers;

bool smParticleSolidCollision(b2Fixture* fixture, b2Vec2& particlePos, b2Vec2& nearestPos, b2Vec2& impactNormal,int particleIdx);
void smSeparateParticleFromBody(int particleIdx, b2Vec2& nearestPos, b2Vec2& normal, smParticle *liquid);

bool smQueryWorldInteractions::ReportFixture(b2Fixture* fixture) {
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
    
    int numParticles = smhashGridList[x][y].GetSize();
    smhashGridList[x][y].ResetIterator();
    
    // Iterate through all the particles in this cell
    for(int i = 0; i < numParticles; i++)
    {
//      if(smliquid[i].isAwake == false) continue;
        
        int particleIdx = smhashGridList[x][y].GetNext();
        
        b2Vec2 particlePos = smliquid[particleIdx].mPosition;
        if(fixture->GetBody()->GetType() == b2_staticBody || fixture->GetBody()->GetType() == b2_kinematicBody)
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
                smSeparateParticleFromBody(particleIdx, nearestPos, normal, smliquid);
            }
        }
        else//不明白非静态物体为什么要用以下算法 我认为和静态算法一样的物理计算才是符合规律的 非静态物体 相互之间产生冲力
        {
            b2Vec2 nearestPos(0,0);
            b2Vec2 normal(0,0);
            bool inside = ParticleSolidCollision(fixture, particlePos, nearestPos, normal,particleIdx);
            
            if (inside)
            {
                b2Vec2 particleVelocity = smliquid[particleIdx].mVelocity;
                
                // electrodruid: I think this does need to be here
                particleVelocity *= deltaT;
                // electrodruid: not sure if this should be here
                //									particleVelocity *= smliquid[particleIdx].mMass;
                
                // electrodruid: Still not sure exactly what the paper meant by
                // "intersection position", but taking the current particle position
                // seems to give the least-bad results
                b2Vec2 impulsePos = particlePos;
                //									b2Vec2 impulsePos = nearestPos;
                
                b2Vec2 pointVelocity = fixture->GetBody()->GetLinearVelocityFromWorldPoint(impulsePos);
                b2Vec2 pointVelocityAbsolute = pointVelocity;
                // electrodruid: I think this does need to be here
                pointVelocity *= deltaT;
                
                b2Vec2 relativeVelocity = particleVelocity - pointVelocity;
                
                b2Vec2 pointVelNormal = normal;
                pointVelNormal *= b2Dot(relativeVelocity, normal);
                b2Vec2 pointVelTangent = relativeVelocity - pointVelNormal;
                
                // Should be a value between 0.0f and 1.0f
                const float slipFriction = 0.3f;
                
                pointVelTangent *= slipFriction;
                b2Vec2 impulse = pointVelNormal - pointVelTangent;
                
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
                b2Vec2 buoyancy = b2Vec2(0, 10.f);
                const float buoyancyAdjuster = 0.f;
                buoyancy *= buoyancyAdjuster;
                
                fixture->GetBody()->ApplyForce(buoyancy, fixture->GetBody()->GetPosition());
                
                // move the particles away from the body
#ifdef VERLET_INTEGRATION
                smSeparateParticleFromBody(particleIdx, nearestPos, normal, smliquid);
#else
                smliquid[particleIdx].mVelocity -= impulse;
                smliquid[particleIdx].mVelocity += pointVelocityAbsolute;
#endif
            }
        }
    }
    return true;
    
}

bool smQueryWorldPostIntersect::ReportFixture(b2Fixture *fixture)
{
    int numParticles = smhashGridList[x][y].GetSize();
    smhashGridList[x][y].ResetIterator();

    for(int i = 0; i < numParticles; i++)
    {
//        if(smliquid[i].isAwake == false) continue;
        int particleIdx = smhashGridList[x][y].GetNext();
        
        b2Vec2 particlePos = smliquid[particleIdx].mPosition;
        if(fixture->GetBody()->GetType() == b2_dynamicBody)
        {
            b2Vec2 nearestPos(0,0);
            b2Vec2 normal(0,0);
            bool inside = ParticleSolidCollision(fixture, particlePos, nearestPos, normal,particleIdx);
            
            if (inside)
            {
                smSeparateParticleFromBody(particleIdx, nearestPos, normal, smliquid);
            }
        }
    }
    return true;
    
}

inline float smb2Random(float lo, float hi)
{
    return ((hi - lo) * CCRANDOM_0_1() + lo);;
}

const float fluidMinX = -10.0f;
const float fluidMaxX = 45;//grid的总高度 对应多少行 这里切忌搞反！40.0f
const float fluidMinY = -5.0f;
const float fluidMaxY = 30.5;//grid的总宽度 对应多少列 20.0f


inline float smmyMap(float val, float minInput, float maxInput, float minOutput, float maxOutput)
{
    float result = (val - minInput) / (maxInput - minInput);
    result *= (maxOutput - minOutput);
    result += minOutput;
    return result;
    
}

inline int smhashX(float x)
{
    float f = smmyMap(x, fluidMinX, fluidMaxX, 0, hashWidth-.001f);
    return (int)f;
}

inline int smhashY(float y)
{
    float f = smmyMap(y, fluidMinY, fluidMaxY, 0, hashHeight-.001f);
    return (int)f;
}

void sminitFluidPraticles(float prad,float pvisc,float pidealRad, float ptotalMass,float ppraticlesN,NSString *spSprName,NSString *sp2SprName)
{
    //common para
//    rad = .6f;
//    visc = .002f;//.0002f
//    idealRad = 60.0f;
//    totalMass = 0.f;
    smrad = prad;
    smvisc = pvisc;//.0002f
    smidealRad = pidealRad;
    smtotalMass = ptotalMass;
    smnParticles = ppraticlesN;
    
    smliquid = (smParticle*)malloc(sizeof(smParticle)*smnParticles);
    smvlenBuffer = (float *)malloc(sizeof(float)*smnParticles);
    for (int i = 0; i < smnParticles; ++i)
	{
        smliquid[i].mPosition = b2Vec2(50, 50);
        smliquid[i].mPrePosition = smliquid[i].mPosition;
		smliquid[i].mOldPosition = smliquid[i].mPosition;
		smliquid[i].mVelocity = b2Vec2(0.0f, -0.0f);
		smliquid[i].mAcceleration = b2Vec2(0, -10.0f);
        smliquid[i].buddleSp = nil;
        
		smliquid[i].mMass = totalMass/smnParticles;
		smliquid[i].mRestitution = 0.4f;
		smliquid[i].mFriction = 0.0f;
        smliquid[i].isAwake = false;
        smliquid[i].ifFanDeHuaForce = true;
        smliquid[i].isBuddlePraticle = false;
        smliquid[i].mForce = b2Vec2(0,-0);
        
        smliquid[i].inittick = 0;
        smliquid[i].buddleTick = 0;
        smliquid[i].xuanwoTick = 60 + rand()%240;
        if(smokeParticleBatch != nil && spSprName != nil)
        {
            smliquid[i].sp = [CCSprite spriteWithFile:spSprName];
            smliquid[i].sp.scale = 1.0;
            [smokeParticleBatch addChild:smliquid[i].sp];
        }
        else
        {
            smliquid[i].sp = nil;
        }
	}
    
}

void smawakePraticles(int awakeNum)
{
    int countNum = awakeNum;
    int numAve =0;
    for (int i = 0; i < smnParticles; ++i)
	{
        if(smliquid[i].isAwake == false)
        {
            smliquid[i].mPosition = b2Vec2(50,50);//b2Vec2(b2Random(14,20),b2Random(20, 40));
            smliquid[i].mOldPosition = smliquid[i].mPosition;
            smliquid[i].mVelocity = b2Vec2(.0f, -20.0f);
            smliquid[i].mForce = b2Vec2(0,0);
            countNum--;
        }
        if(countNum == 0)break;
    }
    
}

void smawakePraticles(int awakeNum,b2Vec2 position,float width,float height,b2Vec2 initVelocity,float angle,int allowTolCount = 0,bool ifContinueSmoothFlow = false)
{
    //angle为倾斜角度 width为宽度 height为每一列或每一行间隔长度 为负数时为横向 注意横纵 会改变宽度和长度的算法
    position.x = position.x-100;
    int countNum = awakeNum;
    //这两个参数为了产生的水流能形成一个类似瀑布或者均匀流体的效果
    int rowNum = 2;//产生水流时 每一行的水滴粒子个数
    float fluidColumnHei = -10;//产生水流时 每行高度 为负数时表示横向向左累积 正数表述纵向向上累积 height

    if(ifContinueSmoothFlow == true)
    {
        for (int i = 0; i < smnParticles; ++i)
        {
            if(smliquid[i].isAwake == false)
            {
                smliquid[i].mPosition = b2Vec2(-10, -10);
                smliquid[i].mPrePosition = smliquid[i].mPosition;
                smliquid[i].mOldPosition = smliquid[i].mPosition;
                smliquid[i].mVelocity = b2Vec2(0.0f, -0.0f);
            }
        }
    }
    for (int i = 0; i < smnParticles; ++i)
	{
        if(smliquid[i].isAwake == false)
        {
            smliquid[i].allowTolCount = allowTolCount;
            if(height > 0)
            {
                smliquid[i].mPosition = b2Vec2((((awakeNum-countNum)%rowNum)*width/rowNum+position.x)/PTM_RATIO,(((awakeNum-countNum)/rowNum)*fluidColumnHei+position.y)/PTM_RATIO);
            }
            else if(height <= 0)
            {
                smliquid[i].mPosition = b2Vec2((((awakeNum-countNum)%rowNum)*width/rowNum+position.x)/PTM_RATIO,(((awakeNum-countNum)/rowNum)*fluidColumnHei*-1.f+position.y)/PTM_RATIO);
            }
            smliquid[i].mPrePosition = smliquid[i].mPosition;
            smliquid[i].mOldPosition = smliquid[i].mPosition;
            smliquid[i].mVelocity = initVelocity;
            smliquid[i].mForce = b2Vec2(0,0);
            countNum--;
        }
        if(countNum == 0 || (haveAwakeParticlesNum+awakeNum-countNum)>=fluidPraNum )
        {
            break;
        }
    }

}

void smresetAllFluid()
{
    for (int i = 0; i < smnParticles; ++i)
	{
        smliquid[i].isAwake = true;
        smliquid[i].mPosition =  b2Vec2(50,50);//b2Vec2(b2Random(-20, -10),b2Random(-20, -10));
        smliquid[i].mVelocity = b2Vec2(0.0f, 0.0f);
        smliquid[i].inittick = 0;
    }
    
}

void smclearMemory()
{
    smnParticles = 0;
    if(smliquid != NULL)
    {
        free(smliquid);
        smliquid = NULL;
    }
    if(smvlenBuffer != NULL)
    {
        free(smvlenBuffer);
        smvlenBuffer = NULL;
    }
    
}

void smupdateFluidStep(float dt)
{
    smhashLocations();
//    smapplyLiquidConstraint(dt);
//    smprocessWorldInteractions(dt);
    smdampenLiquid();
//    smresolveIntersections(dt);
    
//    smgroupID = 0;//不能放在聚类函数体内 内部存在迭代
//    smcateGory(0,0);
    
    smstepFluidParticles(dt);
   
}

void smclearHashGrid()
{
	for(int a = 0; a < hashWidth; a++)
	{
		for(int b = 0; b < hashHeight; b++)
		{
			smhashGridList[a][b].Clear();
		}
	}
    
}

void smhashLocations()
{
    smclearHashGrid();
    smnAwakeParticles = 0;//每一帧开始运算前重新将active水滴数清零 然后重新统计
	for(int a = 0; a < smnParticles; a++)
	{
		int hcell = smhashX(smliquid[a].mPosition.x);
		int vcell = smhashY(smliquid[a].mPosition.y);
        
		if(hcell > -1 && hcell < hashWidth && vcell > -1 && vcell < hashHeight)
		{
            if(smliquid[a].isAwake == false)
            {
                smliquid[a].isAwake = true;
                smhaveAwakeParticlesNum++;
                
            }
			smhashGridList[hcell][vcell].PushBack(a);
            smnAwakeParticles++;
            
		}
        else
        {
            //added by tr 2013-10-03
            if(smliquid[a].inittick != 0)//防止弹出又被弹回来的水滴加入计算
            {
                smliquid[a].mPosition = b2Vec2(50,50);
                smliquid[a].mPrePosition = smliquid[a].mPosition;
                smliquid[a].mOldPosition = smliquid[a].mPosition;
            }
            //ended by tr 2013-10-03
            smliquid[a].isAwake = false;
            smliquid[a].buddleTick = 0;
            smliquid[a].inittick = 0;
            smliquid[a].sp.scale = 1.0;
            smliquid[a].sp.opacity = 255;
            
            //还原变色后的水滴颜色状态
            if(smliquid[a].type != 0)
            {
                [gameLayer reductionColorState:a];
            }
        }
	}
    
}

// Fix up the tail pointers for the hashGrid cells after we've monkeyed with them to
// make the neighbours list for a particle
void smresetGridTailPointers(int particleIdx)
{
	int hcell = smhashX(smliquid[particleIdx].mPosition.x);
	int vcell = smhashY(smliquid[particleIdx].mPosition.y);
    
	for(int nx = -1; nx < 2; nx++)
	{
		for(int ny = -1; ny < 2; ny++)
		{
			int xc = hcell + nx;
			int yc = vcell + ny;
            
			if(xc > -1 && xc < hashWidth && yc > -1 && yc < hashHeight)
			{
				if(!smhashGridList[xc][yc].IsEmpty())
				{
					smhashGridList[xc][yc].UnSplice();
				}
			}
		}
	}
    
}

void smapplyLiquidConstraint(float deltaT)
{
    // * Unfortunately, this simulation method is not actually scale
    // * invariant, and it breaks down for rad < ~3 or so.  So we need
    // * to scale everything to an ideal rad and then scale it back after.
    
	float multiplier = smidealRad / smrad;
    
    //changed by tr 2013-08-23
	float xchange[smnParticles];//={0.0};
	float ychange[smnParticles];//={0.0};
    for(int m = 0; m < smnParticles;m++)
    {
        xchange[m] = 0.f;
        ychange[m] = 0.f;
    }
    
	float xs[smnParticles];
	float ys[smnParticles];
	float vxs[smnParticles];
	float vys[smnParticles];
    
	for (int i=0; i<smnParticles; ++i)
	{
		xs[i] = multiplier*smliquid[i].mPosition.x;
		ys[i] = multiplier*smliquid[i].mPosition.y;
		vxs[i] = multiplier*smliquid[i].mVelocity.x;
		vys[i] = multiplier*smliquid[i].mVelocity.y;
	}
    
	cFluidHashList neighbours;
    
	float* vlen = vlenBuffer;
    
	for(int i = 0; i < smnParticles; i++)
	{
		// Populate the neighbor list from the 9 proximate cells
		int hcell = smhashX(smliquid[i].mPosition.x);
		int vcell = smhashY(smliquid[i].mPosition.y);
        
		bool bFoundFirstCell = false;
		for(int nx = -1; nx < 2; nx++)
		{
			for(int ny = -1; ny < 2; ny++)
			{
				int xc = hcell + nx;
				int yc = vcell + ny;
				if(xc > -1 && xc < hashWidth && yc > -1 && yc < hashHeight)
				{
					if(!smhashGridList[xc][yc].IsEmpty())
					{
						if(!bFoundFirstCell)
						{
							// Set the head and tail of the beginning of our neighbours list
							neighbours.SetHead(smhashGridList[xc][yc].pHead());
							neighbours.SetTail(smhashGridList[xc][yc].pTail());
							bFoundFirstCell = true;
						}
						else
						{
							// We already have a neighbours list, so just add this cell's particles onto
							// the end of it.
							neighbours.Splice(smhashGridList[xc][yc].pHead(), smhashGridList[xc][yc].pTail());
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
            
			float vx = xs[j]-xs[i];//smParticlej]->GetWorldCenter().x - smliquid[i]->GetWorldCenter().x;
			float vy = ys[j]-ys[i];//smParticlej]->GetWorldCenter().y - smliquid[i]->GetWorldCenter().y;
            
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
                        vlen[a] = b2_linearSlop;
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
		float pressure = (p - 5.0f) / 2.0f; //normal pressure term 2
		float presnear = pnear / 2.0f; //near particles term 2
		float changex = 0.0f;
		float changey = 0.0f;
        
		neighbours.ResetIterator();
        
		for(int a = 0; a < neighboursListSize; a++)
		{
			int n = neighbours.GetNext();
            
			int j = n;
            
			float vx = xs[j]-xs[i];//smParticlej]->GetWorldCenter().x - smliquid[i]->GetWorldCenter().x;
			float vy = ys[j]-ys[i];//smParticlej]->GetWorldCenter().y - smliquid[i]->GetWorldCenter().y;
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
		// We've finished with this neighbours list, so go back and re-null-terminate all of the
		// grid cells lists ready for the next particle's neighbours list.
        resetGridTailPointers(i);
	}
	
	for (int i=0; i<smnParticles; ++i)
	{
        if(fabs(xchange[i]) < 1e-8 && fabs(ychange[i]) < 1e-8)//不受范德华力的粒子进行变形渲染
        {
            smliquid[i].ifFanDeHuaForce = false;
            
        }
        smliquid[i].mPrePosition = smliquid[i].mPosition;
        smliquid[i].mPosition += b2Vec2(xchange[i] / multiplier, ychange[i] / multiplier);
		smliquid[i].mVelocity += b2Vec2(xchange[i] / (multiplier*deltaT), ychange[i] / (multiplier*deltaT));
	}
    
}

void smcheckBounds()
{
	float massPerParticle = totalMass / smnParticles;
    
	for (int i=0; i<smnParticles; ++i)
	{
		if (smliquid[i].mPosition.y < -1.0f)
		{
            float cx = -5.0f;
            float cy = 15.0f;
            
            smliquid[i].mPosition = b2Vec2(50,50);//b2Vec2( b2Random(4.f, 13.f),b2Random(11.f, 15.f));
			smliquid[i].mOldPosition = smliquid[i].mPosition;
            smliquid[i].mPrePosition = smliquid[i].mPosition;
			smliquid[i].mVelocity = b2Vec2(0.0f, 0.0f);
			smliquid[i].mAcceleration = b2Vec2(0, -10.0f);
            
			smliquid[i].mMass = massPerParticle;
			smliquid[i].mRestitution = 0.4f;
			smliquid[i].mFriction = 0.0f;
		}
	}
    
}

void smdampenLiquid()
{
	for (int i=0; i<smnParticles; ++i)
	{
		smliquid[i].mVelocity.x *= 0.995f;
		smliquid[i].mVelocity.y *= 0.995f;
        if(smliquid[i].isAwake == true)smliquid[i].inittick++;
	}
}

// Handle interactions with the world
void smprocessWorldInteractions(float deltaT)
{
	// Iterate through the grid, and do an AABB test for every grid containing particles
	for (int x = 0; x < hashWidth; ++x)
	{
		for (int y = 0; y < hashHeight; ++y)//hashWidth?????
		{
			if(!smhashGridList[x][y].IsEmpty())
			{
				float minX = smmyMap((float)x, 0, hashWidth, fluidMinX, fluidMaxX);
				float maxX = smmyMap((float)x+1, 0, hashWidth, fluidMinX, fluidMaxX);
				float minY = smmyMap((float)y, 0, hashHeight, fluidMinY, fluidMaxY);
				float maxY = smmyMap((float)y+1, 0, hashHeight, fluidMinY, fluidMaxY);
                
				b2AABB aabb;
                
				aabb.lowerBound.Set(minX, minY);
				aabb.upperBound.Set(maxX, maxY);
                
                smintersectQueryCallback->x = x;
                smintersectQueryCallback->y = y;
                smintersectQueryCallback->deltaT = deltaT;
                m_world->QueryAABB(smintersectQueryCallback, aabb);
			}
		}
	}
    
}

// Detect an intersection between a particle and a b2Shape, and also try to suggest the nearest
// point on the shape to move the particle to, and the shape normal at that point

bool smParticleSolidCollision(b2Fixture* fixture, b2Vec2& particlePos, b2Vec2& nearestPos, b2Vec2& impactNormal,int particleIdx)
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
		return false;
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
void smSeparateParticleFromBody(int particleIdx, b2Vec2& nearestPos, b2Vec2& normal, smParticle *liquid)
{
        smliquid[particleIdx].mPosition = nearestPos;
	// input velocities
	b2Vec2 V = smliquid[particleIdx].mVelocity;
	float vn = b2Dot(V, normal);	 // impact speed 点乘求向量延反弹方向的转化值 normal为反弹方向的归一化
	//					V -= (2.0f * vn) * normal;
    
	b2Vec2 Vn = vn * normal; // impact velocity vector
	b2Vec2 Vt = V - Vn; // tangencial veloctiy vector (across the surface of collision).
    
	// now the output velocities ('r' for response).
	float restitution = smliquid[particleIdx].mRestitution;
	b2Vec2 Vnr = -Vn;
	Vnr.x *= restitution;
	Vnr.y *= restitution;
    
	float invFriction = 1.0f - smliquid[particleIdx].mFriction;
	b2Vec2 Vtr = Vt;
	Vtr.x *= invFriction;
	Vtr.y *= invFriction;
    
	// resulting velocity
	V = Vnr + Vtr;
    
	smliquid[particleIdx].mVelocity = V;
    
}

void smoutBoundsHandle(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
            
        }
        else if(fabs(verts[gay].y - verts[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts[gay].y-newP.y)+verts[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
            
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[gay+1]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
            
        }
        else if(fabs(verts[gay].y - verts[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts[gay].y-newP.y)+verts[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts[gay],verts[0]);
        }
        
    }
    
    if(smtolCT(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        smliquid[praticleIndex].mPosition = smliquid[praticleIndex].mPrePosition;
        smliquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        smliquid[praticleIndex].mOldPosition = smliquid[praticleIndex].mPosition;
        smliquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void smoutBoundsHandle1(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts1[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
            
        }
        else if(fabs(verts1[gay].y - verts1[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts1[gay].y-newP.y)+verts1[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts1[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
            
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[gay+1]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts1[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
            
        }
        else if(fabs(verts1[gay].y - verts1[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts1[gay].y-newP.y)+verts1[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts1[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts1[gay],verts1[0]);
        }
        
    }
    
    if(smtolCT1(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是咬做特殊处理
        smliquid[praticleIndex].mPosition = smliquid[praticleIndex].mPrePosition;
        smliquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        smliquid[praticleIndex].mOldPosition = smliquid[praticleIndex].mPosition;
        smliquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void smoutBoundsHandle2(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
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
            if(fabs(newP.x - smliquid[praticleIndex].mPosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts2[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
            
        }
        else if(fabs(verts2[gay].y - verts2[gay+1].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts2[gay].y-newP.y)+verts2[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts2[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
            
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[gay+1]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float jiaoPX = verts2[gay].x;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPY = k1*jiaoPX+jiaoB;
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
            
        }
        else if(fabs(verts2[gay].y - verts2[0].y) < 1e-8)//平行
        {
            float newX = newP.x;
            float newY = (verts2[gay].y-newP.y)+verts2[gay].y;
            lastCheckP = b2Vec2(newX,newY);
            float newVX,newVY;
            
            float k1;
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k1 = 1000000;
            }
            else
            {
                k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            
            float jiaoPY = verts2[gay].y;
            float jiaoB = newP.y - k1*newP.x;
            float jiaoPX = (jiaoPY-jiaoB)/k1;
            
            newVX = (newX-jiaoPX)/deltaT;
            newVY = (newY-jiaoPY)/deltaT;

            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
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
            if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
            {
                k3 = 100000.f;
            }
            else
            {
                k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
            }
            float b3 = newP.y - k3*newP.x;
            float jiangluoPX = (b3-b1)/(k1-k3);
            float jiangluoPY = k3*jiangluoPX+b3;
            
            float newVX = (newX-jiangluoPX)/deltaT;
            float newVY = (newY-jiangluoPY)/deltaT;
            
            smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,verts2[gay],verts2[0]);
        }
        
    }
    
    if(smtolCT2(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        smliquid[praticleIndex].mPosition = smliquid[praticleIndex].mPrePosition;
        smliquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        smliquid[praticleIndex].mOldPosition = smliquid[praticleIndex].mPosition;
        smliquid[praticleIndex].mPosition = lastCheckP;
        
    }
    
}

void smoutBoundsHandleSingleVer(int gay,b2Vec2 newP,int praticleIndex,float deltaT)
{
    b2Vec2 lastCheckP;
    if(fabs(singleVers[gay].vec1.x - singleVers[gay].vec2.x) < 1e-8)//垂直
    {
        float newX = (singleVers[gay].vec1.x-newP.x)+singleVers[gay].vec2.x;
        float newY = newP.y;
        lastCheckP = b2Vec2(newX,newY);
        float newVX,newVY;
        float k1;
        if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k1 = 1000000;
        }
        else
        {
            k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
        }
        float jiaoPX = singleVers[gay].vec1.x;
        float jiaoB = newP.y - k1*newP.x;
        float jiaoPY = k1*jiaoPX+jiaoB;
        newVX = (newX-jiaoPX)/deltaT;
        newVY = (newY-jiaoPY)/deltaT;
        
        smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
        
    }
    else if(fabs(singleVers[gay].vec1.y - singleVers[gay].vec2.y) < 1e-8)//平行
    {
        float newX = newP.x;
        float newY = (singleVers[gay].vec1.y-newP.y)+singleVers[gay].vec1.y;
        lastCheckP = b2Vec2(newX,newY);
        float newVX,newVY;
        
        float k1;
        if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k1 = 1000000;
        }
        else
        {
            k1 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
        }
        
        float jiaoPY = singleVers[gay].vec1.y;
        float jiaoB = newP.y - k1*newP.x;
        float jiaoPX = (jiaoPY-jiaoB)/k1;
        
        newVX = (newX-jiaoPX)/deltaT;
        newVY = (newY-jiaoPY)/deltaT;
        
        smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
        
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
        if(fabs(newP.x - smliquid[praticleIndex].mPrePosition.x) < 1e-12)
        {
            k3 = 100000.f;
        }
        else
        {
            k3 = (newP.y - smliquid[praticleIndex].mPrePosition.y)/(newP.x - smliquid[praticleIndex].mPrePosition.x);
        }
        float b3 = newP.y - k3*newP.x;
        float jiangluoPX = (b3-b1)/(k1-k3);
        float jiangluoPY = k3*jiangluoPX+b3;
        
        float newVX = (newX-jiangluoPX)/(deltaT);
        float newVY = (newY-jiangluoPY)/(deltaT);
        
        smSeparatePraticleFromEdge(praticleIndex,b2Vec2(newVX,newVY),deltaT,singleVers[gay].vec1,singleVers[gay].vec2);
    
    }
    if(smtolCTSingleVer(praticleIndex,lastCheckP) != -1)
    {
        //这个最后还是要做特殊处理
        smliquid[praticleIndex].mPosition = smliquid[praticleIndex].mPrePosition;
        smliquid[praticleIndex].mVelocity = b2Vec2(0,0);
    }
    else
    {
        smliquid[praticleIndex].mOldPosition = smliquid[praticleIndex].mPosition;
        smliquid[praticleIndex].mPosition = lastCheckP;
        
    }

}

void smSeparatePraticleFromEdge(int praticleIndex,b2Vec2 newV,float deltaT,b2Vec2 vec1,b2Vec2 vec2)
{

   //this is the 1 Algorithm 摩擦力和反弹力无法分开
    float lenV = smliquid[praticleIndex].mVelocity.Length();
    newV.Normalize();
    newV = newV*lenV;//先求出虚拟无能量损失的反弹速度

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
    
    b2Vec2 levelVec = levelVS*level*(1-smliquid[praticleIndex].mFriction);//水平方向速度
    
    b2Vec2 Vertical = b2Vec2(-level.y,level.x);
    float VerticalVS = b2Dot(newV, Vertical);
    if(VerticalVS < 0)
    {
        Vertical = b2Vec2(level.y,-level.x);
        VerticalVS = -1.f*VerticalVS;
    }
    
    b2Vec2 VerticalVec = VerticalVS*Vertical*smliquid[praticleIndex].mRestitution;//水平方向速度
    smliquid[praticleIndex].mVelocity = levelVec+VerticalVec;//+m_world->GetGravity()*deltaT+smliquid[praticleIndex].mForce*deltaT;//VerticalVec; levelVec
    
}

void smstepFluidParticles(float deltaT)
{
	for (int i = 0; i < smnParticles; ++i)
	{
        BOOL tolEdge;//是否穿越边界 穿越的桢不产生变形
		// Old-Skool Euler stuff
        b2Vec2 g = b2Vec2(0,5);//m_world->GetGravity();
        smliquid[i].mVelocity.x += (g.x * deltaT );
		smliquid[i].mVelocity.y += (g.y * deltaT );
        
        smliquid[i].mVelocity.x += smliquid[i].mForce.x * deltaT;
		smliquid[i].mVelocity.y += smliquid[i].mForce.y * deltaT;
        
        b2Vec2 newP = smliquid[i].mPosition + smliquid[i].mVelocity*deltaT;
//        
//        int gay = smtolCT(i,newP);
//        int gay1 = smtolCT1(i,newP);
//        int gay2 = smtolCT2(i,newP);
//        int gay3 = smtolCTSingleVer(i,newP);
//        
//        if(gay != -1)
//        {
//            if(smliquid[i].allowTolCount > 0)
//            {
//                smliquid[i].allowTolCount--;
//                smliquid[i].mOldPosition = smliquid[i].mPosition;
//                smliquid[i].mPosition = newP;
//            }
//            else
//            {
//                smoutBoundsHandle(gay,newP,i,deltaT);
//                tolEdge = YES;
//            }
//        }
//        else if(gay1 != -1)
//        {
//            if(smliquid[i].allowTolCount > 0)
//            {
//                smliquid[i].allowTolCount--;
//                smliquid[i].mOldPosition = smliquid[i].mPosition;
//                smliquid[i].mPosition = newP;
//            }
//            else
//            {
//                smoutBoundsHandle1(gay1,newP,i,deltaT);
//                tolEdge = YES;
//            }
//        }
//        
//        else if(gay2 != -1 )
//        {
//            if(smliquid[i].allowTolCount > 0)
//            {
//                smliquid[i].allowTolCount--;
//                smliquid[i].mOldPosition = smliquid[i].mPosition;
//                smliquid[i].mPosition = newP;
//            }
//            else
//            {
//                smoutBoundsHandle2(gay2,newP,i,deltaT);
//                tolEdge = YES;
//            }
//        }
//        
//        else if(gay3 != -1)
//        {
//            if(smliquid[i].allowTolCount > 0)
//            {
//                smliquid[i].allowTolCount--;
//                smliquid[i].mOldPosition = smliquid[i].mPosition;
//                smliquid[i].mPosition = newP;
//            }
//            else
//            {
//                smoutBoundsHandleSingleVer(gay3,newP,i,deltaT);
//                tolEdge = YES;
//            }
//        }
//        else
        {
            smliquid[i].mOldPosition = smliquid[i].mPosition;
            smliquid[i].mPosition = newP;//smliquid[i].mVelocity;
        }
        
        if(smliquid[i].ifFanDeHuaForce == false && smliquid[i].isAwake == true)// || smliquid[i].inittick < 60))//变形
        {
            if(smliquid[i].sp != nil)smliquid[i].sp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
            smliquid[i].sp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
            
        }
        else
        {
            if(smliquid[i].sp != nil)smliquid[i].sp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
        }
        
        if(smliquid[i].isAwake == true)
        {
            smliquid[i].sp.scale = smliquid[i].inittick/250.f+1.0;
            smliquid[i].sp.opacity = 255 - smliquid[i].inittick*0.6f;
        }
        smliquid[i].ifFanDeHuaForce = true;
        smliquid[i].mForce = b2Vec2(0,0);
    }
    
}

//气泡
void smaddBuddle(int i,float vSqr,int hcell,int vcell)
{
    //气泡粒子检测和显示
    //处于水流中央 ID处于簇内 速度在限定范围内 当前气泡个数小于上线值 则产生新气泡 否则产生
    if( smhashGridList[hcell][vcell].groupFlag == 255 && smhashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity &&buddleNum <= nAwakeParticles/250 && smliquid[i].isBuddlePraticle == false && smliquid[i].inittick > 60)//
    {
        smliquid[i].buddleSp = [CCSprite spriteWithFile:@"blue_circle_small.png"];
        [ParticleBuddleBatch addChild:smliquid[i].buddleSp];
        smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
        smliquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
        smliquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
        smliquid[i].buddleSp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
        
        smliquid[i].isBuddlePraticle = true;
        smliquid[i].buddleTick++;
        buddleNum++;
    }
    //消除旧的不合格气泡
    else if((smliquid[i].isBuddlePraticle == true) && (smhashGridList[hcell][vcell].groupFlag != 255 || smhashGridList[hcell][vcell].groupID == -1 || vSqr < buddleVelocity))
    {
        if(smliquid[i].buddleSp != nil)
        {
            [smliquid[i].buddleSp removeFromParentAndCleanup:YES];
            smliquid[i].buddleSp = nil;
        }
        smliquid[i].buddleTick = 0;
        smliquid[i].isBuddlePraticle = false;
        buddleNum--;
    }
    //气泡运动和大小变化
    else if(smliquid[i].isBuddlePraticle == true && smhashGridList[hcell][vcell].groupFlag == 255 &&  smhashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity)
    {
        if(smliquid[i].buddleSp == nil)
        {
            smliquid[i].buddleSp = [CCSprite spriteWithFile:@"blue_circle_big,png"];
            [ParticleBuddleBatch addChild:smliquid[i].buddleSp];
            smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
            smliquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
            smliquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
            smliquid[i].buddleSp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
            
        }
        else
        {
            smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
            smliquid[i].buddleSp.scaleX = clampf(vSqr*.06f, .65f, 1.f);
            smliquid[i].buddleSp.scaleY = clampf(vSqr*.06f, .65f, 1.f);
            smliquid[i].buddleSp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
        }
        smliquid[i].buddleTick++;
    }
    
}

//气泡2 匀速上升运动气泡
void smaddBuddle2(int i,float vSqr,int hcell,int vcell)
{
    //气泡粒子检测和显示
    //处于水流中央 ID处于簇内 速度在限定范围内 当前气泡个数小于上限值 则产生新气泡 否则禁止
    if(hcell < 0 ||  vcell < 0 || fabs(vSqr) < 1e-12 || hcell > hashWidth  || vcell > hashHeight)return;
    
    int buddlehcell = 0;
    int buddlevcell = 0;
    if(smliquid[i].buddleSp != nil)
    {
        buddlehcell = smhashX(smliquid[i].buddleSp.position.x/PTM_RATIO);
        buddlevcell = smhashY(smliquid[i].buddleSp.position.y/PTM_RATIO);
    }
    
    if( smhashGridList[hcell][vcell].groupFlag == 255 && smhashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity && buddleNum <= nAwakeParticles/350 && smliquid[i].isBuddlePraticle == false && smliquid[i].inittick > 60)//
    {
        smliquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
        smliquid[i].buddleSp.opacity = 160;
        [ParticleBuddleBatch addChild:smliquid[i].buddleSp];
        //smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
        smliquid[i].buddleSp.scaleX = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
        smliquid[i].buddleSp.scaleY = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
        smliquid[i].buddleSp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
        
        smliquid[i].isBuddlePraticle = true;
        smliquid[i].buddleTick++;
        buddleNum++;
    }
    else if(nAwakeParticles > 200 && buddleNum <= nAwakeParticles/350 && smhashGridList[hcell][vcell].groupFlag == 255 && smhashGridList[hcell][vcell].groupID != -1 && smliquid[i].isBuddlePraticle == false && smliquid[i].inittick > 60)
    {
        smliquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
        smliquid[i].buddleSp.opacity = 160;
        [ParticleBuddleBatch addChild:smliquid[i].buddleSp];
        //smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
        smliquid[i].buddleSp.scale = (.5f+.1f*(float)(rand()%5))/8.f;
        smliquid[i].buddleSp.position = ccp(32.f * smliquid[i].mPosition.x, 32.f * smliquid[i].mPosition.y);
        
        smliquid[i].isBuddlePraticle = true;
        smliquid[i].buddleTick++;
        buddleNum++;
    }
    
    //消除旧的不合格气泡 假设气泡属于匀速上升运动
    //表面张力逐渐扩大 气泡大小逐渐扩大
    //消除的可能性为气泡上升过程中
    //1自动破裂或者上升到流体 2与空气接触面时马上破裂
    else if((smliquid[i].isBuddlePraticle == true) && smliquid[i].buddleSp != nil && (smhashGridList[buddlehcell][buddlevcell].groupFlag&255) == 0)//&8
    {
        if(smliquid[i].buddleSp != nil)
        {
            [smliquid[i].buddleSp removeFromParentAndCleanup:YES];
            smliquid[i].buddleSp = nil;
        }
        smliquid[i].buddleTick = 0;
        smliquid[i].isBuddlePraticle = false;
        buddleNum--;
    }
    //气泡运动 匀速上升运动 直至到达流体表面破裂
    //else if(smliquid[i].isBuddlePraticle == true && smhashGridList[hcell][vcell].groupFlag == 255 &&  smhashGridList[hcell][vcell].groupID != -1 && vSqr >= buddleVelocity)
    else if(smliquid[i].isBuddlePraticle == true)
    {
        if(smliquid[i].buddleSp == nil)
        {
            smliquid[i].buddleSp = [CCSprite spriteWithFile:@"buddle1.png"];
            smliquid[i].buddleSp.opacity = 160;
            [ParticleBuddleBatch addChild:smliquid[i].buddleSp];
            //smliquid[i].buddleSp.rotation = -1.f * CC_RADIANS_TO_DEGREES(ccpToAngle(ccp(smliquid[i].mVelocity.x, smliquid[i].mVelocity.y)));
            smliquid[i].buddleSp.scaleX = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
            smliquid[i].buddleSp.scaleY = (clampf(vSqr*.005f, .65f, 1.f))/8.f;
            
        }
        smliquid[i].buddleSp.position = ccp(smliquid[i].buddleSp.position.x,smliquid[i].buddleSp.position.y+rand()%2+1);
        smliquid[i].buddleTick++;
    }
    
}

void smresolveIntersections(float deltaT)
{
	// Iterate through the grid, and do an AABB test for every grid containing particles
	for (int x = 0; x < hashWidth; ++x)
	{
		for (int y = 0; y < hashHeight; ++y)//hashWidth?why
		{
			if(!smhashGridList[x][y].IsEmpty())
			{
				float minX = smmyMap((float)x, 0, hashWidth, fluidMinX, fluidMaxX);
				float maxX = smmyMap((float)x+1, 0, hashWidth, fluidMinX, fluidMaxX);
				float minY = smmyMap((float)y, 0, hashHeight, fluidMinY, fluidMaxY);
				float maxY = smmyMap((float)y+1, 0, hashHeight, fluidMinY, fluidMaxY);
                
				b2AABB aabb;
                
				aabb.lowerBound.Set(minX, minY);
				aabb.upperBound.Set(maxX, maxY);
                
                smeulerIntersectQueryCallback->x = x;
                smeulerIntersectQueryCallback->y = y;
                smeulerIntersectQueryCallback->deltaT = deltaT;
                m_world->QueryAABB(smeulerIntersectQueryCallback, aabb);
			}
		}
	}
    
}

int smtolCT(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum == 0) return -1;
    for(int j = 0; j < vertsNum;j++)
    {
        if(j != vertsNum-1)
        {
            if(smintersect_in(newP,smliquid[praticleIndex].mPrePosition,verts[j],verts[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(smintersect_in(newP,smliquid[praticleIndex].mPrePosition,verts[j],verts[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

int smtolCT1(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum1 == 0) return -1;
    for(int j = 0; j < vertsNum1;j++)
    {
        if(j != vertsNum1-1)
        {
            if(intersect_in(newP,smliquid[praticleIndex].mPrePosition,verts1[j],verts1[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(intersect_in(newP,smliquid[praticleIndex].mPrePosition,verts1[j],verts1[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

int smtolCT2(int praticleIndex, b2Vec2 newP)
{
    if(vertsNum2 == 0) return -1;
    for(int j = 0; j < vertsNum2;j++)
    {
        if(j != vertsNum2-1)
        {
            if(intersect_in(newP,smliquid[praticleIndex].mPrePosition,verts2[j],verts2[j+1]) != 0)
            {
                return j;
            }
        }
        else
        {
            if(intersect_in(newP,smliquid[praticleIndex].mPrePosition,verts2[j],verts2[0]) != 0)
            {
                return j;
            }
        }
    }
    return -1;
    
}

//单条边界的碰撞检测反应 用于非闭合碰撞区间
int smtolCTSingleVer(int praticleIndex, b2Vec2 newP)
{
    if(singleVerNum == 0) return -1;
    for(int j = 0; j < singleVerNum;j++)
    {
        if(intersect_in(newP,smliquid[praticleIndex].mPrePosition,singleVers[j].vec1,singleVers[j].vec2) != 0)
        {
            return j;
        }
    }
    return -1;
    
}


//计算交叉乘积(P1-P0)x(P2-P0)
double smxmult(b2Vec2 p1,b2Vec2 p2,b2Vec2 p0)
{
    return (p1.x-p0.x)*(p2.y-p0.y)-(p2.x-p0.x)*(p1.y-p0.y);
}

//判点是否在线段上,包括端点
int smdot_online_in(b2Vec2 p,b2Vec2 l1,b2Vec2 l2)
{
    return zero(xmult(p,l1,l2))&&(l1.x-p.x)*(l2.x-p.x)<eps&&(l1.y-p.y)*(l2.y-p.y)<eps;
}

//判两点在线段同侧,点在线段上返回0
int smsame_side(b2Vec2 p1,b2Vec2 p2,b2Vec2 l1,b2Vec2 l2)
{
    return xmult(l1,p1,l2)*xmult(l1,p2,l2)>eps;
}

//判三点共线
int smdots_inline(b2Vec2 p1,b2Vec2 p2,b2Vec2 p3)
{
    return zero(xmult(p1,p2,p3));
}

//判两线段相交,包括端点和部分重合
int smintersect_in(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
{
    if (!dots_inline(u1,u2,v1)||!dots_inline(u1,u2,v2))
        return !same_side(u1,u2,v1,v2)&&!same_side(v1,v2,u1,u2);
    return dot_online_in(u1,v1,v2)||dot_online_in(u2,v1,v2)||dot_online_in(v1,u1,u2)||dot_online_in(v2,u1,u2);
}

//计算两线段交点,请判线段是否相交(同时还是要判断是否平行!)
b2Vec2 smintersection(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
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
b2Vec2 smintersectionStraight(b2Vec2 u1,b2Vec2 u2,b2Vec2 v1,b2Vec2 v2)
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

int smSideOfLine(b2Vec2 p1, b2Vec2 p2, b2Vec2 pt)
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
int smPtInPoly(b2Vec2 pt, b2Vec2 *poly,int count)
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
bool smPtInPolygon(b2Vec2 p,b2Vec2* ptPolygon,int nCount)
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

void smdrawTestGrid()
{
    float dX = fluidMaxX*32.f/hashWidth; //40;//(fluidMaxX - fluidMinX);
    float dY = fluidMaxY*32.f/hashHeight;//40;//(fluidMaxY - fluidMinY);
    
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
void smcateGory(int xIndex, int yIndex)
{
    int groupNumWeights = 0;//设定一个网格最少有多少个粒子才能成为聚类条件网格

    for(int i = xIndex; i < hashWidth; i++)
    {
        for(int j = yIndex; j < hashHeight; j++)
        {
            if(smhashGridList[i][j].ifNOCountineIterator == true && (xIndex != 0 || yIndex != 0) && smhashGridList[i][j].GetSize() > groupNumWeights)
            {
                //if(pNum != 0)NSLog(@"haha1 x:%d y:%d groupid:%d pNum:%d",i,j,groupID,pNum);
                
                if((i+1) < hashWidth)//继续迭代右边聚类判断
                {
                    if(smhashGridList[i+1][j].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|1;
                        smhashGridList[i+1][j].groupFlag = smhashGridList[i+1][j].groupFlag|2;
                        smhashGridList[i+1][j].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i+1][j].neiGroupFlag = smhashGridList[i+1][j].neiGroupFlag|2;
                    }
                }
                //只做一次左边情况的特殊判断 这个是否会打乱分组还需研究 打乱的话 将改组单独分出
                if((i-1) > -1)
                {
                    if(smhashGridList[i-1][j].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|2;
                        smhashGridList[i-1][j].groupFlag = smhashGridList[i-1][j].groupFlag|1;
                        smhashGridList[i-1][j].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i-1][j].neiGroupFlag = smhashGridList[i-1][j].neiGroupFlag|1;
                    }
                }
                
                if((j+1) < hashHeight)//继续迭代上边聚类判断
                {
                    if(smhashGridList[i][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|8;
                        smhashGridList[i][j+1].groupFlag = smhashGridList[i][j+1].groupFlag|4;
                        smhashGridList[i][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i][j+1].neiGroupFlag = smhashGridList[i][j+1].neiGroupFlag|4;
                    }
                }
                //只做一次下边情况的特殊判断  打乱的话 将改组单独分出
                if((j-1) > -1)
                {
                    if(smhashGridList[i][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|4;
                        smhashGridList[i][j-1].groupFlag = smhashGridList[i][j-1].groupFlag|8;
                        smhashGridList[i][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i][j-1].neiGroupFlag = smhashGridList[i][j-1].neiGroupFlag|8;
                    }
                }
                //左上
                if((i-1)>-1&&(j+1)<hashHeight)
                {
                    if(smhashGridList[i-1][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|128;
                        smhashGridList[i-1][j+1].groupFlag = smhashGridList[i-1][j+1].groupFlag|64;
                        smhashGridList[i-1][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i-1][j+1].neiGroupFlag = smhashGridList[i-1][j+1].neiGroupFlag|64;
                    }
                }
                //右下
                if((i+1)<hashWidth&&(j-1)>-1)
                {
                    if(smhashGridList[i+1][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|64;
                        smhashGridList[i+1][j-1].groupFlag = smhashGridList[i+1][j-1].groupFlag|128;
                        smhashGridList[i+1][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i+1][j-1].neiGroupFlag = smhashGridList[i+1][j-1].neiGroupFlag|128;
                    }
                }
                //右上
                if((i+1)<hashWidth&&(j+1)<hashHeight)
                {
                    if(smhashGridList[i+1][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|32;
                        smhashGridList[i+1][j+1].groupFlag = smhashGridList[i+1][j+1].groupFlag|16;
                        smhashGridList[i+1][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i+1][j+1].neiGroupFlag = smhashGridList[i+1][j+1].neiGroupFlag|16;
                    }
                }
                //左下
                if((i-1)>-1&&(j-1)>-1)
                {
                    if(smhashGridList[i-1][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|16;
                        smhashGridList[i-1][j-1].groupFlag = smhashGridList[i-1][j-1].groupFlag|32;
                        smhashGridList[i-1][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i-1][j-1].neiGroupFlag = smhashGridList[i-1][j-1].neiGroupFlag|32;
                    }
                }

                return;
            }
            else if(smhashGridList[i][j].ifNOCountineIterator == true && (xIndex == 0 || yIndex == 0))
            {
                continue;
            }
            
            if(smhashGridList[i][j].GetSize() <= groupNumWeights && (xIndex != 0 || yIndex != 0))
            {
                return;
            }
            else if(smhashGridList[i][j].GetSize() <= groupNumWeights && (xIndex == 0 && yIndex == 0))//最早的第一次迭代 不能中断第一次循环
            {
                smhashGridList[i][j].groupFlag = 0;
                smhashGridList[i][j].groupID = -1;
                smhashGridList[i][j].ifNOCountineIterator = true;
                continue;
            }
            else if(smhashGridList[i][j].GetSize() > groupNumWeights && smhashGridList[i][j].ifNOCountineIterator == false)
            {
                //smhashGridList[i][j].groupFlag = 0;
                //here can't be 0  or miss last Iterator data
                //左上 右下 右上 左下 上 下 左 右 11111111
                smhashGridList[i][j].ifNOCountineIterator = true;
                if(smhashGridList[i][j].groupID == -1)
                {
                    smhashGridList[i][j].groupID = (++groupID);
                }
                if((i+1) < hashWidth)//继续迭代右边聚类判断
                {
                    if(smhashGridList[i+1][j].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|1;
                        smhashGridList[i+1][j].groupFlag = smhashGridList[i+1][j].groupFlag|2;
                        smhashGridList[i+1][j].groupID = smhashGridList[i][j].groupID;
                    }
                    else if(smhashGridList[i+1][j].GetSize() == 0)
                    {
                        smhashGridList[i+1][j].neiGroupFlag = smhashGridList[i+1][j].neiGroupFlag|2;
                    }
                    //[self cateGory:(i+1) yIndex:j];
                    cateGory(i+1,j);
                }
                //只做一次左边情况的特殊判断 这个是否会打乱分组还需研究 打乱的话 将改组单独分出
                if((i-1) > -1)
                {
                    if(smhashGridList[i-1][j].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|2;
                        smhashGridList[i-1][j].groupFlag = smhashGridList[i-1][j].groupFlag|1;
                        smhashGridList[i-1][j].groupID = smhashGridList[i][j].groupID;
                    }
                    else if(smhashGridList[i-1][j].GetSize() == 0)
                    {
                         smhashGridList[i-1][j].neiGroupFlag = smhashGridList[i-1][j].neiGroupFlag|1;
                    }
                    //[self cateGory:(i-1) yIndex:j];
                    cateGory(i-1,j);
                }
                
                if((j+1) < hashHeight)//继续迭代上边聚类判断
                {
                    if(smhashGridList[i][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|8;
                        smhashGridList[i][j+1].groupFlag = smhashGridList[i][j+1].groupFlag|4;
                        smhashGridList[i][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else 
                    {
                        smhashGridList[i][j+1].neiGroupFlag = smhashGridList[i][j+1].neiGroupFlag|4;
                    }
                    //[self cateGory:i yIndex:(j+1)];
                    cateGory(i,j+1);
                }
                //只做一次下边情况的特殊判断  打乱的话 将改组单独分出
                if((j-1) > -1)
                {
                    if(smhashGridList[i][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|4;
                        smhashGridList[i][j-1].groupFlag = smhashGridList[i][j-1].groupFlag|8;
                        smhashGridList[i][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i][j-1].neiGroupFlag = smhashGridList[i][j-1].neiGroupFlag|8;
                    }
                    //[self cateGory:i yIndex:(j-1)];
                    cateGory(i,j-1);
                }
                //左上
                if((i-1)>-1&&(j+1)<hashHeight)
                {
                    if(smhashGridList[i-1][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|128;
                        smhashGridList[i-1][j+1].groupFlag = smhashGridList[i-1][j+1].groupFlag|64;
                        smhashGridList[i-1][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i-1][j+1].neiGroupFlag = smhashGridList[i-1][j+1].neiGroupFlag|64;
                    }
                    //[self cateGory:(i-1) yIndex:(j+1)];
                    cateGory(i-1,j+1);
                }
                //右下
                if((i+1)<hashWidth&&(j-1)>-1)
                {
                    if(smhashGridList[i+1][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|64;
                        smhashGridList[i+1][j-1].groupFlag = smhashGridList[i+1][j-1].groupFlag|128;
                        smhashGridList[i+1][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i+1][j-1].neiGroupFlag = smhashGridList[i+1][j-1].neiGroupFlag|128;
                    }
                    //[self cateGory:(i+1) yIndex:(j-1)];
                    cateGory(i+1,j-1);
                }
                //右上
                if((i+1)<hashWidth&&(j+1)<hashHeight)
                {
                    if(smhashGridList[i+1][j+1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|32;
                        smhashGridList[i+1][j+1].groupFlag = smhashGridList[i+1][j+1].groupFlag|16;
                        smhashGridList[i+1][j+1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i+1][j+1].neiGroupFlag = smhashGridList[i+1][j+1].neiGroupFlag|16;
                    }
                    //[self cateGory:(i+1) yIndex:(j+1)];
                    cateGory(i+1,j+1);
                }
                //左下
                if((i-1)>-1&&(j-1)>-1)
                {
                    if(smhashGridList[i-1][j-1].GetSize() > groupNumWeights)
                    {
                        smhashGridList[i][j].groupFlag = smhashGridList[i][j].groupFlag|16;
                        smhashGridList[i-1][j-1].groupFlag = smhashGridList[i-1][j-1].groupFlag|32;
                        smhashGridList[i-1][j-1].groupID = smhashGridList[i][j].groupID;
                    }
                    else
                    {
                        smhashGridList[i-1][j-1].neiGroupFlag = smhashGridList[i-1][j-1].neiGroupFlag|32;
                    }
                    //[self cateGory:(i-1) yIndex:(j-1)];
                    cateGory(i-1,j-1);
                }
                
            }
        }
    }
        
}

//
//void smjiaoPoint(int i, vector<ccVertex2F>& BoundsPointVec, int boundsFlag) //上下左右 4,3,2,1
//{
//    float circleR = 60.f;
//
//    //x2+y2=r2
//    float pX = smliquid[i].mPosition.x*32.f;
//    float pY = smliquid[i].mPosition.y*32.f;
//    
//    int yuX = (int)pX%40;
//    int yuY = (int)pY%40;
//
//    if(boundsFlag == 4)//上
//    {
//        if((int)(pY+circleR/2)%40 == 0)//一个交点
//        {
//            BoundsPointVec.push_back(ccv(pX,pY+circleR/2));
//        }
//        else if(yuY+circleR/2 > 40)//两个交点；
//        {
//            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuY)*(40-yuY));
//            BoundsPointVec.push_back(ccv(pX + dis,pY+40-yuY));
//            BoundsPointVec.push_back(ccv(pX - dis,pY+40-yuY));
//            //NSLog(@"aaaa groupID : %d %ld",i,BoundsPointVec.size());
//        }
//    }
//    else if(boundsFlag == 3)//下
//    {
//        if((int)(pY-circleR/2)%40 == 0)//一个交点
//        {
//            BoundsPointVec.push_back(ccv(pX,pY-circleR/2));
//        }
//        else if(yuY < circleR/2)//两个交点；
//        {
//            float dis = sqrt((circleR/2)*(circleR/2)-(yuY)*(yuY));
//            BoundsPointVec.push_back(ccv(pX + dis,pY-yuY));
//            BoundsPointVec.push_back(ccv(pX - dis,pY-yuY));
//        }
//        
//    }
//    else if(boundsFlag == 2)//左
//    {
//        if((int)(pX-circleR/2)%40 == 0)//一个交点
//        {
//            BoundsPointVec.push_back(ccv(pX-circleR/2,pY));
//        }
//        else if(yuX < circleR/2)//两个交点；
//        {
//            float dis = sqrt((circleR/2)*(circleR/2)-(yuX)*(yuX));
//            BoundsPointVec.push_back(ccv(pX-yuX,pY + dis));
//            BoundsPointVec.push_back(ccv(pX-yuX,pY - dis));
//        }
//        
//    }
//    else if(boundsFlag == 1)//右
//    {
//        if((int)(pX+circleR/2)%40 == 0)//一个交点
//        {
//            BoundsPointVec.push_back(ccv(pX+circleR/2,pY));
//        }
//        else if(yuX+circleR/2 > 40)//两个交点；
//        {
//            float dis = sqrt((circleR/2)*(circleR/2)-(40-yuX)*(40-yuX));
//            BoundsPointVec.push_back(ccv(pX+40-yuX,pY + dis));
//            BoundsPointVec.push_back(ccv(pX+40-yuX,pY - dis));
//        }
//    }
//    
//}

