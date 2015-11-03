//
//  QrCodeViewController.m
//  QrCodeTest
//
//  Created by Hayware on 15/10/27.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import "QrCodeViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "QrCodeView.h"

#define MAIN_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define MAIN_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define MAIN_SCREEN_BOUNDS [UIScreen mainScreen].bounds

static const float lineMinY = 185;
static const float viewWidth = 200;
static const float viewHeight = 200;


@interface QrCodeViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession * qrSession;//回话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * qrVideoPreviewLayer;//读取
@property (nonatomic, strong) QrCodeView * codeView;
@property (nonatomic, copy) void (^qrScanResultBlock) (QrCodeViewController *,NSString *);

@end

@implementation QrCodeViewController

- (void)dealloc
{
    if (_qrSession) {
        [_qrSession stopRunning];
        _qrSession = nil;
    }
    
    if (_qrVideoPreviewLayer) {
        _qrVideoPreviewLayer = nil;
    }
    
    if (_codeView.timeMachine) {
        [_codeView.timeMachine invalidate];
        _codeView.timeMachine = nil;
    }
    
    if (_codeView) {
        [_codeView removeFromSuperview];
        _codeView = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
   
    [self createQRcodeScanAction];
    [self startReadingQRCode];
    [self initUserInterface];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initUserInterface
{
    [self.view addSubview:self.codeView];
    
    UIView * bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, 64)];
    bgView.backgroundColor = [UIColor colorWithRed:21.0/255.0 green:156.0/255.0 blue:115.0/255.0 alpha:1.0];
    [self.view addSubview:bgView];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((MAIN_SCREEN_WIDTH - 120) / 2.0, 30, 120, 20)];
    titleLabel.text = @"二维码扫描";
    titleLabel.font = [UIFont systemFontOfSize:18.0];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(16, 28, 21, 22);
    [btn setContentMode:UIViewContentModeScaleAspectFit];
    [btn setImage:[UIImage imageNamed:@"darkReturn"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(cancelReadingQRCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}


- (void)createQRcodeScanAction
{
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError * error = nil;
    
    AVCaptureDeviceInput * deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"没有摄像头-%@", error.localizedDescription);
        return;
    }
    
    //设置输出
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [output setRectOfInterest:[self getReaderViewBoundsWithSize:CGSizeMake(viewWidth, viewHeight)]];
    
    //拍摄会话
    self.qrSession = [[AVCaptureSession alloc] init];
    
    // 读取质量，质量越高，可读取小尺寸的二维码
    if ([self.qrSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
        [self.qrSession setSessionPreset:AVCaptureSessionPreset1920x1080];
    } else if ([self.qrSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        [self.qrSession setSessionPreset:AVCaptureSessionPreset1280x720];
    } else {
        [self.qrSession setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    if ([self.qrSession canAddInput:deviceInput]) {
        [self.qrSession addInput:deviceInput];
    }
    
    if ([self.qrSession canAddOutput:output]) {
        [self.qrSession addOutput:output];
    }
    
    //设置输出的格式，一定要先设置会话的输出为output之后，再指定输出的元数据类型
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    //设置预览图层
    self.qrVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.qrSession];
    //设置preview图层的属性
    [self.qrVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //设置preview图层的大小
    self.qrVideoPreviewLayer.frame = self.view.layer.bounds;
    //将图层添加到视图的图层
    [self.view.layer insertSublayer:self.qrVideoPreviewLayer atIndex:0];
}

- (CGRect)getReaderViewBoundsWithSize:(CGSize)size
{
    return CGRectMake(lineMinY / MAIN_SCREEN_HEIGHT, ((MAIN_SCREEN_WIDTH - size.width) / 2.0) / MAIN_SCREEN_WIDTH, size.height / MAIN_SCREEN_HEIGHT, size.width / MAIN_SCREEN_WIDTH);
}

- (QrCodeView *)codeView
{
    if (!_codeView) {
        _codeView = [[QrCodeView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    }
    return _codeView;
}

#pragma mark -- <AVCaptureMetadataOutputObjectsDelegate>
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //扫描结果
    __weak typeof(self) weakSelf = self;
    if (metadataObjects.count > 0) {
        [self stopReadingQRCode];
        
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
       
        if (obj.stringValue && ![obj.stringValue isEqualToString:@""] && obj.stringValue.length > 0) {
            NSLog(@"%@",obj.stringValue);
            
            if ([obj.stringValue containsString:@"http"]) {
                if (self.qrScanResultBlock) {
                    NSLog(@"success");
                    self.qrScanResultBlock(weakSelf,obj.stringValue);
                }
            } else {
                if (self.qrScanResultBlock) {
                    self.qrScanResultBlock(weakSelf,FailMessageFlag);
                }
            }
        } else {
            if (self.qrScanResultBlock) {
                self.qrScanResultBlock(weakSelf,FailMessageFlag);
            }
        }
    } else {
        if (self.qrScanResultBlock) {
            self.qrScanResultBlock(weakSelf,FailMessageFlag);
        }
    }
}

- (void)scanQrcodeWithResultBlock:(void (^)(QrCodeViewController *, NSString *))block
{
    self.qrScanResultBlock = block;
}

#pragma mark -- 交互事件

- (void)startReadingQRCode
{
    [self.qrSession startRunning];
    NSLog(@"startRunning");
}

- (void)stopReadingQRCode
{
    if (_codeView.timeMachine) {
        [_codeView.timeMachine invalidate];
        _codeView.timeMachine = nil;
    }
    [self.qrSession stopRunning];
    NSLog(@"stopRunning");
}

//取消扫描
- (void)cancelReadingQRCode
{
    [self stopReadingQRCode];
    
    if (self.qrScanResultBlock) {
        self.qrScanResultBlock(self, CancelMessageFlag);
    }
    NSLog(@"cancelRunning");
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
