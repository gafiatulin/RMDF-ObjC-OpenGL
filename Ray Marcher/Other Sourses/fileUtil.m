//
//  fileUtil.m
//  Ray Marcher
//
//  Created by Victor Gafiatulin on 11/04/14.
//  Copyright (c) 2014 Victor Gafiatulin. All rights reserved.
//

#import <sys/stat.h>
#import <Foundation/Foundation.h>

char *readFile(const char *name) {
  const char *path =
      [[[NSBundle mainBundle] pathForResource:@(name)
                                       ofType:nil] fileSystemRepresentation];
  struct stat statbuf;
  FILE *fh;
  char *source;
  fh = fopen(path, "r");
  if (fh == 0)
    return 0;
  stat(path, &statbuf);
  if (!statbuf.st_size)
    return 0;
  source = (char *)malloc(statbuf.st_size + 1);
  fread(source, statbuf.st_size, 1, fh);
  source[statbuf.st_size] = '\0';
  fclose(fh);
  return source;
}