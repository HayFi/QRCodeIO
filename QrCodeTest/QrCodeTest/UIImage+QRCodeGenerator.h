//
//  UIImage+QRCodeGenerator.h
//  QrCodeTest
//
//  Created by Hayware on 15/11/2.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCodeGenerator)

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size;

@end
