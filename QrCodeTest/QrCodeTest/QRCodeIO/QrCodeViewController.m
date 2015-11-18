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
@property (nonatomic, copy) hf_ScanQrcodeBlock qrScanResultBlock;

@end

@implementation QrCodeViewController

- (void)dealloc
{
    [self backAndRemove];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"二维码扫描";
    [self initUserInterface];
    [self createQRcodeScanAction];
    [self startReadingQRCode];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startReadingQRCode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopReadingQRCode];
}

- (void)backAndRemove
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

- (QrCodeView *)codeView
{
    if (!_codeView) {
        _codeView = [[QrCodeView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    }
    return _codeView;
}

- (void)initUserInterface
{
    [self.view addSubview:self.codeView];
}

- (CGRect)getReaderViewBoundsWithSize:(CGSize)size
{
    return CGRectMake(lineMinY / MAIN_SCREEN_HEIGHT, ((MAIN_SCREEN_WIDTH - size.width) / 2.0) / MAIN_SCREEN_WIDTH, size.height / MAIN_SCREEN_HEIGHT, size.width / MAIN_SCREEN_WIDTH);
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

#pragma mark -- <AVCaptureMetadataOutputObjectsDelegate>
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //扫描结果
    __weak typeof(self) weakSelf = self;
    if (metadataObjects.count > 0) {
        [self stopReadingQRCode];
        
        AVMetadataMachineReadableCodeObject * obj = metadataObjects[0];
        
        if (obj.stringValue && ![obj.stringValue isEqualToString:@""] && obj.stringValue.length > 0) {
            NSLog(@"%@",obj.stringValue);
            
            if ([obj.stringValue containsString:@"http:"]) {
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

- (void)scanQrcodeWithResultBlock:(hf_ScanQrcodeBlock)resultBlock
{
    self.qrScanResultBlock = resultBlock;
}

#pragma mark -- 交互事件

- (void)startReadingQRCode
{
    if (_codeView.timeMachine) {
        [_codeView.timeMachine invalidate];
        _codeView.timeMachine = nil;
    }
    [_codeView startToScan];
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
