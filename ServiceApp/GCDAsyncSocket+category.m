//
//  GCDAsyncSocket+category.m
//  ServiceApp
//
//  Created by wangguopeng on 2017/4/26.
//  Copyright © 2017年 joymake. All rights reserved.
//

#import "GCDAsyncSocket+category.h"
#import <objc/runtime.h>

@implementation GCDAsyncSocket (category)
-(void)setTimeNew:(NSDate *)timeNew{
    objc_setAssociatedObject(self, _cmd, timeNew, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSDate *)timeNew{
    return objc_getAssociatedObject(self, @selector(setTimeNew:));
}
@end
