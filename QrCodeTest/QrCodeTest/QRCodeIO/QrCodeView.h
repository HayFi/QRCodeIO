//
//  QrCodeView.h
//  QrCodeTest
//
//  Created by Hayware on 15/10/29.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QrCodeView : UIView

@property (nonatomic, strong) UIImageView * line;//交互线
@property (nonatomic, strong) NSTimer * timeMachine;//交互线控制

@end
