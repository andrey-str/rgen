/*
 * NSString+rgen.m, misc rgen specific string methods
 *
 * Copyright (c) 2011 <mattias.wadman@gmail.com>
 *
 * MIT License:
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "NSString+rgen.h"
#import "NSCharacterSet+rgen.h"

@implementation NSString (rgen)

// based on http://stackoverflow.com/questions/1918972
- (NSString *)toCamelCase:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  
  BOOL makeNextCharacterUpperCase = NO;
  for (NSInteger i = 0; i < [self length]; i++) {
    unichar c = [self characterAtIndex:i];
    if ([charSet characterIsMember:c]) {
      makeNextCharacterUpperCase = YES;
    } else if (makeNextCharacterUpperCase) {
      [output appendString:[[NSString stringWithCharacters:&c length:1]
			    uppercaseString]];
      makeNextCharacterUpperCase = NO;
    } else {
      NSString *s = [NSString stringWithCharacters:&c length:1];
      if (i == 0) {
	s = [s lowercaseString];
      }
      
      [output appendString:s];
    }
  }
  
  return output;
}

- (NSString *)charSetNormalize:(NSCharacterSet *)charSet {
  NSMutableString *output = [NSMutableString string];
  
  for (NSInteger i = 0; i < [self length]; i++) {
    unichar c = [self characterAtIndex:i];
    if (![charSet characterIsMember:c]) {
      continue;
    }
    
    [output appendString:[NSString stringWithCharacters:&c length:1]];
  }
  
  return output;
}

- (NSString *)stripSuffix:(NSArray *)suffixes {
  for (NSString *suffix in suffixes) {
    if ([self hasSuffix:suffix]) {
      return [self substringToIndex:[self length] - [suffix length]];
    }
  }
  
  return self;
}

- (NSString *)escapeCString {
  return [self stringByReplacingOccurrencesOfString:@"\""
					 withString:@"\\\""];
}

// avoid C keywords and some Objective-C stuff
- (BOOL)isReservedRgenName {
  static NSSet *names = nil;
  if (names == nil) {
    names = [[NSSet setWithObjects:
	      @"bycopy",
	      @"byref",
	      @"char",
	      @"const",
	      @"default",
	      @"delete",
	      @"double",
	      @"float",
	      @"id",
	      @"in",
	      @"inout",
	      @"int",
	      @"long",
	      @"new", // not sure
	      @"nil",
	      @"oneway",
	      @"out",
	      @"self",
	      @"short",
	      @"signed",
	      @"super",
	      @"unsigned",
	      @"void",
	      @"volatile",
	      // NSObject class/protocol instance methods with no argument
	      @"copy",
	      @"mutableCopy",
	      @"dealloc",
	      @"finalize",
	      @"classForCoder",
	      @"classForKeyedArchiver",
	      @"class",
	      @"superclass",
	      @"hash",
	      /* @"self", */ // included as keyword above
	      @"autorelease",
	      @"release",
	      @"retain",
	      @"retainCount",
	      @"description",
	      @"zone",
	      @"isProxy",
	      // rgen reserved
	      @"loadImages",
	      @"releaseImages",
	      nil]
	     retain];
  }
  
  return [names containsObject:self];  
}

- (BOOL)isSupportedImageExtByIOS {
  static NSSet *exts = nil;
  if (exts == nil) {
    // from UIImage class reference "Supported Image Formats"
    exts = [[NSSet setWithObjects:
	     @"tiff", @"tif",
	     @"jpg", @"jpeg",
	     @"gif",
	     @"png",
	     @"bmp", @"bmpf",
	     @"ico",
	     @"cur",
	     @"xbm",
	     nil]
	    retain];
  }
  
  return [exts containsObject:self];
}

+ (NSArray *)imageScaleSuffixArray:(BOOL)ipadSuffix {
  if (ipadSuffix) {
    static NSArray *suffixes = nil;
    if (suffixes == nil) {
      suffixes = [[NSArray arrayWithObjects:@"@2x",  @"@ipad", nil] retain];
    }
    return suffixes;
  } else {
    static NSArray *suffixes = nil;
    if (suffixes == nil) {
      suffixes = [[NSArray arrayWithObjects:@"@2x", nil] retain];
    }
    return suffixes;
  }
}

- (NSString *)normalizeIOSPath:(BOOL)ipadSuffix {
  if ([[[self pathExtension] lowercaseString] isSupportedImageExtByIOS]) {
    return [[[self stringByDeletingPathExtension]
	     stripSuffix:[[self class] imageScaleSuffixArray:ipadSuffix]]
	    stringByAppendingPathExtension:[self pathExtension]];
  }
  
  return self;
}

- (NSString *)propertyName {
  NSString *name = self;
  name = [[name toCamelCase:[NSCharacterSet
			     characterSetWithCharactersInString:@"._- @"]]
	  charSetNormalize:[NSCharacterSet propertyNameCharacterSet]];
  
  if ([name isReservedRgenName]) {
    name = [name stringByAppendingString:@"_"];
  }
  
  if (![[NSCharacterSet propertyNameStartCharacterSet]
	characterIsMember:[name characterAtIndex:0]]) {
    name = [@"_" stringByAppendingString:name];
  }
  
  return name;
}

- (NSString *)imagePropertyName:(BOOL)ipadSuffix {
  NSString *name = self;
  NSString *ext = [[name pathExtension] lowercaseString];
  name = [self stringByDeletingPathExtension];
  if ([ext isSupportedImageExtByIOS]) {
    name = [name stripSuffix:[[self class] imageScaleSuffixArray:ipadSuffix]];
  }
  
  return [name propertyName];
}

- (NSString *)dirPropertyName {
  return [self propertyName];
}

- (NSString *)className {
  NSString *name = self;
  
  name = [[name toCamelCase:[NSCharacterSet
			     characterSetWithCharactersInString:@"._- @"]]
	  charSetNormalize:[NSCharacterSet classNameCharacterSet]];
  
  if (![[NSCharacterSet classNameStartCharacterSet]
	characterIsMember:[name characterAtIndex:0]]) {
    name = [@"_" stringByAppendingString:name];
  }
  
  return [name capitalizedString];
}


@end