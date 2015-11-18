//
//  QrCodeViewController.h
//  QrCodeTest
//
//  Created by Hayware on 15/10/27.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FailMessageFlag @"failMessage" //扫描取消
#define CancelMessageFlag @"cancelMessage" //扫描失败

@interface QrCodeViewController : UIViewController

- (void)scanQrcodeWithResultBlock:(void (^)(QrCodeViewController * qrVC, NSString * resultMessage))block;

- (void)backAndRemove;

@end
