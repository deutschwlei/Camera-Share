//
//  CameraCaptureOperation.h
//  VideoCapture2
//
//  Created by wilson.lei on 3/8/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraCaptureOperation : NSOperation <AVCaptureVideoDataOutputSampleBufferDelegate>

@end
