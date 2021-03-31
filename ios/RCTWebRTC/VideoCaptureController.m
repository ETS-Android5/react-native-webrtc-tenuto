//
//  VideoCaptureController.m
//  RCTWebRTC
//
//  Created by 홍은지(Eunji Hong) on 2021/03/31.
//

#import "VideoCaptureController.h"
#import "VideoCapturer.h"

#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCCVPixelBuffer.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <WebRTC/RTCVideoSource.h>

#import <React/RCTLog.h>


@implementation VideoCaptureController {
    VideoCapturer *_capturer;
    NSString *_deviceId;
    NSString *_filter;
    BOOL _running;
    BOOL _usingFrontCamera;
    int _width;
    int _height;
    int _fps;
}

-(instancetype)initWithCapturer:(VideoCapturer *)capturer
                 andConstraints:(NSDictionary *)constraints {
    self = [super init];
    if (self) {
        _capturer = capturer;
        _running = NO;

        // Default to the front camera.
        _usingFrontCamera = YES;

        _deviceId = constraints[@"deviceId"];
        _width = [constraints[@"width"] intValue];
        _height = [constraints[@"height"] intValue];
        _fps = MIN([constraints[@"frameRate"] intValue], 30);
        
        _filter = None;

        id facingMode = constraints[@"facingMode"];

        if (facingMode && [facingMode isKindOfClass:[NSString class]]) {
            AVCaptureDevicePosition position;
            if ([facingMode isEqualToString:@"environment"]) {
                position = AVCaptureDevicePositionBack;
            } else if ([facingMode isEqualToString:@"user"]) {
                position = AVCaptureDevicePositionFront;
            } else {
                // If the specified facingMode value is not supported, fall back
                // to the front camera.
                position = AVCaptureDevicePositionFront;
            }

            _usingFrontCamera = position == AVCaptureDevicePositionFront;
        }
    }

    return self;
}

-(void)startCapture {
    AVCaptureDevice *device;

    if (_deviceId) {
        device = [AVCaptureDevice deviceWithUniqueID:_deviceId];
    }
    if (!device) {
        AVCaptureDevicePosition position
            = _usingFrontCamera
                ? AVCaptureDevicePositionFront
                : AVCaptureDevicePositionBack;
        device = [self findDeviceForPosition:position];
    }

    if (!device) {
        RCTLogWarn(@"[VideoCaptureController] No capture devices found!");

        return;
    }

    AVCaptureDeviceFormat *format
        = [self selectFormatForDevice:device
                      withTargetWidth:_width
                     withTargetHeight:_height];
    if (format == nil) {
        RCTLogWarn(@"[VideoCaptureController] No valid formats for device %@", device);

        return;
    }
    

    RCTLog(@"[VideoCaptureController] Capture will start");

    // Starting the capture happens on another thread. Wait for it.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [_capturer startCaptureWithDevice:device format:format fps:_fps completionHandler:^(NSError *err) {
        if (err) {
            RCTLogError(@"[VideoCaptureController] Error starting capture: %@", err);
        } else {
            RCTLog(@"[VideoCaptureController] Capture started");
            self->_running = YES;
        }
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

}

-(void)stopCapture {
    if (!_running)
        return;

    RCTLog(@"[VideoCaptureController] Capture will stop");
    // Stopping the capture happens on another thread. Wait for it.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [_capturer stopCaptureWithCompletionHandler:^{
        RCTLog(@"[VideoCaptureController] Capture stopped");
        self->_running = NO;
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

-(void)switchCamera {
    _usingFrontCamera = !_usingFrontCamera;
    _deviceId = NULL;

    [self startCapture];
}

-(void)setFilter:(NSString *)filter{
    _filter = filter;
}

- (UIImage *) applyCIFilter: (UIImage *)uIImage
{
    @autoreleasepool {
        CIContext *context = [CIContext contextWithOptions:nil];

        //  Convert UIImage to CIImage
        CIImage *ciImage = [[CIImage alloc] initWithImage:uIImage];

        //  Set values for CIColorMonochrome Filter
        CIFilter *filter = [CIFilter filterWithName:_filter];
        [filter setValue:ciImage forKey:kCIInputImageKey];

        CIImage *result = [filter valueForKey:kCIOutputImageKey];
        CGRect extent = [result extent];
        CGImageRef cgImage = [context createCGImage:result fromRect:extent];
        UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
        
        CGImageRelease(cgImage);

        return filteredImage;
    }
}

-(UIImage*)pixelBufferToUIImage:(CVPixelBufferRef) pixelBuffer{
    @autoreleasepool {
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                           createCGImage:ciImage
                           fromRect:CGRectMake(0, 0,
                                  CVPixelBufferGetWidth(pixelBuffer),
                                  CVPixelBufferGetHeight(pixelBuffer))];

        UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
        
        CGImageRelease(videoImage);
        
        return uiImage;
    }
}

- (void)capturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame{
    if(_filter == None){
        [_capturer.videoSource capturer:_capturer didCaptureVideoFrame:frame];
    } else {
        @autoreleasepool {
            RTCCVPixelBuffer *framebuffer = frame.buffer;         // RTCCVPixelBuffer
            CVPixelBufferRef pixelBuffer = framebuffer.pixelBuffer;
            
            UIImage *uiImage = [self pixelBufferToUIImage:pixelBuffer];

            UIImage *resizedImage = [self resizeImage:uiImage convertToSize: CGSizeMake(frame.width, frame.height)];
            UIImage *filteredImage = [self applyCIFilter: resizedImage];
            
            CIImage *inputImage = [CIImage imageWithCGImage:filteredImage.CGImage];
            CIContext *ciContext = [CIContext contextWithCGContext:UIGraphicsGetCurrentContext() options:nil];
            
            [ciContext render:inputImage toCVPixelBuffer: pixelBuffer];
            
            RTCCVPixelBuffer *rtcBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer: pixelBuffer];
            RTCVideoFrame *rtcFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcBuffer rotation: frame.rotation timeStampNs:frame.timeStampNs];
            
            [_capturer.videoSource capturer:_capturer didCaptureVideoFrame:rtcFrame];
        }
    }
}

#pragma mark Private

- (UIImage *)resizeImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }

    return [captureDevices firstObject];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device
                                 withTargetWidth:(int)targetWidth
                                withTargetHeight:(int)targetHeight{
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;

    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        FourCharCode pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        } else if (diff == currentDiff && pixelFormat == [_capturer preferredOutputPixelFormat]) {
            selectedFormat = format;
        }

    }

    return selectedFormat;
}



@end
