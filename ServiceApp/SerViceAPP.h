//
//  SerViceAPP.h
//  SerVe
//
//  Created by qianhaifeng on 16/5/5.
//  Copyright © 2016年 qianhaifeng. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GCDAsyncSocket;
typedef void (^SocketBlock)(GCDAsyncSocket *client,NSString *message);
typedef void (^SocketUserBlock)(NSInteger number);
@interface SerViceAPP : NSObject

+ (instancetype)shareInstance;

-(void)openSerVice;

- (void)closeService;

@property (nonatomic,copy) SocketBlock messageBlock;

@property (nonatomic,copy) SocketUserBlock userNumberBlock;

@end
