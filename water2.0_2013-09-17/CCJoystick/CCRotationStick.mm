//
//  CCRorationStick.m
//  WaterSprite4
//
//  Created by zte-s on 13-5-29.
//  Copyright 2013年 zte. All rights reserved.
//

#import "CCRotationStick.h"
#import "SPHNode.h"


@implementation CCRotationStick
@synthesize innerCircle,outerCircle,stickPosition,unusedSection1,unusedSection1VecNum,disappearSection,disappearRadius;

-(void)updateNewPosition:(CGPoint)newPosition
{
    stickPosition = newPosition;
    if(innerCircle != nil)innerCircle.position = newPosition;
    if(outerCircle != nil)outerCircle.position = newPosition;
    
}

-(id)initWithCircle:(CCSprite *)innerS outerCircle:(CCSprite *)outerS innerRadius:(float)innerR outerRadius:(float)outerR position:(CGPoint)ps delegate:(id)mouseD
{
    if( (self=[super init] ))
    {
        self.mouseEnabled = YES;
        //[[CCEventDispatcher sharedDispatcher] addTouchDelegate:self priority:1];
        
        //[[CCEventDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
        //[self setMousePriority:-10];

        self.anchorPoint = ccp(0,0);
        self.position = ccp(0.f,0.f);
        if(innerS != nil)
        {
            innerCircle = innerS;
            innerCircle.anchorPoint = ccp(.5f,.5f);
            innerCircle.position = ps;
            [self addChild:innerCircle z:10];
        }
        if(outerS != nil)
        {
            outerCircle = outerS;
            outerCircle.anchorPoint = ccp(.5f,.5f);
            outerCircle.position = ps;
            [self addChild:outerCircle z:10];
        }
        stickPosition.x = ps.x;
        stickPosition.y = ps.y;
        mouseDelegate = mouseD;
        innerRadius = innerR;
        outerRadius = outerR;
        prevPoint = ps;//当第一次刚点下去创建该手柄时 有可能玩家就已经开始了移动手柄的操作
    }
    return self;
    
}

- (BOOL)ccMouseDown:(NSEvent *)event
{
    ifmouseEventTranslateToOther = NO;
    NSPoint location = [event locationInWindow];
    prevPoint.x = location.x;
    prevPoint.y = location.y;
    
    if(((prevPoint.x - stickPosition.x)*(prevPoint.x - stickPosition.x) + (prevPoint.y - stickPosition.y)*(prevPoint.y - stickPosition.y) >=  innerRadius*innerRadius) && ((prevPoint.x - stickPosition.x)*(prevPoint.x - stickPosition.x) + (prevPoint.y - stickPosition.y)*(prevPoint.y - stickPosition.y) <=  outerRadius*outerRadius))//表示移动的点在内环到外环的中间位置 如果产生move事件 这时候应该使用旋转功能
    {
        gestureType = 1;
        return YES;
    }
    else if(((prevPoint.x - stickPosition.x)*(prevPoint.x - stickPosition.x) + (prevPoint.y - stickPosition.y)*(prevPoint.y - stickPosition.y) <  innerRadius*innerRadius))//表示手指的点在内环位置 如果产生move事件 应该使用移动功能
    {
        gestureType = 2;
        return YES;
    }
    return NO;
    
}

-(BOOL) ccMouseDragged:(NSEvent*)event
{
    CGPoint location = ccp([event locationInWindow].x,[event locationInWindow].y);
    if(gestureType == 1)//旋转
    {
        float changeAngle = [CCRotationStick acosAngle:prevPoint cicleCenter:stickPosition lastPoint:location];
        if(fabs(changeAngle) < 1e-12 || fabs(changeAngle) > 100000)return NO;
        changeAngle = -1.f*changeAngle/40;
        NSLog(@"ca : %f",changeAngle);
        if(innerCircle != nil)
        {
            innerCircle.rotation = innerCircle.rotation + CC_RADIANS_TO_DEGREES(changeAngle);//changeAngle*180/PI;
        }
        if(outerCircle != nil)
        {
            outerCircle.rotation = outerCircle.rotation + CC_RADIANS_TO_DEGREES(changeAngle);//changeAngle*180/PI;
        }
        //((CCTool*)mouseDelegate).mainSprite.rotation = ((CCTool*)mouseDelegate).mainSprite.rotation + changeAngle*180/PI;
        [mouseDelegate rotation:changeAngle];
        
        prevPoint = location;//重新设置前一个移动坐标点
        ifmouseEventTranslateToOther = YES;//事件不传给其他层
    }
    else if(gestureType == 2)//移动
    {
        CGPoint offset = ccp(location.x - prevPoint.x,location.y - prevPoint.y);
        if(innerCircle != nil)
        {
            innerCircle.position = ccp(innerCircle.position.x+offset.x,innerCircle.position.y+offset.y);
        }
        if(outerCircle != nil)
        {
            outerCircle.position = ccp(outerCircle.position.x+offset.x,outerCircle.position.y+offset.y);
        }
        //stickPosition = outerCircle.position;
        [mouseDelegate move:offset];
        prevPoint = location;//重新设置前一个移动坐标点
        ifmouseEventTranslateToOther = YES;//事件不传给其他层
    }
    return ifmouseEventTranslateToOther;
    return NO;
    
}

