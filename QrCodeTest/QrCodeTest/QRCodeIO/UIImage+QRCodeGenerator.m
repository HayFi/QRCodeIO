//
//  UIImage+QRCodeGenerator.m
//  QrCodeTest
//
//  Created by Hayware on 15/11/2.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import "UIImage+QRCodeGenerator.h"
#import "qrencode.h"

enum {
    qr_margin = 3
};

@implementation UIImage (QRCodeGenerator)

+ (void)drawQRCode:(QRcode *)code context:(CGContextRef)ctx size:(CGFloat)size
{
    unsigned char * data = 0;
    int width;
    data = code -> data;
    width = code -> width;
    float zoom = (double)size / (code->width + 2.0 * qr_margin);
    CGRect rectDraw = CGRectMake(0, 0, zoom, zoom);
    
    // draw
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor blackColor].CGColor));
    for(int i = 0; i < width; ++i) {
        for(int j = 0; j < width; ++j) {
            if(*data & 1) {
                rectDraw.origin = CGPointMake((j + qr_margin) * zoom,(i + qr_margin) * zoom);
                CGContextAddRect(ctx, rectDraw);
            }
            ++ data;
        }
    }
    CGContextFillPath(ctx);
}

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size
{
    if (![string length]) {
        return nil;
    }
    
    QRcode * code = QRcode_encodeString([string UTF8String], 0, QR_ECLEVEL_Q, QR_MODE_8, 1);
    if (!code) {
        return nil;
    }
    
    // create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(0, size, size, 8, size * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -size);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
    CGContextConcatCTM(context, CGAffineTransformConcat(translateTransform, scaleTransform));
    
    // draw QR on this context
    [UIImage drawQRCode:code context:context size:size];
    
    // get image
    CGImageRef qrCGImage = CGBitmapContextCreateImage(context);
    UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    
    // some releases
    CGContextRelease(context);
    CGImageRelease(qrCGImage);
    CGColorSpaceRelease(colorSpace);
    QRcode_free(code);
    
    return qrImage;
}

+ (UIImage *)qrImageForString:(NSString *)string imageWidth:(CGFloat)imageWidth topImage:(UIImage *)topImage
{
    if (![string length]) {
        return nil;
    }
    
    QRcode * code = QRcode_encodeString([string UTF8String], 0, QR_ECLEVEL_Q, QR_MODE_8, 1);
    if (!code) {
        return nil;
    }
    
    // create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(0, imageWidth, imageWidth, 8, imageWidth * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -imageWidth);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
    CGContextConcatCTM(context, CGAffineTransformConcat(translateTransform, scaleTransform));
    
    // draw QR on this context
    [UIImage drawQRCode:code context:context size:imageWidth];
    
    // get image
    CGImageRef qrCGImage = CGBitmapContextCreateImage(context);
    UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    
    // some releases
    CGContextRelease(context);
    CGImageRelease(qrCGImage);
    CGColorSpaceRelease(colorSpace);
    QRcode_free(code);
    
    UIImage * img = [UIImage createRoundedRectImage:topImage size:CGSizeMake(imageWidth, imageWidth) radius:20];
    
    UIGraphicsBeginImageContext(qrImage.size);
    [qrImage drawInRect:CGRectMake(0, 0, qrImage.size.width, qrImage.size.height)];
    CGFloat width = qrImage.size.width / 4;
    CGFloat x = width + width / 2;
    [img drawInRect:CGRectMake(x, x, width, width)];
    UIImage * fusionImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return fusionImage;
}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float kWidth, kHeight;
    
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    kWidth = CGRectGetWidth(rect) / ovalWidth;
    kHeight = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, kWidth, kHeight / 2);  // Start at lower right corner
    CGContextAddArcToPoint(context, kWidth, kHeight, kWidth / 2, kHeight, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, kHeight, 0, kHeight / 2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, kWidth / 2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, kWidth, 0, kWidth, kHeight / 2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size radius:(NSInteger)radius
{
    // the size of CGContextRef
    NSInteger width = size.width;
    NSInteger height = size.height;
    
    UIImage * img = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, radius * 2, radius * 2);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), img.CGImage);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    img = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return img;
}

@end
