//
//  RayMarchOpenGLView.m
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 10/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import "RayMarchOpenGLView.h"
#import "openGLRender.h"
#import "openGLCamera.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface RayMarchOpenGLView () {
  CVDisplayLinkRef displayLink;
  NSOpenGLPixelFormat *pixelFormat;
  GLint virtualScreen;
  BOOL enableMultisample;
  unsigned long long lastTime;
  int numOfFrames;
  NSRect oldBounds;
  bool keys[4];
}

@property(nonatomic, strong) openGLRender *rayMarchingRenderingController;
@property(nonatomic, strong) openGLCamera *rayMarchingCam;

@end

@implementation RayMarchOpenGLView

- (void)awakeFromNib {
  NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                              options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
                                                                owner:self
                                                             userInfo:nil];
  [self addTrackingArea:trackingArea];
  [self setNextResponder:[NSApplication sharedApplication]];
}

- (void)updateTrackingAreas {
  [super updateTrackingAreas];
  [self removeTrackingArea:[[self trackingAreas] firstObject]];
  NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                              options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
                                                                owner:self
                                                             userInfo:nil];
  [self addTrackingArea:trackingArea];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)isOpaque {
  return YES;
}

//------------------------------------------------------------

- (openGLRender *)rayMarchingRenderingController {
  if (!_rayMarchingRenderingController) {
    _rayMarchingRenderingController = [[openGLRender alloc] init];
  }
  return _rayMarchingRenderingController;
}

- (openGLCamera *)rayMarchingCam {
  if (!_rayMarchingCam) {
    _rayMarchingCam = [[openGLCamera alloc] init];
  }
  return _rayMarchingCam;
}

- (CVReturn)getFrameForTime:(const CVTimeStamp *)outputTime {
  @autoreleasepool {
    [self drawView];
    return kCVReturnSuccess;
  }
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
  CVReturn result = [(__bridge RayMarchOpenGLView *)displayLinkContext getFrameForTime:outputTime];
  return result;
}

- (id)initWithFrame:(NSRect)frame {
  NSOpenGLPixelFormatAttribute attribs[] = {
      NSOpenGLPFADoubleBuffer,  NSOpenGLPFAAllowOfflineRenderers,
      NSOpenGLPFAMultisample,   1,
      NSOpenGLPFASampleBuffers, 1,
      NSOpenGLPFASamples,       4,
      NSOpenGLPFAColorSize,     32,
      NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
      0};
  NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
  if (!pf) {
    NSLog(@"Failed to create pixel format.");
    return nil;
  }
  self = [super initWithFrame:frame pixelFormat:pf];
  if (self) {
    pixelFormat = pf;
    enableMultisample = YES;
  }
  return self;
}

- (void)initializeVariablesSetUpCam {
  lastTime = (long long)([[NSDate date] timeIntervalSince1970]);
  numOfFrames = 0;
  oldBounds = [self bounds];
  [[self window] setAcceptsMouseMovedEvents:YES];
  for (int i = 0; i < 4; i++)
    keys[i] = false;
  self.rayMarchingCam = [[openGLCamera alloc] initWithPosition:GLKVector3Make(0, 100, 0)];
}

- (void)setupDisplayLink {
  CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
  CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback,
                                 (__bridge void *)(self));
  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
  CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext,
                                                    cglPixelFormat);
  CVDisplayLinkStart(displayLink);
}

- (void)prepareOpenGL {
  [super prepareOpenGL];
  [[self openGLContext] makeCurrentContext];
  GLint one = 1;
  [[self openGLContext] setValues:&one forParameter:NSOpenGLCPSwapInterval];
  [self initializeVariablesSetUpCam];
  [self.rayMarchingRenderingController startup];
  if (self.rayMarchingRenderingController->setupDone) {
    GLKVector2 resolution = GLKVector2Make((GLfloat)NSWidth(oldBounds),
                                           (GLfloat)NSHeight(oldBounds));
    GLKVector3 p = [self.rayMarchingCam getPosition];
    GLKVector3 d = [self.rayMarchingCam getDirection];
    GLKVector3 r = [self.rayMarchingCam getRight];
    glUniform2fv(self.rayMarchingRenderingController->uniforms.resolution, 1,
                 (GLfloat *)(&(resolution.v)));
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camP, 1,
                 (GLfloat *)(&(p.v)));
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camD, 1,
                 (GLfloat *)(&(d.v)));
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camR, 1,
                 (GLfloat *)(&(r.v)));
  }
  [self setupDisplayLink];
}

