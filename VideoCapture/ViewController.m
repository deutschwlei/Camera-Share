//
//  ViewController.m
//  VideoCapture
//
//  Created by wilson.lei on 3/8/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    NSString *_gamePeerID;
    GKSession *_gameSession;
    
    GKMatch *_gameMatch;
    BOOL _isMatchStarted;
    GKLocalPlayer *_localPlayer;
    
    AVCaptureSession *_AVSession;
    __block BOOL _isSendData;
    __block UIImage *_frameImage;
    __block CIImage *_ciImage;
    __block CIContext *_ciContext;
  
    dispatch_queue_t _videoFrameProcessQueue;
}

@property(nonatomic, strong) NSDate *timingDate;

@end


@implementation ViewController

@synthesize timingDate = _timingDate;
@synthesize aImageView = _aImageView;

#pragma mark - Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _isSendData = YES;
    _isMatchStarted = NO;
    self.timingDate = [NSDate date];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showVideoFrame:) name:@"VideoFrameDidReceived" object:nil];
    
    //disable auto lock
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //_localPlayer = [GKlocalPlayer _localPlayer];
    //[self auth_localPlayer];

    
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onConnectTap:(id)sender
{

    //[self setupCaptureSession];
    [self startPicker];
}

#pragma mark - GameKit Peer Picker

-(void)startPicker
{
    GKPeerPickerController *picker;
    
    picker = [[[GKPeerPickerController alloc] init] autorelease];
    //picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby | GKPeerPickerConnectionTypeOnline;
    picker.delegate = self;
    [picker show];
}

-(void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker
{
    picker.delegate = nil;

}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type
{
	return [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
	// Remember the current peer.
	_gamePeerID = peerID;
	
	// Make sure we have a reference to the game session and it is set up
	_gameSession = session; // retain
	_gameSession.delegate = self;
	[_gameSession setDataReceiveHandler:self withContext:NULL];
	
    [self setupCaptureSession];
    
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
    
}

-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    int dataInKB = data.length/1024;
    NSLog(@"data length %d B = %d KB", data.length, dataInKB);
    
    if(data.length > 0){
        //check if I get a byte
        if(data.length < 10){
            NSLog(@"got a byte");
            _isSendData = YES;
        }
        else{
            //got an image
            NSLog(@"got image");
            NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:self.timingDate]);
            //send back 1 byte data
            NSData *aByte = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
            NSLog(@"send a byte");
            self.timingDate = [NSDate date];
            
            //send a received data acknowledgment to the other device
            [_gameSession sendData:aByte toPeers:[NSArray arrayWithObjects:_gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
            
            UIImage *aImage = [UIImage imageWithData:data];
            [_aImageView setImage:aImage];
            [_aImageView setHidden:NO];
        }
    }
}

#pragma mark - GKSessionDelegate
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{

}

-(void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error %@", error);
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    if(state == GKPeerStateDisconnected){
        [_aImageView setHidden:YES];
        [session disconnectFromAllPeers];
        [_AVSession stopRunning];
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    
}

#pragma mark - Video capture
- (void)setupCaptureSession
{
    
    // Create the session
    _AVSession = [[AVCaptureSession alloc] init];
    
    // Configure the session to produce lower resolution video frames
    _AVSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [_AVSession addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    [_AVSession addOutput:output];
    
    // Configure your output.
    dispatch_queue_t videoQueue = dispatch_queue_create("com.deutschinc.videoQueue", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:videoQueue];
    dispatch_release(videoQueue);
    
    _videoFrameProcessQueue = dispatch_queue_create("com.deutschinc._videoFrameProcessQueue", DISPATCH_QUEUE_SERIAL);
    
    // Specify the pixel format
    output.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Start the session running to start the flow of data
    [_AVSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if(_isSendData){
        _isSendData = NO;
        CFRetain(sampleBuffer);
        
        dispatch_async(_videoFrameProcessQueue, ^{
            // Get a CMSampleBuffer's Core Video image buffer for the media data
            CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            //get CoreImage from CVImage
            _ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            _ciContext = [CIContext contextWithOptions:nil];
            CGImageRef cgImageRef = [_ciContext createCGImage:_ciImage fromRect:_ciImage.extent];
            
            _frameImage = [UIImage imageWithCGImage:cgImageRef scale:1.0 orientation:UIImageOrientationRight];
            CGImageRelease(cgImageRef);
            

            //send image data to the other device
            [_gameSession sendData:UIImageJPEGRepresentation(_frameImage, 0.1) toPeers:[NSArray arrayWithObjects:_gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
            
            CFRelease(sampleBuffer);
        });
        
    }
    
}

#pragma mark - Game Center, GKMatchmakerViewControllerDelegate

- (void) auth_localPlayer{

    _localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil)
        {
            NSLog(@"User is not auth");
            [self showAuthenticationDialogWhenReasonable: viewController];
        }
        else if (_localPlayer.isAuthenticated)
        {
            [self authenticatedPlayer: _localPlayer];
        }
        else
        {
            NSLog(@"User auth failed");
            //[self disableGameCenter];
        }
        
    };
}

- (void) showAuthenticationDialogWhenReasonable:(UIViewController *) loginVC{
    [self.view addSubview:loginVC.view];
}

- (void) authenticatedPlayer:(GKLocalPlayer *) _localPlayer
{
    NSLog(@"User is authed");
}

- (void) showGameCenter
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    gameCenterController.gameCenterDelegate = self;
    [self presentViewController: gameCenterController animated: YES completion:nil];
}

-(void)setupMatch
{
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    
    
    GKMatchmaker *matchMaker = [GKMatchmaker sharedMatchmaker];
    [matchMaker startBrowsingForNearbyPlayersWithReachableHandler:^(NSString *playerID, BOOL reachable){
        if(reachable){
            NSLog(@"reachable");
        }
    }];
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    // Implement any specific code in your game here.
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    // Implement any specific code in your game here.
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [self dismissViewControllerAnimated:YES completion:nil];
    _gameMatch = match; // Use a retaining property to retain the match.
    match.delegate = self;
    if (!_isMatchStarted && match.expectedPlayerCount == 0)
    {
        _isMatchStarted = YES;
        NSLog(@"found player");
        // Insert game-specific code to start the match.
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    
}



#pragma mark - System
- (void)dealloc {
    [_connectBtn release];
    [_aImageView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setConnectBtn:nil];
    _aImageView = nil;
    [super viewDidUnload];
}
@end
