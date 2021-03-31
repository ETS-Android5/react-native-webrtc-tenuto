
#import <Foundation/Foundation.h>
#import <WebRTC/RTCCameraVideoCapturer.h>

#import "CaptureController.h"

/* CIFilter Type */
static NSString *const None = @"None";
static NSString *const CIColorInvert = @"CIColorInvert";
static NSString *const CIComicEffect = @"CIComicEffect";
static NSString *const CISepiaTone = @"CISepiaTone";
static NSString *const CIEdgeWork = @"CIEdgeWork";

@interface VideoCaptureController : CaptureController<RTCVideoCapturerDelegate>

-(instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                 andConstraints:(NSDictionary *)constraints;
-(void)startCapture;
-(void)stopCapture;
-(void)switchCamera;
-(void)setFilter:(NSString*) filter;

@end
