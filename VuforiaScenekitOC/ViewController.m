//
//  ViewController.m
//  VuforiaScenekitOC
//
//  Created by CoWill on 2017/8/9.
//  Copyright © 2017年 CoWill. All rights reserved.
//

#import "ViewController.h"
#import "VuforiaManager.h"
@interface ViewController ()<VuforiaManagerDelegate,VuforiaEAGLViewSceneSource, VuforiaEAGLViewDelegate>
@property (nonatomic,strong) NSString* vuforiaLicenseKey;
@property (nonatomic,strong) NSString* vuforiaDataSetFile;
@property (nonatomic,strong) VuforiaManager* vuforiaManager;
@property (nonatomic,strong) NSString* lastSceneName;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupVuforiaManager];
    
}
-(void)setupVuforiaManager{
    self.vuforiaLicenseKey=@"Your LicenseKey";
    
    self.vuforiaDataSetFile= @"Your dataset file, such like StonesAndChips.xml";
    self.vuforiaManager=[[VuforiaManager alloc]initWithLicenseKey:self.vuforiaLicenseKey dataSetFile:self.vuforiaDataSetFile];
    
    if(self.vuforiaManager){
        self.vuforiaManager.delegate=self;
        self.vuforiaManager.eaglView.sceneSource=self;
        self.vuforiaManager.eaglView.delegate = self;
        [self.vuforiaManager.eaglView setupRenderer];
        self.view = self.vuforiaManager.eaglView;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRecieveWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRecieveDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    //设置默认的转向
    [self.vuforiaManager prepareWithOrientation:UIInterfaceOrientationPortrait];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillDisappear:(BOOL)animated{
    if(self.vuforiaManager){
        NSError* error;
        if(![self.vuforiaManager stop:&error]){
            NSLog(@"Error!-------VuforiaManager can not stop");
        }
        
    }
}
#pragma mark - VuforiaManagerDelegate
- (void)vuforiaManagerDidFinishPreparing:(VuforiaManager*) manager{
    NSLog(@"did finish preparing\n");
    NSError* error;
    if([self.vuforiaManager start:&error]){
        [self.vuforiaManager setContinuousAutofocusEnabled:YES];
    }
    else{
        NSLog(@"Error!-------VuforiaManager start error");
    }
}
- (void)vuforiaManager:(VuforiaManager*)manager didFailToPreparingWithError:(NSError*)error{
    NSLog(@"did faid to preparing %@",error);
}
- (void)vuforiaManager:(VuforiaManager *)manager didUpdateWithState:(VuforiaState*)state{
    for(int index=0; index<state.numberOfTrackableResults; ++index){
        VuforiaTrackableResult* result=[state trackableResultAtIndex:index];
        NSString* trackerableName=result.trackable.name;
        if([trackerableName isEqualToString:self.lastSceneName])
            return;
        
        if([trackerableName isEqualToString:@"stones"]){
            [manager.eaglView setNeedsChangeSceneWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"stones",@"scene", nil]];
            self.lastSceneName=@"stones";
            return;
        }
        if([trackerableName isEqualToString:@"chips"]){
            [manager.eaglView setNeedsChangeSceneWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"chips",@"scene", nil]];
            self.lastSceneName=@"chips";
            return;
        }
    }

}

#pragma mark - VuforiaEAGLViewSceneSource
- (SCNScene *)sceneForEAGLView:(VuforiaEAGLView *)view userInfo:(NSDictionary<NSString*, id>*)userInfo{
    if(!userInfo)
        return [self createBoxScenewithView:view];//default

    if([userInfo[@"scene"] isEqualToString:@"stones"]){
        return [self createBoxScenewithView:view];//create a simple box
    }
    else if([userInfo[@"scene"] isEqualToString:@"chips"]){
        return [self createTreeSceneWithView:view];//create scene from model
    }
    else{
        return [self createBoxScenewithView:view];//default
    }
}

#pragma mark - VuforiaEAGLViewDelegate
- (void)vuforiaEAGLView:(VuforiaEAGLView*)view didTouchDownNode:(SCNNode *)node{
    NSLog(@"touch down");
}
- (void)vuforiaEAGLView:(VuforiaEAGLView*)view didTouchUpNode:(SCNNode *)node{
    NSLog(@"touch up");
}
- (void)vuforiaEAGLView:(VuforiaEAGLView*)view didTouchCancelNode:(SCNNode *)node{
    NSLog(@"touch cancel");
}

#pragma mark - vuforia manager
-(void)vuforiaManagerPause{
    if(self.vuforiaManager){
        NSError* error;
        if(![self.vuforiaManager pause:&error]){
            NSLog(@"Error!-------VuforiaManager can not pause");
        }
        
    }
}
-(void)vuforiaManagerResume{
    if(self.vuforiaManager){
        NSError*  error;
        if(![self.vuforiaManager resume:&error]){
            NSLog(@"Error!-------VuforiaManager can not resume");
        }
        
    }
}
-(void)didRecieveWillResignActiveNotification{
    [self vuforiaManagerPause];
}
-(void)didRecieveDidBecomeActiveNotification{
    [self vuforiaManagerResume];
}

#pragma mark - create scene
-(SCNScene*) createBoxScenewithView: (VuforiaEAGLView*)view{
    SCNScene* scene= [SCNScene scene];
    
    SCNNode* lightNode=[SCNNode node];
    lightNode.light=[SCNLight light];
    lightNode.light.type=SCNLightTypeOmni;
    lightNode.light.color=[UIColor lightGrayColor];
    lightNode.position=SCNVector3Make(0,10,10);
    [scene.rootNode addChildNode:lightNode];
    
    SCNNode* ambientLightNode=[SCNNode node];
    ambientLightNode.light=[SCNLight light];
    ambientLightNode.light.type=SCNLightTypeOmni;
    ambientLightNode.light.color=[UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];

    SCNNode* boxNode=[SCNNode node];
    boxNode.name=@"box";
    boxNode.geometry=[SCNBox boxWithWidth:3 height:3 length:3 chamferRadius:0.0];
    boxNode.geometry.firstMaterial=[SCNMaterial material];
    boxNode.geometry.firstMaterial.diffuse.contents= [UIColor blueColor];
    [scene.rootNode addChildNode:boxNode];
    
    return scene;
}

-(SCNScene*) createTreeSceneWithView:(VuforiaEAGLView*)view{
    SCNScene* scene=[SCNScene scene];
    SCNNode* node=[SCNNode node];
    SCNScene* sceneModel=[SCNScene sceneNamed:@"Lowpoly_tree_sample.scn"];
    for(SCNNode* n in sceneModel.rootNode.childNodes){
        [node addChildNode:n];
    }
    //make the eulerAngles right
    node.position=SCNVector3Make(0, 0, -1);
    node.eulerAngles=SCNVector3Make(M_PI_2, 0, 0);
    
    [scene.rootNode addChildNode:node];
    return scene;
}
@end
