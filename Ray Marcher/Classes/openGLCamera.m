//
//  openGLCamera.m
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 12/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import "openGLCamera.h"
#define DEFAULT_MODE true
#define DEFAULT_POSITION GLKVector3Make(0.0f, 0.0f, -1.0f)
#define DEFAULT_ROTATION GLKVector2Make(0.0f, 0.0f)
#define DEFAULT_SPEED GLKVector2Make(0.01f, 7.5f)

enum { keyUP, keyDown, keyLeft, keyRight };

@interface openGLCamera () {
  bool flyCam;
  GLKVector3 position;
  GLKVector3 direction;
  GLKVector3 right;
  GLKVector2 rotation;
  GLKVector2 speed;
}

@end

@implementation openGLCamera

- (instancetype)initWith:(bool)mode
                position:(GLKVector3)pos
                rotation:(GLKVector2)rot
                   speed:(GLKVector2)sp {
  self = [super init];
  if (self) {
    flyCam = mode;
    position = pos;
    rotation = rot;
    speed = sp;
    direction = GLKVector3Normalize(
        GLKVector3Make(cos(rotation.x) * sin(rotation.y), sin(rotation.x),
                       cos(rotation.x) * cos(rotation.y)));
    right = GLKVector3Normalize(
        GLKVector3Make(-cos(rotation.y), 0.0f, sin(rotation.y)));
  }
  return self;
}

- (instancetype)init {
  return [self initWith:DEFAULT_MODE
               position:DEFAULT_POSITION
               rotation:DEFAULT_ROTATION
                  speed:DEFAULT_SPEED];
}

- (instancetype)initWithMode:(bool)mode {
  return [self initWith:mode
               position:DEFAULT_POSITION
               rotation:DEFAULT_ROTATION
                  speed:DEFAULT_SPEED];
}

- (instancetype)initWithSpeed:(GLKVector2)sp {
  return [self initWith:DEFAULT_MODE
               position:DEFAULT_POSITION
               rotation:DEFAULT_ROTATION
                  speed:sp];
}

- (instancetype)initWithPosition:(GLKVector3)pos {
  return [self initWith:DEFAULT_MODE
               position:pos
               rotation:DEFAULT_ROTATION
                  speed:DEFAULT_SPEED];
}

- (instancetype)initWithRotation:(GLKVector2)rot {
  return [self initWith:DEFAULT_MODE
               position:DEFAULT_POSITION
               rotation:rot
                  speed:DEFAULT_SPEED];
}

- (void)handleMouse:(NSEvent *)mouseEvent {
  rotation.x -= mouseEvent.deltaY * speed.x;
  rotation.y -= mouseEvent.deltaX * speed.x;
  direction = GLKVector3Normalize(
      GLKVector3Make(cos(rotation.x) * sin(rotation.y), sin(rotation.x),
                     cos(rotation.x) * cos(rotation.y)));
  right = GLKVector3Normalize(
      GLKVector3Make(-cos(rotation.y), 0.0f, sin(rotation.y)));
}

- (void)handleKeyboard:(int)keyCode {
  switch (keyCode) {
  case keyUP:
    position =
        GLKVector3Add(position, GLKVector3MultiplyScalar(direction, speed.y));
    break;
  case keyDown:
    position = GLKVector3Subtract(position,
                                  GLKVector3MultiplyScalar(direction, speed.y));
    break;
  case keyLeft:
    position =
        GLKVector3Subtract(position, GLKVector3MultiplyScalar(right, speed.y));
    break;
  case keyRight:
    position =
        GLKVector3Add(position, GLKVector3MultiplyScalar(right, speed.y));
    break;
  default:
    NSLog(@"Unidentified keyCode");
    break;
  }
}

- (GLKVector3)getPosition {
  return position;
}
- (GLKVector3)getDirection {
  return direction;
}
- (GLKVector3)getRight {
  return right;
}
//-(GLKVector3) getUp{return GLKVector3CrossProduct(right, direction);}

@end
