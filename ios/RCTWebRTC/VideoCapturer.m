//
//  VideoCapturer.m
//  RCTWebRTC
//
//  Created by 홍은지(Eunji Hong) on 2021/03/31.
//

#import "VideoCapturer.h"

#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>

#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCCVPixelBuffer.h>
#import <WebRTC/RTCVideoFrameBuffer.h>
#import <WebRTC/RTCVideoSource.h>

#import <React/RCTLog.h>


@implementation VideoCapturer

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate{
    RCTLog(@"video capturer init init init");
    self = [super initWithDelegate:delegate];
    self.videoSource = delegate;
    
    return self;
}

@end
