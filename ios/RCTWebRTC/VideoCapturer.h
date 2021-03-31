//
//  VideoCapturer.h
//  RCTWebRTC
//
//  Created by 홍은지(Eunji Hong) on 2021/03/31.
//

#import <Foundation/Foundation.h>

#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import <WebRTC/RTCVideoSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoCapturer : RTCCameraVideoCapturer

@property (nonatomic, strong) RTCVideoSource *videoSource;

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
