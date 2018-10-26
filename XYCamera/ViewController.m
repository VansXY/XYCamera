//
//  ViewController.m
//  XYCamera
//
//  Created by 肖扬 on 2018/10/26.
//  Copyright © 2018 Vickate. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import "UIView+Add.h"

static NSString *const photoLibraryTitle = @"Vickate";

/*
 自定义相机有两种：
 1. 使用系统自带相机
 2. 使用AVFoundation框架制作相机
 */

/*
 准备知识：
 
 AVCaptureDevice 是关于相机硬件的接口。它被用于控制硬件特性，诸如镜头的位置、曝光、闪光灯等。
 AVCaptureDeviceInput 提供来自设备的数据。
 AVCaptureOutput 是一个抽象类，描述 capture session 的结果。以下是三种关于静态图片捕捉的具体子类：
 AVCaptureStillImageOutput 用于捕捉静态图片
 AVCaptureMetadataOutput 启用检测人脸和二维码
 AVCaptureVideoOutput 为实时预览图提供原始帧
 AVCaptureSession 管理输入与输出之间的数据流，以及在出现问题时生成运行时错误。
 AVCaptureVideoPreviewLayer 是 CALayer 的子类，可被用于自动显示相机产生的实时图像。它还有几个工具性质的方法，可将 layer 上的坐标转化到设备上。它看起来像输出，但其实不是。另外，它拥有 session (outputs 被 session 所拥有)。
 */

@interface ViewController ()<AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate> {
    /// 导航高度
    CGFloat statusBarHeight;
    /// 底部高度
    CGFloat bottomBarHeight;
}

/*******拍摄硬件*********/
/// AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *session;
/// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
/// 照片输出流
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
/// 照片输出流设置
@property (nonatomic, strong) AVCapturePhotoSettings *photoOutputSettings;
/// 预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/// 设备
@property (nonatomic, strong) AVCaptureDevice *device;

/*******底部视图*********/
/// 拍照按钮
@property (nonatomic, strong) UIButton *takePhotoButton;
/// 地理位置
@property (nonatomic, strong) UILabel *addressLabel;
/// 对焦视图
@property (nonatomic, strong) UIView *focusView;
/// 拍摄的照片
@property (nonatomic, strong) UIImageView *photoImageView;

/*******顶部视图*********/
/// 顶部视图
@property (nonatomic, strong) UIView *statusBarView;
/// 切换镜头的按钮
@property (nonatomic, strong) UIButton *switchButton;
/// 切换闪光灯按钮
@property (nonatomic, strong) UIButton *flashButton;
/// 更多按钮，点击弹出功能视图
@property (nonatomic, strong) UIButton *moreButton;

/*******功能视图*********/
/// 功能视图
@property (nonatomic, strong) UIView *configView;
/// iso
@property (nonatomic, strong) UIImageView *isoImage;
/// 白平衡
@property (nonatomic, strong) UIImageView *webImage;
/// 快门时间
@property (nonatomic, strong) UIImageView *shutterspeedImage;
/// 焦距
@property (nonatomic, strong) UIImageView *focusImage;


