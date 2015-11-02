//
//  QrCodeView.m
//  QrCodeTest
//
//  Created by Hayware on 15/10/29.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import "QrCodeView.h"

#define MAIN_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define MAIN_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define MAIN_SCREEN_BOUNDS [UIScreen mainScreen].bounds
static const float kLineMinY = 185;
static const float kLineMaxY = 385;
static const float kReaderViewWidth = 200;
static const float kReaderViewHeight = 200;

@implementation QrCodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //画中间的基准线
        _line = [[UIImageView alloc] initWithFrame:CGRectMake((MAIN_SCREEN_WIDTH - 300) / 2.0, kLineMinY, 300, 12 * 300 / 320.0)];
        [_line setImage:[UIImage imageNamed:@"ff_QRCodeScanLine"]];
        [self addSubview:_line];
        
        //最上部view
        UIView * upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, kLineMinY)];//80
        upView.alpha = 0.3;
        upView.backgroundColor = [UIColor blackColor];
        [self addSubview:upView];
        
        //左侧的view
        UIView * leftView = [[UIView alloc] initWithFrame:CGRectMake(0, kLineMinY, (MAIN_SCREEN_WIDTH - kReaderViewWidth) / 2.0, kReaderViewHeight)];
        leftView.alpha = 0.3;
        leftView.backgroundColor = [UIColor blackColor];
        [self addSubview:leftView];
        
        //右侧的view
        UIView * rightView = [[UIView alloc] initWithFrame:CGRectMake(MAIN_SCREEN_WIDTH - CGRectGetMaxX(leftView.frame), kLineMinY, CGRectGetMaxX(leftView.frame), kReaderViewHeight)];
        rightView.alpha = 0.3;
        rightView.backgroundColor = [UIColor blackColor];
        [self addSubview:rightView];
        
        CGFloat space_h = MAIN_SCREEN_HEIGHT - kLineMaxY;
        
        //底部view
        UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, kLineMaxY, MAIN_SCREEN_WIDTH, space_h)];
        downView.alpha = 0.3;
        downView.backgroundColor = [UIColor blackColor];
        [self addSubview:downView];
        
        //四个边角
        UIImage * cornerImage = [UIImage imageNamed:@"ScanQR1"];
        
        //左侧的view
        UIImageView *leftView_image = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - cornerImage.size.width / 2.0, CGRectGetMaxY(upView.frame) - cornerImage.size.height / 2.0, cornerImage.size.width, cornerImage.size.height)];
        leftView_image.image = cornerImage;
        [self addSubview:leftView_image];
        
        cornerImage = [UIImage imageNamed:@"ScanQR2"];
        
        //右侧的view
        UIImageView *rightView_image = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rightView.frame) - cornerImage.size.width / 2.0, CGRectGetMaxY(upView.frame) - cornerImage.size.height / 2.0, cornerImage.size.width, cornerImage.size.height)];
        rightView_image.image = cornerImage;
        [self addSubview:rightView_image];
        cornerImage = [UIImage imageNamed:@"ScanQR3"];
        
        //底部view
        UIImageView *downView_image = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - cornerImage.size.width / 2.0, CGRectGetMinY(downView.frame) - cornerImage.size.height / 2.0, cornerImage.size.width, cornerImage.size.height)];
        downView_image.image = cornerImage;
        [self addSubview:downView_image];
        
        cornerImage = [UIImage imageNamed:@"ScanQR4"];
        
        UIImageView * downViewRight_image = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rightView.frame) - cornerImage.size.width / 2.0, CGRectGetMinY(downView.frame) - cornerImage.size.height / 2.0, cornerImage.size.width, cornerImage.size.height)];
        downViewRight_image.image = cornerImage;
        [self addSubview:downViewRight_image];
        
        //说明label
        UILabel *labIntroudction = [[UILabel alloc] init];
        labIntroudction.backgroundColor = [UIColor clearColor];
        labIntroudction.frame = CGRectMake(CGRectGetMaxX(leftView.frame), CGRectGetMinY(downView.frame) + 25, kReaderViewWidth, 20);
        labIntroudction.textAlignment = NSTextAlignmentCenter;
        labIntroudction.font = [UIFont boldSystemFontOfSize:13.0];
        labIntroudction.textColor = [UIColor whiteColor];
        labIntroudction.text = @"将二维码置于框内,即可自动扫描";
        [self addSubview:labIntroudction];
        
        UIView *scanCropView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - 1,kLineMinY,self.frame.size.width - 2 * CGRectGetMaxX(leftView.frame) + 2, kReaderViewHeight + 2)];
        scanCropView.layer.borderColor = [UIColor greenColor].CGColor;
        scanCropView.layer.borderWidth = 2.0;
        [self addSubview:scanCropView];
        
        _lineTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 20 target:self selector:@selector(animationLine) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)animationLine
{
    __block CGRect frame = _line.frame;
    
    static BOOL flag = YES;
    
    if (flag) {
        frame.origin.y = kLineMinY;
        flag = NO;
        
        [UIView animateWithDuration:1.0 / 20 animations:^{
            
            frame.origin.y += 5;
            _line.frame = frame;
            
        } completion:nil];
    } else {
        if (_line.frame.origin.y >= kLineMinY) {
            if (_line.frame.origin.y >= kLineMaxY - 12) {
                frame.origin.y = kLineMinY;
                _line.frame = frame;
                
                flag = YES;
            } else {
                [UIView animateWithDuration:1.0 / 20 animations:^{
                    
                    frame.origin.y += 5;
                    _line.frame = frame;
                    
                } completion:nil];
            }
        } else {
            flag = !flag;
        }
    }
}

@end
