//
//  SerViceAPP.m
//  SerVe
//
//  Created by qianhaifeng on 16/5/5.
//  Copyright © 2016年 qianhaifeng. All rights reserved.
//

#import "SerViceAPP.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncSocket+category.h"

@interface SerViceAPP()<GCDAsyncSocketDelegate>

@property(nonatomic, strong)GCDAsyncSocket *serve;
@property(nonatomic, strong)NSMutableArray *socketConnectsM;
@property(nonatomic, strong)NSThread *checkThread;
@end

static SerViceAPP *instance;
@implementation SerViceAPP

+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    return instance;
}

-(NSThread *)checkThread{
    return _checkThread = _checkThread?:[[NSThread alloc]initWithTarget:self selector:@selector(checkClientOnline) object:nil];
}

-(GCDAsyncSocket *)serve{
    if (!_serve) {
        _serve = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        _serve.delegate = self;
    }
    return _serve;
}

-(NSMutableArray *)socketConnectsM{
    return _socketConnectsM= _socketConnectsM?:[NSMutableArray array];
}

-(void)openSerVice{
    NSError *error;
    if (self.serve.isDisconnected) {
        [self.checkThread start];
        BOOL sucess = [self.serve acceptOnPort:8088 error:&error];
        NSLog(sucess?@"端口开启成功,并监听客户端请求连接...":@"端口开启失...");
    }
}

- (void)closeService{
    if (!self.checkThread.isCancelled) {
        [self.checkThread cancel];
    }
    if (self.serve.isConnected) {
        @synchronized (_serve) {
            [self.serve disconnect];
        }
    }
}
#pragma delegate

- (void)socket:(GCDAsyncSocket *)serveSock didAcceptNewSocket:(GCDAsyncSocket *)clientSocket{
    NSLog(@"%@ IP: %@: %zd 客户端请求连接...",clientSocket,clientSocket.connectedHost,clientSocket.connectedPort);
    // 1.将客户端socket保存起来
    clientSocket.timeNew = [NSDate date];
    [self.socketConnectsM addObject:clientSocket];
    self.userNumberBlock?self.userNumberBlock(self.socketConnectsM.count):nil;
    [clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag  {
    NSString *clientStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    ![clientStr isEqualToString:@"heart"] && clientStr.length!=0 &&self.messageBlock?self.messageBlock(clientSocket,clientStr):nil;
    for (GCDAsyncSocket *socket in self.socketConnectsM) {
         if (![clientSocket isEqual:socket]) {
             //群聊 发送给其他客户端
             if(![clientStr isEqualToString:@"heart"] && clientStr.length!=0)
             {
                 [self writeDataWithSocket:socket str:clientStr];
             }
         }
         else{socket.timeNew = [NSDate date];}
    }
    [clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"又下线");
    [self.socketConnectsM enumerateObjectsUsingBlock:^(GCDAsyncSocket *client, NSUInteger idx, BOOL * _Nonnull stop) {
        if([client isEqual:sock]){
            [self.socketConnectsM removeObject:client];
            *stop = YES;
        }
    }];
}

-(void)exitWithSocket:(GCDAsyncSocket *)clientSocket{
    [self writeDataWithSocket:clientSocket str:@"成功退出\n"];
    [self.socketConnectsM enumerateObjectsUsingBlock:^(GCDAsyncSocket *client, NSUInteger idx, BOOL * _Nonnull stop) {
        if([client isEqual:clientSocket]){
            [self.socketConnectsM removeObject:client];
            *stop = YES;
        }
    }];
    NSLog(@"当前在线用户个数:%ld",self.socketConnectsM.count);
    self.userNumberBlock?self.userNumberBlock(self.socketConnectsM.count):nil;
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"数据发送成功..");
}

- (void)writeDataWithSocket:(GCDAsyncSocket*)clientSocket str:(NSString*)str{
    [clientSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

#pragma checkTimeThread

//开启线程 启动runloop 循环检测客户端socket最新time
- (void)checkClientOnline{
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:35 target:self selector:@selector(repeatCheckClinetOnline) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]run];
    }
}

//移除 超过心跳的 client
- (void)repeatCheckClinetOnline{
    if (self.socketConnectsM.count == 0) {
        return;
    }
    NSDate *date = [NSDate date];
    NSMutableArray *arrayNew = [NSMutableArray array];
    for (GCDAsyncSocket *socket in self.socketConnectsM ) {
        if ([date timeIntervalSinceDate:socket.timeNew]>30) {
            continue;
        }
        [arrayNew addObject:socket   ];
    }
    self.socketConnectsM = arrayNew;
    self.userNumberBlock?self.userNumberBlock(self.socketConnectsM.count):nil;
}
@end
