//
//  ViewController.m
//  VideoCapture
//
//  Created by wilson.lei on 3/8/13.
//  Copyright (c) 2013 wilson.lei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSOperationQueue *opQueue;
    UIImageView *aImageView;
    NSString *gamePeerID;
    GKSession *gameSession;
    GKMatch *gameMatch;
    BOOL isSendData;
    BOOL isMatchStarted;
  
}
@end


@implementation ViewController

@synthesize timingDate;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    isSendData = true;
    isMatchStarted = false;
    self.timingDate = [NSDate date];
    opQueue = [[NSOperationQueue alloc] init];
    
    UIView *aView = [[UIView alloc]initWithFrame:self.view.bounds];
    [aView setBackgroundColor:[UIColor orangeColor]];
    aImageView = [[UIImageView alloc]initWithFrame:aView.frame];
    [aView addSubview:aImageView];
    self.view = aView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showVideoFrame:)
                                                 name:@"VideoFrameDidReceived"
                                               object:nil];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    /*
    CameraCaptureOperation *aCameraCaptureOp = [[CameraCaptureOperation alloc]init];
    [opQueue cancelAllOperations];
    [opQueue addOperation:aCameraCaptureOp];
    
     */
    [self startPicker];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    /*
    GKLocalPlayer *localplayer = [GKLocalPlayer localPlayer];

    [localplayer authenticateWithCompletionHandler:^(NSError *error) {
        if (error) {
            //DISABLE GAME CENTER FEATURES / SINGLEPLAYER
        }
        else {
            [self setupMatch];
            //ENABLE GAME CENTER FEATURES / MULTIPLAYER
        }
    }];
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)showVideoFrameMT:(NSNotification *)info{
    //NSLog(@"got image");
    NSDictionary *notifData = [info userInfo];
    UIImage *aImage = [notifData valueForKey:@"image"];
    
    /*
    NSDate *timingDate = [NSDate date];
    UIImageJPEGRepresentation(aImage, 0.1);
    NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:timingDate]);
    */
    
    [gameSession sendData:UIImageJPEGRepresentation(aImage, 0.1) toPeers:[NSArray arrayWithObjects:gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
    isSendData = false;
}


- (void)showVideoFrame:(NSNotification *)info{
    if(isSendData){
        NSLog(@"send image");
        [self performSelectorOnMainThread:@selector(showVideoFrameMT:) withObject:info waitUntilDone:NO];
    }
}

#pragma - Peer Picker

-(void)startPicker
{
    GKPeerPickerController *picker;
    
    picker = [[GKPeerPickerController alloc] init];
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

- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type
{
    if (type == GKPeerPickerConnectionTypeOnline) {
        picker.delegate = nil;
        [picker dismiss];
        [picker autorelease];
        // Implement your own internet user interface here.
    }
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
	// Remember the current peer.
	gamePeerID = peerID;
	
	// Make sure we have a reference to the game session and it is set up
	gameSession = session; // retain
	gameSession.delegate = self;
	[gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
    
    CameraCaptureOperation *aCameraCaptureOp = [[CameraCaptureOperation alloc]init];
    [opQueue cancelAllOperations];
    [opQueue addOperation:aCameraCaptureOp];
    
}

-(void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error %@", error);
}

#pragma mark - Data Send / Receive

-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    int dataInKB = data.length/1024;
    NSLog(@"data length %d B = %d KB", data.length, dataInKB);
    
    //check if I get a byte
    if(data.length < 10){
        NSLog(@"got a byte");
        isSendData = true;
        
    }
    else{
        //got an image
        NSLog(@"got image");
        NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:self.timingDate]);
        //send back 1 byte data
        NSData *aByte = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"send a byte");
        self.timingDate = [NSDate date];
        [gameSession sendData:aByte toPeers:[NSArray arrayWithObjects:gamePeerID,nil] withDataMode:GKSendDataReliable error:nil];
        
        UIImage *aImage = [UIImage imageWithData:data];
        [aImageView setFrame:CGRectMake(0, 0, aImage.size.width, aImage.size.height)];
        [aImageView setImage:aImage];
    }
}

#pragma - Match
-(void)setupMatch
{
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    
    /*
    GKMatchmaker *matchMaker = [GKMatchmaker sharedMatchmaker];
    [matchMaker startBrowsingForNearbyPlayersWithReachableHandler:^(NSString *playerID, BOOL reachable){
        if(reachable){
            
        }
    }];
    */
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
    gameMatch = match; // Use a retaining property to retain the match.
    match.delegate = self;
    if (!isMatchStarted && match.expectedPlayerCount == 0)
    {
        isMatchStarted = true;
        NSLog(@"found player");
        // Insert game-specific code to start the match.
    }
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID{
    
}

-(void)reachablePlayer:(NSString *) playerID isReachable:(BOOL)reachable{
    
}

@end