/*******获取地理位置*********/
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLGeocoder *geocoder;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self startLocation];
    [self initCaptureSession];
    [self setUI];
    [self setStatusBar];
    [self setConfigView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)setUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    BOOL isiPhoneX = (Height == 812) ? YES : NO;
    statusBarHeight = isiPhoneX ? 44 : 20;
    bottomBarHeight = isiPhoneX ? 34 : 0;
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = CGRectMake(0, statusBarHeight, Width, Height - statusBarHeight - bottomBarHeight - 70);
    self.previewLayer.cornerRadius = 5;
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    self.takePhotoButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.takePhotoButton.frame = CGRectMake(Width / 2 - 30, Height - bottomBarHeight - 65, 60, 60);
    [self.takePhotoButton setBackgroundImage:[UIImage imageNamed:@"photo"] forState:(UIControlStateNormal)];
    [self.takePhotoButton addTarget:self action:@selector(takePhoto:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:self.takePhotoButton];
    
    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(Width - 100, Height - 60, 90, 50)];
    self.addressLabel.centerY = self.takePhotoButton.centerY;
    self.addressLabel.text = @"获取位置...";
    self.addressLabel.textColor = [UIColor whiteColor];
    self.addressLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.addressLabel];
    
    self.photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
    self.photoImageView.backgroundColor = [UIColor whiteColor];
    self.photoImageView.centerY = self.takePhotoButton.centerY;
    self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.photoImageView];
    
    _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    _focusView.layer.borderWidth = 1.0;
    _focusView.layer.borderColor =[UIColor orangeColor].CGColor;
    _focusView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_focusView];
    _focusView.hidden = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)setStatusBar {
    self.statusBarView = [[UIView alloc] initWithFrame:CGRectMake(Width - 35, statusBarHeight, 25, 200)];
    self.statusBarView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.statusBarView];
    
    self.switchButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.switchButton.frame = CGRectMake(0, 7.5, 25, 25);
    [self.switchButton setBackgroundImage:[UIImage imageNamed:@"后"] forState:(UIControlStateNormal)];
    [self.switchButton setBackgroundImage:[UIImage imageNamed:@"前"] forState:(UIControlStateSelected)];
    [self.switchButton addTarget:self action:@selector(swithButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.statusBarView addSubview:self.switchButton];
    
    self.flashButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.flashButton.frame = CGRectMake(0, 57.5, 25, 25);
    [self.flashButton setBackgroundImage:[UIImage imageNamed:@"闪光灯开"] forState:(UIControlStateNormal)];
    [self.flashButton setBackgroundImage:[UIImage imageNamed:@"闪光灯关"] forState:(UIControlStateSelected)];
    [self.flashButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.statusBarView addSubview:self.flashButton];
    
    self.moreButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.moreButton.frame = CGRectMake(0, 107.5, 25, 25);
    self.moreButton.selected = NO;
    [self.moreButton setBackgroundImage:[UIImage imageNamed:@"更多"] forState:(UIControlStateNormal)];
    [self.moreButton addTarget:self action:@selector(moreButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.statusBarView addSubview:self.moreButton];
}

- (void)setConfigView {
    self.configView = [[UIView alloc] initWithFrame:CGRectMake(0, Height - 200 - bottomBarHeight - 70, Width, 200)];
    self.configView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:self.configView];
    
    [self.view bringSubviewToFront:self.configView];
    
    self.focusImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 12.5, 25, 25)];
    self.focusImage.image = [UIImage imageNamed:@"焦距调节"];
    self.focusImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.configView addSubview:self.focusImage];
    
    self.isoImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 62.5, 25, 25)];
    self.isoImage.image = [UIImage imageNamed:@"iso"];
    self.isoImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.configView addSubview:self.isoImage];
    
    self.shutterspeedImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 112.5, 25, 25)];
    self.shutterspeedImage.image = [UIImage imageNamed:@"快门"];
    self.shutterspeedImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.configView addSubview:self.shutterspeedImage];
    
    self.webImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 162.5, 25, 25)];
    self.webImage.image = [UIImage imageNamed:@"黑白平衡"];
    self.webImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.configView addSubview:self.webImage];
    
    self.configView.hidden = YES;
}

- (void)initCaptureSession {
    self.session = [[AVCaptureSession alloc] init];
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_device error:&error];
    if (error) NSLog(@"%@", error);
    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    [self setImageModeWithtype:AVVideoCodecTypeJPEG];
    
    [self setFlashModeWithMode:(AVCaptureTorchModeAuto)];
    
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    if ([self.session canAddOutput:self.photoOutput]) {
        [self.session addOutput:self.photoOutput];
    }
}

- (void)takePhoto:(UIButton *)sender {
    AVCaptureConnection *connection = [self.photoOutput connectionWithMediaType:(AVMediaTypeVideo)];
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self getVideoOrientationWithDeviceOrientation:orientation];
    [connection setVideoOrientation:avcaptureOrientation];
    [connection setVideoScaleAndCropFactor:1];
    self.photoOutputSettings = nil;
    [self setImageModeWithtype:(AVVideoCodecTypeJPEG)];
    [self.photoOutput capturePhotoWithSettings:self.photoOutputSettings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) return;
    /// 保存图片
    NSData *jpegData = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:jpegData];
    UIImageWriteToSavedPhotosAlbum(image, self,  @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    self.photoImageView.image = image;
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    NSString *msg = nil ;
    if (error != NULL) {
        msg = @"保存图片失败" ;
    }
}

/// 将元数据写入照片
- (void)writeExifToPhotoWithDictionary:(NSDictionary *)dictionary {
    
}

/// 获取照片的元数据
- (NSDictionary *)readExifWithImage:(UIImage *)image {
    NSDictionary *diction = [[NSDictionary alloc] init];
    return diction;
}

/// 获取指定名称的相册
- (PHAssetCollection *)createCustomAlbum {
    /// 首先判断当前的相册是否已经创建
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *assetCollection in result) {
        if ([assetCollection.localizedTitle isEqualToString:photoLibraryTitle]) {
            return assetCollection;
        }
    }
    /// 没有该相册，去创建一个相册
    NSError *error;
    /// PHAssetCollection的标识, 利用这个标识可以找到对应的PHAssetCollection对象(相簿对象)
    __block NSString *assetCollectionLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        /// 创建相簿的请求
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:photoLibraryTitle].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    /// 如果有错误信息
    if (error) return nil;
    
    /// 获得刚才创建的相簿
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject;
}

/// 设置拍摄照片的格式
- (void)setImageModeWithtype:(AVVideoCodecType)type {
    if (!type.length) type = AVVideoCodecTypeJPEG;
    NSDictionary *setDic = @{AVVideoCodecKey:type};
    self.photoOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    /// 根据环境自动设置闪光灯
    [self.photoOutputSettings setFlashMode:(AVCaptureFlashModeAuto)];
    [self.photoOutput setPhotoSettingsForSceneMonitoring:self.photoOutputSettings];
}

