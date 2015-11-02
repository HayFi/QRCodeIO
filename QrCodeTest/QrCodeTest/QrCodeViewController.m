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

static const float kLineMinY = 185;
static const float kReaderViewWidth = 200;
static const float kReaderViewHeight = 200;


@interface QrCodeViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *qrSession;//回话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *qrVideoPreviewLayer;//读取
@property (nonatomic, strong) QrCodeView * codeView;
@property (nonatomic, strong) UIImageView *line;//交互线
@property (nonatomic, strong) NSTimer *lineTimer;//交互线控制
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
    
    if (_codeView.lineTimer) {
        [_codeView.lineTimer invalidate];
        _codeView.lineTimer = nil;
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
    
    self.navigationItem.title = @"二维码扫描";
   
    [self initUserInterface];
    
    [self setOverlayPickerView];
    [self startSYQRCodeReading];
    
    [self initTitleView];
    [self createBackBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initTitleView
{
    UIView * bgView = [[UIView alloc] initWithFrame:CGRectMake(0,0,MAIN_SCREEN_WIDTH, 64)];
    bgView.backgroundColor = [UIColor colorWithRed:62.0/255 green:199.0/255 blue:153.0/255 alpha:1.0];
    [self.view addSubview:bgView];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((MAIN_SCREEN_WIDTH - 120) / 2.0, 30, 120, 20)];
    titleLabel.text = @"二维码扫描";
    titleLabel.font = [UIFont systemFontOfSize:18.0];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
}

- (void)createBackBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(20, 28, 60, 24)];
    [btn setImage:[UIImage imageNamed:@"sgdtw"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(cancleSYQRCodeReading) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}


- (void)initUserInterface
{
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //摄像头判断
    NSError * error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"没有摄像头-%@", error.localizedDescription);
        return;
    }
    
    //设置输出(Metadata元数据)
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    
    //使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [output setRectOfInterest:[self getReaderViewBoundsWithSize:CGSizeMake(kReaderViewWidth, kReaderViewHeight)]];
    
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
    
    if ([self.qrSession canAddInput:input]) {
        [self.qrSession addInput:input];
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
    return CGRectMake(kLineMinY / MAIN_SCREEN_HEIGHT, ((MAIN_SCREEN_WIDTH - size.width) / 2.0) / MAIN_SCREEN_WIDTH, size.height / MAIN_SCREEN_HEIGHT, size.width / MAIN_SCREEN_WIDTH);
}

- (void)setOverlayPickerView
{
    [self.view addSubview:self.codeView];
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
        [self stopSYQRCodeReading];
        
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

#pragma mark 交互事件

- (void)startSYQRCodeReading
{
    [self.qrSession startRunning];
    
    NSLog(@"startRunning");
}

- (void)stopSYQRCodeReading
{
    if (_lineTimer) {
        [_lineTimer invalidate];
        _lineTimer = nil;
    }
    [self.qrSession stopRunning];
    NSLog(@"stopRunning");
}

//取消扫描
- (void)cancleSYQRCodeReading
{
    [self stopSYQRCodeReading];
    
    if (self.qrScanResultBlock) {
        self.qrScanResultBlock(self, CancelMessageFlag);
    }
    NSLog(@"cancelRunning");
}

@end