-(BOOL) ccMouseUp:(NSEvent*)event
{
    //added by tr 2013-10-05
    if(gestureType == 2)
    {
        if(unusedSection1VecNum > 0 && PtInPolygon(b2Vec2(innerCircle.position.x/PTM_RATIO,innerCircle.position.y/PTM_RATIO),unusedSection1,unusedSection1VecNum) == true)
        {
            //NSLog(@"ddddd %d",PtInPoly(b2Vec2(innerCircle.position.x/PTM_RATIO,innerCircle.position.y/PTM_RATIO),unusedSection1,unusedSection1VecNum));
            if(innerCircle != nil)
            {
                innerCircle.position = stickPosition;
            }
            if(outerCircle != nil)
            {
                outerCircle.position = stickPosition;
            }
            [mouseDelegate setBodyPosition:stickPosition];
        }
        else
        {
            stickPosition = outerCircle.position;
        }
        //看道具是否回收
        if((stickPosition.x >= disappearSection.x-disappearRadius && stickPosition.x <= disappearSection.x+disappearRadius)&&(stickPosition.y >= disappearSection.y-disappearRadius && stickPosition.y <= disappearSection.y+disappearRadius))
        {
            //[self removeFromParentAndCleanup:YES];
            SPHNode* sphLayer = (SPHNode*)gameLayer;
            sphLayer.usedToolsNum--;
            [(CCTool*)mouseDelegate removeFromParentAndCleanup:YES];
        }
    }
    //ended by tr 2013-10-05
    prevPoint = ccp(0.f,0.f);
    gestureType = 0;
    return ifmouseEventTranslateToOther;
    
}

