//
//  shaderUtil.cpp
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 11/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#include "shaderUtil.h"
#include "fileUtil.h"
#include <stdio.h>

GLuint loadShaderProgramFromFile(const char *filename, GLenum shaderType) {
  GLchar const *shader_source = readFile(filename);
  if (!shader_source)
    return 0;
  GLuint shader = glCreateShader(shaderType);
  glShaderSource(shader, 1, &shader_source, NULL);
  glCompileShader(shader);
  GLint shaderCompiled;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &shaderCompiled);
  if (shaderCompiled == GL_FALSE) {
    GLint len;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
    if (len != 0) {
      char str[len];
      glGetShaderInfoLog(shader, len, NULL, &str[0]);
      printf("%s", str);
    }
    return 0;
  }
  return shader;
}

GLuint compileShaders() {
  GLuint program = glCreateProgram();
  GLuint vertexShader = loadShaderProgramFromFile("vs.glsl", GL_VERTEX_SHADER);
  GLuint tessellationControlShader =
      loadShaderProgramFromFile("tcs.glsl", GL_TESS_CONTROL_SHADER);
  GLuint tessellationEvaluationShader =
      loadShaderProgramFromFile("tes.glsl", GL_TESS_EVALUATION_SHADER);
  GLuint geometryShader =
      loadShaderProgramFromFile("gs.glsl", GL_GEOMETRY_SHADER);
  GLuint fragmentShader =
      loadShaderProgramFromFile("fs.glsl", GL_FRAGMENT_SHADER);
  // OpenGL Core 4.3 required
  // GLuint computeShader = loadShaderProgramFromFile("cs.glsl",
  // GL_COMPUTE_SHADER);
  if (vertexShader)
    glAttachShader(program, vertexShader);
  if (tessellationControlShader)
    glAttachShader(program, tessellationControlShader);
  if (tessellationEvaluationShader)
    glAttachShader(program, tessellationEvaluationShader);
  if (geometryShader)
    glAttachShader(program, geometryShader);
  if (fragmentShader)
    glAttachShader(program, fragmentShader);
  // OpenGL Core 4.3 required
  // if(computeShader) glAttachShader(program, computeShader);
  glLinkProgram(program);
  glDeleteShader(vertexShader);
  glDeleteShader(tessellationControlShader);
  glDeleteShader(tessellationEvaluationShader);
  glDeleteShader(geometryShader);
  glDeleteShader(fragmentShader);
  GLint programLinked;
  glGetProgramiv(program, GL_LINK_STATUS, &programLinked);
  if (programLinked == GL_FALSE) {
    GLint len;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
    if (len != 0) {
      char str[len];
      glGetProgramInfoLog(program, len, NULL, &str[0]);
      printf("%s", str);
    }
    return 0;
  }
  return program;
}