#pragma mark - 打开功能视图
- (void)moreButtonClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.configView.hidden = !sender.selected;
}

#pragma mark - 切换摄像头
- (void)swithButtonClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self cameraBackgroundDidClickChangeFront];
    } else {
        [self cameraBackgroundDidClickChangeBack];
    }
}

/// 切换后置摄像头
- (void)cameraBackgroundDidClickChangeBack {
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionBack;
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    AVCaptureDeviceInput *toChangeDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:toChangeDevice error:nil];
    [self.session beginConfiguration];
    [self.session removeInput:self.deviceInput];
    if ([self.session canAddInput:toChangeDeviceInput]) {
        [self.session addInput:toChangeDeviceInput];
        self.deviceInput = toChangeDeviceInput;
    }
    [self.session commitConfiguration];
}

/// 切换前置摄像头
- (void)cameraBackgroundDidClickChangeFront {
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    AVCaptureDeviceInput *toChangeDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:toChangeDevice error:nil];
    [self.session beginConfiguration];
    [self.session removeInput:self.deviceInput];
    if ([self.session canAddInput:toChangeDeviceInput]) {
        [self.session addInput:toChangeDeviceInput];
        self.deviceInput = toChangeDeviceInput;
    }
    [self.session commitConfiguration];
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPresetPhoto])
                return device;
            return nil;
        }
    }
    return nil;
}

#pragma mark - 闪光灯
- (void)flashButtonClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self closeFlashMode];
    } else {
        [self startFlashMode];
    }
}

/// 打开闪光灯
- (void)startFlashMode {
    [self setFlashModeWithMode:(AVCaptureTorchModeOn)];
}

/// 关闭闪光灯
- (void)closeFlashMode {
    [self setFlashModeWithMode:(AVCaptureTorchModeOff)];
}

- (void)setFlashModeWithMode:(AVCaptureTorchMode)mode {
    NSError *error;
    [_device lockForConfiguration:&error];
    _device.torchMode = mode;
    [_device unlockForConfiguration];
}

#pragma mark - 变焦
/// 数码变焦 1-3倍
- (void)cameraBackgroundDidChangeZoomWithProgress:(CGFloat)progress {
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        [self.device rampToVideoZoomFactor:progress withRate:50];
    }
}
#pragma mark - 焦距

#pragma mark - ISO

#pragma mark - 快门时间
//手动模式下的设置曝光时间
- (void)setSpeedWithProgress:(CGFloat)progress {
    //    UISlider *control = sender;
    //    NSError *error;
    //
    //    double p = pow(control.value, kExposureDurationPower );
    //    double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
    //    double maxDurationSeconds = CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
    //    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds;
    //
    //    if ([self.videoDevice lockForConfiguration:&;error]) {
    //        [self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(newDurationSeconds, 1000*1000*1000) ISO:AVCaptureISOCurrent completionHandler:nil];
    //        [self.videoDevice unlockForConfiguration];
    //    } else {
    //        NSLog( @"Could not lock device for configuration: %@", error );
    //    }
}

#pragma mark - 白平衡

#pragma mark - 光学防抖
/// 打开光学防抖
- (void)startStabilization {
    AVCaptureConnection *videoConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([_device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    }
}

/// 关闭光学防抖
- (void)closeStabilization {
    AVCaptureConnection *videoConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([_device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    }
}

/// 获取设备方向
- (AVCaptureVideoOrientation)getVideoOrientationWithDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}

/// 点击聚焦
- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    /// 拿到点击点
    CGPoint point = [gesture locationInView:gesture.view];
    /// 设置聚焦
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    /// 点击除了上下黑色导航栏以内的才会聚焦
    if (point.y < 20 || point.y > Height - 70) {
        return;
    }
    /// 找到聚焦位置(注意该point是在屏幕的比例位置)
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        /// 对焦模式和对焦点
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        /// 曝光模式和曝光点
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        [self.device unlockForConfiguration];
        
        /// 设置对焦动画
        _focusView.center = point;
        _focusView.hidden = NO;
        
        /// 设置聚焦动画
        [UIView animateWithDuration:0.3 animations:^{
            /// 先放大1.25倍
            self.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                /// 再返回原来的尺寸
                self.focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.focusView.alpha = 0.3;
            }];
        }];
    }
}

/// 隐藏导航栏
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - 获取地理位置
- (void)startLocation {
    /// 初始化定位管理器
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager requestAlwaysAuthorization];
    [_locationManager requestWhenInUseAuthorization];
    /// 设置代理
    _locationManager.delegate = self;
    /// 设置定位精确度到米
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    /// 设置过滤器为无
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    /// 开始定位
    [_locationManager startUpdatingLocation];//开始定位之后会不断的执行代理方法更新位置会比较费电所以建议获取完位置即时关闭更新位置服务
    /// 初始化地理编码器
    _geocoder = [[CLGeocoder alloc] init];
}

@end
