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

#define HF_TimeInterval 1.0 / 20.0
static const float line_MinY = 185;
static const float line_MaxY = 385;
static const float viewWidth = 200;
static const float viewHeight = 200;

@interface QrCodeView ()
{
    BOOL _flag;
}

@end

@implementation QrCodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //画中间的基准线
        _line = [[UIImageView alloc] initWithFrame:CGRectMake((MAIN_SCREEN_WIDTH - 300) / 2.0, line_MinY, 300, 12 * 300 / 320.0)];
        [_line setImage:[UIImage imageNamed:@"ff_QRCodeScanLine"]];
        [self addSubview:_line];
        
        //最上部view
        UIView * topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, line_MinY)];//80
        topView.alpha = 0.3;
        topView.backgroundColor = [UIColor blackColor];
        [self addSubview:topView];
        
        //左侧的view
        UIView * leftView = [[UIView alloc] initWithFrame:CGRectMake(0, line_MinY, (MAIN_SCREEN_WIDTH - viewWidth) / 2.0, viewHeight)];
        leftView.alpha = 0.3;
        leftView.backgroundColor = [UIColor blackColor];
        [self addSubview:leftView];
        
        //右侧的view
        UIView * rightView = [[UIView alloc] initWithFrame:CGRectMake(MAIN_SCREEN_WIDTH - CGRectGetMaxX(leftView.frame), line_MinY, CGRectGetMaxX(leftView.frame), viewHeight)];
        rightView.alpha = 0.3;
        rightView.backgroundColor = [UIColor blackColor];
        [self addSubview:rightView];
        
        CGFloat bottomHeight = MAIN_SCREEN_HEIGHT - line_MaxY;
        
        //底部view
        UIView * bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, line_MaxY, MAIN_SCREEN_WIDTH, bottomHeight)];
        bottomView.alpha = 0.3;
        bottomView.backgroundColor = [UIColor blackColor];
        [self addSubview:bottomView];
        
        //四个边角
        UIImage * currentImage = [UIImage imageNamed:@"ScanQR1"];
        
        //左侧的view
        UIImageView * leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - currentImage.size.width / 2.0, CGRectGetMaxY(topView.frame) - currentImage.size.height / 2.0, currentImage.size.width, currentImage.size.height)];
        leftImageView.image = currentImage;
        [self addSubview:leftImageView];
        
        currentImage = [UIImage imageNamed:@"ScanQR2"];
        
        //右侧的view
        UIImageView * rightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rightView.frame) - currentImage.size.width / 2.0, CGRectGetMaxY(topView.frame) - currentImage.size.height / 2.0, currentImage.size.width, currentImage.size.height)];
        rightImageView.image = currentImage;
        [self addSubview: rightImageView];
        currentImage = [UIImage imageNamed:@"ScanQR3"];
        
        //底部view
        UIImageView * bottomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - currentImage.size.width / 2.0, CGRectGetMinY(bottomView.frame) - currentImage.size.height / 2.0, currentImage.size.width, currentImage.size.height)];
        bottomImageView.image = currentImage;
        [self addSubview:bottomImageView];
        
        currentImage = [UIImage imageNamed:@"ScanQR4"];
        
        UIImageView * bottomRightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rightView.frame) - currentImage.size.width / 2.0, CGRectGetMinY(bottomView.frame) - currentImage.size.height / 2.0, currentImage.size.width, currentImage.size.height)];
        bottomRightImageView.image = currentImage;
        [self addSubview:bottomRightImageView];
        
        //说明label
        UILabel * alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame), CGRectGetMinY(bottomView.frame) + 25, viewWidth, 20)];
        alertLabel.backgroundColor = [UIColor clearColor];
        alertLabel.textAlignment = NSTextAlignmentCenter;
        alertLabel.font = [UIFont systemFontOfSize:13.0f];
        alertLabel.textColor = [UIColor whiteColor];
        alertLabel.text = @"将二维码置于框内,即可自动扫描";
        alertLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:alertLabel];
        
        UIView * scanCropView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) - 1,line_MinY,self.frame.size.width - 2 * CGRectGetMaxX(leftView.frame) + 2, viewHeight + 2)];
        scanCropView.layer.borderColor = [UIColor greenColor].CGColor;
        scanCropView.layer.borderWidth = 2.0;
        [self addSubview:scanCropView];
        
        _flag = YES;
    }
    return self;
}

- (void)startToScan
{
    _timeMachine = [NSTimer scheduledTimerWithTimeInterval:HF_TimeInterval target:self selector:@selector(startScanningTheAnimation) userInfo:nil repeats:YES];
}

- (void)startScanningTheAnimation
{
    __block CGRect frame = _line.frame;
    
    if (_flag) {
        frame.origin.y = line_MinY;
        _flag = NO;
        [UIView animateWithDuration:HF_TimeInterval animations:^{
            frame.origin.y += 5;
            _line.frame = frame;
        }];
    } else {
        if (_line.frame.origin.y >= line_MinY) {
            if (_line.frame.origin.y >= line_MaxY - 12) {
                frame.origin.y = line_MinY;
                _line.frame = frame;
                
                _flag = YES;
            } else {
                [UIView animateWithDuration:HF_TimeInterval animations:^{
                    frame.origin.y += 5;
                    _line.frame = frame;
                }];
            }
        } else {
            _flag = !_flag;
        }
    }
}

@end
