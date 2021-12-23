//
//  VideoCaptureController.h
//  RCTWebRTC
//
//  Created by 홍은지(Eunji Hong) on 2021/03/31.
//

#import <Foundation/Foundation.h>
#import <WebRTC/RTCCameraVideoCapturer.h>

#import "CaptureController.h"

/* CIFilter Type */
static NSString *const None = @"None";
// Tone Change
static NSString *const CISepiaTone = @"CISepiaTone";
static NSString *const CIPhotoEffectFade = @"CIPhotoEffectFade";
static NSString *const CIPhotoEffectInstant = @"CIPhotoEffectInstant";
static NSString *const CIPhotoEffectMono = @"CIPhotoEffectMono";
static NSString *const CIPhotoEffectNoir = @"CIPhotoEffectNoir";
static NSString *const CIPhotoEffectProcess = @"CIPhotoEffectProcess";
static NSString *const CIPhotoEffectTonal = @"CIPhotoEffectTonal";
// Various effect
static NSString *const CIBloom = @"CIBloom";
static NSString *const CIGloom = @"CIGloom";
static NSString *const CICrystallize = @"CICrystallize";
static NSString *const CIEdgeWork = @"CIEdgeWork";
static NSString *const CIComicEffect = @"CIComicEffect";
static NSString *const CIColorPosterize = @"CIColorPosterize";
static NSString *const CIColorInvert = @"CIColorInvert";

@class VideoCaptureController;
@protocol VideoCaptureFilterDelegate<NSObject>

- (void)videoCaptureController:(VideoCaptureController *)videoCaptureController
         filterVideoFrameImage:(UIImage *)image
                    completion:(void (^)(UIImage *image))completion;

@end

@interface VideoCaptureController : CaptureController<RTCVideoCapturerDelegate>

@property (class, nonatomic, weak) id <VideoCaptureFilterDelegate> filterDelegate;

-(instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                 andConstraints:(NSDictionary *)constraints;
-(void)startCapture;
-(void)stopCapture;
-(void)switchCamera;
-(void)setSystemFilter:(NSString*) filter;

@end
