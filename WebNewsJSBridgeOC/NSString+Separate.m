//
//  NSString+Separate.m
//  WebNewsJSBridgeOC
//
//  Created by Ronaldinho on 15/8/21.
//  Copyright (c) 2015年 HotWordLand. All rights reserved.
//

#import "NSString+Separate.h"

@implementation NSString (Separate)
- (NSString *)SeparateFromString:(NSString *)fromString ToString:(NSString *)toString {
    NSString *selfString = self;
    if (fromString && [selfString rangeOfString:fromString].length) {
        selfString = [selfString substringFromIndex:[selfString rangeOfString:fromString].location + fromString.length];
    }
    if (toString && [selfString rangeOfString:toString].length) {
        selfString = [selfString substringToIndex:[selfString rangeOfString:toString].location];
    }
    
    return selfString;
}

@end
