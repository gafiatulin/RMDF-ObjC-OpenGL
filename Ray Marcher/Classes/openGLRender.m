//
//  openGLRender.m
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 10/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import "openGLRender.h"
#import "shaderUtil.h"
#import <openGL/glu.h>

@interface openGLRender () {
  GLuint program;
  GLuint vao;
  double initTime;
  GLint blockSize;
}

@end

@implementation openGLRender

- (instancetype)init {
  self = [super init];
  if (self) {
    setupDone = false;
    uniforms.resolution = -1;
    uniforms.globalTime = -1;
    initTime = (double)([[NSDate date] timeIntervalSince1970]);
  }
  return self;
}

- (void)startup {
  program = compileShaders();
  glGenVertexArrays(1, &vao);
  glBindVertexArray(vao);
  uniforms.resolution = glGetUniformLocation(program, "resolution");
  uniforms.globalTime = glGetUniformLocation(program, "globalTime");
  uniforms.camP = glGetUniformLocation(program, "camPosition");
  uniforms.camD = glGetUniformLocation(program, "camDirection");
  uniforms.camR = glGetUniformLocation(program, "camRight");
  glUseProgram(program);
  setupDone = true;
}

- (void)render {
  glUniform1f(uniforms.globalTime, (GLfloat)((double)([[NSDate date] timeIntervalSince1970]) - initTime));
  glDrawArrays(GL_TRIANGLES, 0, 6);
}

- (void)shutdown {
  glDeleteProgram(program);
  glDeleteVertexArrays(1, &vao);
}
- (void)dealloc {
}

@end