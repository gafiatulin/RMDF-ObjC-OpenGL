//
//  openGLRender.h
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 10/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

@interface openGLRender : NSObject {
@public
  bool setupDone;
  struct {
    GLint resolution;
    GLint globalTime;
    GLint camP;
    GLint camD;
    GLint camR;
  } uniforms;
}
- (void)startup;
- (void)render;
- (void)shutdown;

@end
