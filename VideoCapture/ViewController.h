//
//  ViewController.h
//  VideoCapture
//
//  Created by wilson.lei on 3/8/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <GKPeerPickerControllerDelegate, GKSessionDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKGameCenterControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (retain, nonatomic) IBOutlet UIButton *connectBtn;
@property (nonatomic, retain) IBOutlet UIImageView *aImageView;
@property (retain, nonatomic) IBOutlet UIButton *closeSharingBtn;
@property (retain, nonatomic) IBOutlet UIView *videosView;
@property (retain, nonatomic) IBOutlet UIView *videoPreviewView;

@end
