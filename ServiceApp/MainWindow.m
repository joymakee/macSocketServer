//
//  MainWindow.m
//  ServiceApp
//
//  Created by wangguopeng on 2017/2/17.
//  Copyright © 2017年 joymake. All rights reserved.
//

#import "MainWindow.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import "SerViceAPP.h"
#import "GCDAsyncSocket.h"
#import <CoreImage/CoreImage.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@interface MainWindow ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *addressTextField;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSTextField *userNumberTextField;
@property (weak) IBOutlet NSTextField *clientAddressLabel;
@property (weak) IBOutlet NSTextField *clientData;
@property (weak) IBOutlet NSImageView *qrCodeImageView;
@end

@implementation MainWindow

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.addressTextField setStringValue:[self getIPAddress:true]];
    self.clientData.maximumNumberOfLines = 10;
    [self generateQrCodeImage];
}
- (IBAction)touchAction:(NSButton *)sender {
    [[SerViceAPP shareInstance] openSerVice];
    sender.layer.backgroundColor = [NSColor colorWithRed:0.1 green:0.9 blue:0.2 alpha:0.7].CGColor;
    sender.layer.borderWidth =1;
    sender.layer.masksToBounds = YES;
    sender.layer.cornerRadius = 3;
    __weak typeof (&*self)weakSelf = self;
    [SerViceAPP shareInstance].messageBlock=^(GCDAsyncSocket *client,NSString *message){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.clientAddressLabel.stringValue = [NSString stringWithFormat:@"地址:%@\t端口:%hu",client.connectedHost,client.connectedPort];
            weakSelf.clientData.stringValue = message;
 
        });
    };
    
    [SerViceAPP shareInstance].userNumberBlock = ^(NSInteger number) {
        dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.userNumberTextField.stringValue = [@(number) stringValue];
        });
    };
}

- (void)generateQrCodeImage{
    //1.实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
   // CIFilter用来表示CoreImage提供的各种滤镜。滤镜使用键-值来设置输入值，这些值设置好之后，CIFilter就可以用来生成新的CIImage输出图像。这里的输出的图像不会进行实际的图像渲染。
    
    //2.恢复滤镜的默认属性（因为滤镜有可能保存上一次的属性）
    [filter setDefaults];
    //3.经字符串转化成NSData
    NSData *data = [self.addressTextField.stringValue dataUsingEncoding:NSUTF8StringEncoding];
    //4.通过KVC设置滤镜，传入data，将来滤镜就知道要通过传入的数据生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    //5.生成二维码
    CIImage *ciImage = [filter outputImage];
    //CIImage是CoreImage框架中最基本代表图像的对象，他不仅包含元图像数据，还包含作用在原图像上的滤镜链。
    
    NSImage *nsImage = [self createNonInterpolatedUIImageFormCIImage:ciImage withSize:self.qrCodeImageView.bounds.size.width];
    //6.设置生成好的二维码到imageVIew上
    self.qrCodeImageView.image = nsImage;
}

- (NSImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    //设置比例
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap（位图）;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [self imageFromCGImageRef:scaledImage];
}

//将CGImageRef转换为NSImage *

- (NSImage*) imageFromCGImageRef:(CGImageRef)image

{
    
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    
    CGContextRef imageContext = nil;
    
    NSImage* newImage = nil;
    
    // Get the image dimensions.
    
    imageRect.size.height = CGImageGetHeight(image);
    
    imageRect.size.width = CGImageGetWidth(image);
    
    // Create a new image to receive the Quartz image data.
    
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    
    [newImage lockFocus];
    
    // Get the Quartz context and draw.
    
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]
                                  
                                  graphicsPort];
    
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image);
    
    [newImage unlockFocus];
    
    return newImage;
    
}

//获取设备当前网络IP地址
- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

//获取所有相关IP信息
- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

@end
