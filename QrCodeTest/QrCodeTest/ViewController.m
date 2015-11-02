//
//  ViewController.m
//  QrCodeTest
//
//  Created by Hayware on 15/10/27.
//  Copyright © 2015年 HayFi. All rights reserved.
//

#import "ViewController.h"
#import "QrCodeViewController.h"
#import "UIImage+QRCodeGenerator.h"

@interface ViewController ()

@property(nonatomic, strong) UIImageView * qrImageView;
@property(nonatomic, strong) UILabel * label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithTitle:@"showIt" style:UIBarButtonItemStylePlain target:self action:@selector(pushQrVC)];
    self.navigationItem.rightBarButtonItem = rightItem;
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.qrImageView];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 200)];
    _label.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.qrImageView.frame) + 40);
    _label.numberOfLines = 0;
    _label.textColor = [UIColor redColor];
    _label.text = @"进入扫描二维码";
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
}

- (UIImageView *)qrImageView
{
    if (!_qrImageView) {
        _qrImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        _qrImageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds) - 20);
        _qrImageView.backgroundColor = [UIColor whiteColor];
        _qrImageView.layer.borderWidth = 1;
        _qrImageView.layer.borderColor = [UIColor grayColor].CGColor;
    }
    return _qrImageView;
}

- (void)pushQrVC
{
    QrCodeViewController * qrVC = [[QrCodeViewController alloc] init];
    [self presentViewController:qrVC animated:YES completion:nil];
    __weak typeof(self) weakSelf = self;
    [qrVC scanQrcodeWithResultBlock:^(QrCodeViewController *qrVC, NSString *resultMessage) {
        if ([resultMessage isEqualToString:FailMessageFlag] || [resultMessage isEqualToString:CancelMessageFlag]) {
            [qrVC dismissViewControllerAnimated:YES completion:nil];
        } else {
            weakSelf.label.text = resultMessage;
            weakSelf.qrImageView.image = [UIImage qrImageForString:resultMessage imageSize:weakSelf.qrImageView.bounds.size.width];
            [qrVC dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end