-(float)rotationEvent:(CGPoint)previousPoint curPoint:(CGPoint)currentPoint
{
    float changeAngle;
    if(fabs(previousPoint.x - currentPoint.x) < FLT_EPSILON)//垂直滑动
    {
        if(previousPoint.y - currentPoint.y > 0 && (previousPoint.x < stickPosition.x - innerRadius && previousPoint.x > stickPosition.x - outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自上往下滑动 顺时针转动 触点在左边区域
        {
            changeAngle = -1*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y > 0 && (previousPoint.x > stickPosition.x + innerRadius && previousPoint.x < stickPosition.x + outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自上往下滑动 逆时针转动 触点在右边区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y < 0 && (previousPoint.x < stickPosition.x - innerRadius && previousPoint.x > stickPosition.x - outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自下往上滑动 顺时针转动 触点在左边区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y < 0 && (previousPoint.x > stickPosition.x + innerRadius && previousPoint.x < stickPosition.x + outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自下往上滑动 逆时针转动 触点在右边区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        
    }
    else if(fabs(previousPoint.y - currentPoint.y) < FLT_EPSILON)//水平滑动
    {
        if(previousPoint.x - currentPoint.x > 0 && (previousPoint.y > stickPosition.y + innerRadius && previousPoint.y < stickPosition.y + outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自右往左滑动 逆时针转动 触点在上方区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x > 0  && (previousPoint.y < stickPosition.y - innerRadius && previousPoint.y > stickPosition.y - outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自右往左滑动 顺时针转动 触点在下方区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x < 0 && (previousPoint.y > stickPosition.y + innerRadius && previousPoint.y < stickPosition.y + outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自左往右滑动 顺时针转动 触点在上方区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x < 0 && (previousPoint.y < stickPosition.y - innerRadius && previousPoint.y > stickPosition.y - outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自左往右滑动 顺时针转动 触点在下方区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
    }
    
    else//算斜率
    {
        //y = kx+b; k = y'/x';
        float k = (previousPoint.y - currentPoint.y)/(previousPoint.x - currentPoint.x);
        if(k < -1)
        {
            
        }
        else if(k >= -1 && k<= 1)
        {
            
        }
        else if(k > 1)
        {
            
        }
        
        if(previousPoint.x - currentPoint.x > 0 && (previousPoint.y > stickPosition.y + innerRadius && previousPoint.y < stickPosition.y + outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自右往左滑动 逆时针转动 触点在上方区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x > 0  && (previousPoint.y < stickPosition.y - innerRadius && previousPoint.y > stickPosition.y - outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自右往左滑动 顺时针转动 触点在下方区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x < 0 && (previousPoint.y > stickPosition.y + innerRadius && previousPoint.y < stickPosition.y + outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自左往右滑动 顺时针转动 触点在上方区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.x - currentPoint.x < 0 && (previousPoint.y < stickPosition.y - innerRadius && previousPoint.y > stickPosition.y - outerRadius) && (previousPoint.x <= stickPosition.x + innerRadius && previousPoint.x >= stickPosition.x - innerRadius))//自左往右滑动 顺时针转动 触点在下方区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        
        else if(previousPoint.y - currentPoint.y > 0 && (previousPoint.x < stickPosition.x - innerRadius && previousPoint.x > stickPosition.x - outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自上往下滑动 顺时针转动 触点在左边区域
        {
            changeAngle = -1*RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y > 0 && (previousPoint.x > stickPosition.x + innerRadius && previousPoint.x < stickPosition.x + outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自上往下滑动 逆时针转动 触点在右边区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y < 0 && (previousPoint.x < stickPosition.x - innerRadius && previousPoint.x > stickPosition.x - outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自下往上滑动 顺时针转动 触点在左边区域
        {
            changeAngle = RotationSpeed*PI/180.f;
            return changeAngle;
        }
        else if(previousPoint.y - currentPoint.y < 0 && (previousPoint.x > stickPosition.x + innerRadius && previousPoint.x < stickPosition.x + outerRadius) && (previousPoint.y <= stickPosition.y + innerRadius && previousPoint.y >= stickPosition.y - innerRadius))//自下往上滑动 逆时针转动 触点在右边区域
        {
            changeAngle = -1.f*RotationSpeed*PI/180.f;
            return changeAngle;
        }
    }
    return 0.f;
    
}

+(float)acosAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3
{
    //added by tr 2013-05-29
    int steering;//转向 最后获取角度的正负值
    //vector1
    float xV1 = p2.x - p1.x;
    float yV1 = p2.y - p1.y; 
    //vector2
    float xV2 = p3.x - p2.x;
    float yV2 = p3.y - p2.y;
    //使用向量叉积来判断是逆时针还是顺时针
    if(xV1*yV2 - yV1*xV2 > 1e-12) steering = -1; //p1->p2->p3 逆时针
    else if(fabs(xV1*yV2 - yV1*xV2) <= 1e-12) steering = 1; //p1->p2->p3 直线上
    else if(xV1*yV2 - yV1*xV2 < -1*(1e-12)) steering = 1; //p1->p2->p3 顺时针
    
    //if ((0==xV1 && 0 ==yV1)&&(0 == xV2 && 0 == yV2))
    if (fabs((xV1*xV1 + yV1*yV1)) <= 1e-12 || fabs((xV2*xV2 + yV2*yV2))  <= 1e-12)
        return 0.f;
    else
        return steering*acos((xV1*xV2 + yV1*yV2) / sqrt((xV1*xV1 + yV1*yV1)*(xV2*xV2 + yV2*yV2)));//steering*
    //ended by tr 2013-05-29
    
}

+(float)asinAngle:(CGPoint)p1 cicleCenter:(CGPoint)p2 lastPoint:(CGPoint)p3;
{
    //vector1
    float xV1 = p2.x - p1.x;
    float yV1 = p2.y - p1.y; 
    //vector2
    float xV2 = p3.x - p2.x;
    float yV2 = p3.y - p2.y;
    if ((0==xV1 && 0 ==yV1)&&(0 == xV2 && 0 == yV2))
        return 0;
    else
    {
        float dot = sqrt((xV1*xV1 + yV1*yV1)*(xV2*xV2 + yV2*yV2));
        if(dot < 1e-12)
            return 0.0f;
        else
            return asin((xV1*xV2 + yV1*yV2) / dot);
    };
    
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    if(innerCircle != nil)
    {
        [innerCircle removeFromParentAndCleanup:YES];
    }
    if(outerCircle != nil)
    {
        [outerCircle removeFromParentAndCleanup:YES];
    }
//    if(mouseDelegate != nil)
//    {
//        [mouseDelegate removeFromParentAndCleanup:YES];
//    }
    [super dealloc];
    
}

@end
