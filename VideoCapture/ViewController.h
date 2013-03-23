//
//  ViewController.h
//  VideoCapture
//
//  Created by wilson.lei on 3/8/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraCaptureOperation.h"
#import <GameKit/GameKit.h>

@interface ViewController : UIViewController <GKPeerPickerControllerDelegate, GKSessionDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate>

@property(nonatomic, strong) NSDate *timingDate;
@end
