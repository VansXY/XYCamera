# XYCamera
AVFoundation框架搭建自定义相机

基本知识：

- AVCaptureDevice 是关于相机硬件的接口。它被用于控制硬件特性，诸如镜头的位置、曝光、闪光灯等。
- AVCaptureDeviceInput 提供来自设备的数据。
- AVCaptureOutput 是一个抽象类，描述 capture session 的结果。以下是三种关于静态图片捕捉的具体子类：
  - AVCaptureStillImageOutput 用于捕捉静态图片
  - AVCaptureMetadataOutput 启用检测人脸和二维码
  - AVCaptureVideoOutput 为实时预览图提供原始帧
- AVCaptureSession 管理输入与输出之间的数据流，以及在出现问题时生成运行时错误。
- AVCaptureVideoPreviewLayer 是 CALayer 的子类，可被用于自动显示相机产生的实时图像。它还有几个工具性质的方法，可将 layer 上的坐标转化到设备上。它看起来像输出，但其实不是。另外，它拥有 session (outputs 被 session 所拥有)。

功能：

- 可以自己自定义相机的参数（焦距、ISO、快门时间、白平衡、光学防抖）
- 记录拍摄照片的元数据和位置信息
- 添加水印
