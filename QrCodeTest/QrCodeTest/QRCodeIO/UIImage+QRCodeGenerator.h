//
//  UIImage+QRCodeGenerator.h
//  QrCodeTest
//
//  Created by Hayware on 15/11/2.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCodeGenerator)

//创建二维码图片
+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size;

//创建带圆角logo的二维码图片
+ (UIImage *)qrImageForString:(NSString *)string imageWidth:(CGFloat)imageWidth topImage:(UIImage *)topImage;

@end
