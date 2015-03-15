//
//  openGLCamera.h
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 12/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

@interface openGLCamera : NSObject

- (instancetype)init;
- (instancetype)initWithMode:(bool)mode;
- (instancetype)initWithSpeed:(GLKVector2)sp;
- (instancetype)initWithPosition:(GLKVector3)pos;
- (instancetype)initWithRotation:(GLKVector2)rot;
- (instancetype)initWith:(bool)mode
                position:(GLKVector3)pos
                rotation:(GLKVector2)rot
                   speed:(GLKVector2)sp;
- (void)handleMouse:(NSEvent *)mouseEvent;
- (void)handleKeyboard:(int)keyCode;
- (GLKVector3)getPosition;
- (GLKVector3)getDirection;
- (GLKVector3)getRight;
//-(GLKVector3) getUp;

@end