- (void)drawView {
  [[self openGLContext] makeCurrentContext];
  unsigned long long time = (long long)([[NSDate date] timeIntervalSince1970]);
  CGLLockContext([[self openGLContext] CGLContextObj]);
  // Render
  [self.rayMarchingRenderingController render];
  //
  [[self openGLContext] flushBuffer];
  // FPS Counter
  numOfFrames++;
  if (time - lastTime >= 1) {
    [self.window setTitle:[NSString stringWithFormat:@"FPS: %f", 1000.0 / numOfFrames]];
    numOfFrames = 0;
    lastTime += 1.0;
  }
  CGLUnlockContext([[self openGLContext] CGLContextObj]);
  //
  if (keys[0])
    [self.rayMarchingCam handleKeyboard:0];
  if (keys[1])
    [self.rayMarchingCam handleKeyboard:1];
  if (keys[2])
    [self.rayMarchingCam handleKeyboard:2];
  if (keys[3])
    [self.rayMarchingCam handleKeyboard:3];
  if (keys[0] || keys[1] || keys[2] || keys[3]) {
    GLKVector3 p = [self.rayMarchingCam getPosition];
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camP, 1,
                 (GLfloat *)(&(p.v)));
  }
}

- (void)reshape {
  NSRect newBounds = [self bounds];
  if (NSWidth(newBounds) != NSWidth(oldBounds) ||
      NSHeight(newBounds) != NSHeight(oldBounds)) {
    glViewport(0, 0, NSWidth(newBounds), NSHeight(newBounds));
    oldBounds = newBounds;
    if (self.rayMarchingRenderingController->setupDone) {
      GLKVector2 resolution = GLKVector2Make((GLfloat)NSWidth(oldBounds),
                                             (GLfloat)NSHeight(oldBounds));
      glUniform2fv(self.rayMarchingRenderingController->uniforms.resolution, 1,
                   (GLfloat *)(&(resolution.v)));
    }
  }
}

- (void)dealloc {
  CVDisplayLinkStop(displayLink);
  CVDisplayLinkRelease(displayLink);
  [self.rayMarchingRenderingController shutdown];
  [self removeTrackingArea:[[self trackingAreas] firstObject]];
  self.rayMarchingRenderingController = Nil;
}

- (void)keyUp:(NSEvent *)theEvent {
  unsigned short temp = theEvent.keyCode;
  if ((temp == 13) || (temp == 126))
    keys[0] = NO;
  if ((temp == 1) || (temp == 125))
    keys[1] = NO;
  if ((temp == 0) || (temp == 123))
    keys[2] = NO;
  if ((temp == 2) || (temp == 124))
    keys[3] = NO;
}
- (void)keyDown:(NSEvent *)theEvent {
  unsigned short temp = theEvent.keyCode;
  if ((temp == 13) || (temp == 126))
    keys[0] = YES;
  if ((temp == 1) || (temp == 125))
    keys[1] = YES;
  if ((temp == 0) || (temp == 123))
    keys[2] = YES;
  if ((temp == 2) || (temp == 124))
    keys[3] = YES;
}

- (void)mouseDragged:(NSEvent *)theEvent {
  [self.rayMarchingCam handleMouse:theEvent];
  if (self.rayMarchingRenderingController->setupDone) {
    GLKVector3 d = [self.rayMarchingCam getDirection];
    GLKVector3 r = [self.rayMarchingCam getRight];
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camD, 1, (GLfloat *)(&(d.v)));
    glUniform3fv(self.rayMarchingRenderingController->uniforms.camR, 1, (GLfloat *)(&(r.v)));
  }
}

@end
