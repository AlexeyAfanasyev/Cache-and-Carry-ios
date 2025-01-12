/*!
 *  Notice: This file is the property of Penthera Inc.
 *  The concepts contained herein are proprietary to Penthera Inc.
 *  and may be covered by U.S. and/or foreign patents and/or patent
 *  applications, and are protected by trade secret or copyright law.
 *  Distributing and/or reproducing this information is forbidden unless
 *  prior written permission is obtained from Penthera Inc.
 *
 *  The VirtuosoClientEngineDemo project has been provided as an example application
 *  that uses the Virtuoso Download SDK.  It is provided as-is with no warranties whatsoever,
 *  expressed or implied.  This project provides a working example and shows ONE possible
 *  use of the SDK for a end-to-end video download process.  Other configurations
 *  are possible.  Please contact Penthera support if you have any questions.  We
 *  are here to help!
 *
 *  @copyright (c) 2017 Penthera Inc. All Rights Reserved.
 *
 */

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

/*
 *  This VirtuosoLoggerDelegate method is fired whenever internal SDK debug statements are logged.  Callers can use this to 
 *  route SDK debug statements to their own logging systems.
 */
- (void)virtuosoDebugEventOccurred:(NSString *)data
{
    
}

/*
 *  This VirtuosoLoggerDelegate method is fired whenever internal events are generated.  Callers can use this to route SDK events to
 *  their own custom analytics system.
 */
- (void)virtuosoEventOccurred:(kVL_LogEvent)event forFile:(NSString *)fileID onBearer:(kVL_BearerType)bearer withData:(long long)data
{
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Process the fetch in the SDK.
    [VirtuosoEventHandler processFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
        
        // Do any synchronous or asynchronous processing you need to do here.  Just make sure to merge your own fetch result with the
        // SDK fetch result....
        if( completionHandler != NULL )
            completionHandler(result);
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"Did receive push notice: %@",userInfo);
    if( [VirtuosoEventHandler processRemotePushNotice:userInfo withCompletionHandler:completionHandler] )
    {
        // This push was received and processed by the SDK.  We don't need to do anything further with it here.
        NSLog(@"Push notice was handled by engine.");
    }
    else
    {
        // This push was not processed by the engine.  It is likely a push generated by a non-Penthera system.  It is your
        // responsibility to handle the push data here.
        NSLog(@"Push notice could not be handled by engine.");
    }
}

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"Did receive background download session wake for session: %@",identifier);
    if( [VirtuosoEventHandler processBackgroundSessionWake:identifier completionHandler:completionHandler] )
    {
        NSLog(@"Wake was handled by engine.");
    }
    else
    {
        NSLog(@"Wake could not be handled by engine.");
        
        // Application should process this.  It's not for the Engine.
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Handle the "old" method, just in case.  We just need to call the "new" method without a handler.
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
        // Blank completion handler, to silence compiler warnings.
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
#warning You will be unable to generate a usable push token unless you properly configure your app provisioning profiles and upload an Apple push certificate to your Backplane instance.
    
    // Due to Apple's infrastructure requirements, the push certificates stored on the server *must* match the provisioning profile
    // used to build the app.  Otherwise, push notices will not function.  You can still "simulate" receiving a push notice by tapping
    // the manual sync button in the app or by backgrounding and foregrounding the app.  When you build your own proof-of-concept application
    // and use your own application secret and key to startup the engine, you will need to provide the configured server push certificate
    // to the Backplane.  See the Backplane documentation for additional details.
    
    if( [VirtuosoDownloadEngine instance].started )
        [VirtuosoSettings instance].devicePushToken = [deviceToken description];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error registering for push notices: %@",error);
    
    if( [VirtuosoDownloadEngine instance].started )
        [VirtuosoSettings instance].devicePushToken = nil;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
     * We are NOT going to register for remote notifications here, because we need to authenticate a user first (in this case,
     * just ask for a user name).  We'll register after engine startup.
     */

    /*
     *  For the purposes of our example, we want to default the Download Engine enabled state to NO.  This default setting
     *  will be used by the ViewController to finish configuration of the Engine after the Backplane User and Group have been 
     *  entered.  This defaults value is being set explicitly for clarity.
     */
    if( [[NSUserDefaults standardUserDefaults] objectForKey:@"ClientEngineEnabledPreference"] == nil )
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ClientEngineEnabledPreference"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    /*
     *  Penthera recommends configuring all logging as early as possible in the didFinishLaunchingWithOptions method.  For the
     *  purpose of our example, we're going to setup logging to be as verbose as possible on all log output paths.  For real-world
     *  applications, you'll want to configure your own log options.
     */
    [VirtuosoLogger addDelegate:self];
    [VirtuosoLogger setLogLevel:kVL_LogVerbose];
    [VirtuosoLogger enableLogsToFile:YES];
    
    /*
     *  Configure the DRM license manager
     */
    [VirtuosoLicenseManager setLicenseServerURL:@"https://widevine-proxy.appspot.com/proxy" forDRM:kVLM_Widevine]; // Google License Server
    [VirtuosoLicenseManager setDelegate:self];

    /*
     *  Output the SDK version, as this may help with support
     */
    NSLog(@"Cache & Carry SDK Version: %@",[VirtuosoDownloadEngine versionString]);

    /*
     *  You must call this method to enable the background fetch features.
     */
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    /*
     *  Standard app configuration and startup
     */
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:self.viewController];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)lookupID:(NSString *__autoreleasing  _Nonnull *)licenseID andLicenseToken:(NSString *__autoreleasing  _Nonnull *)licenseToken forAsset:(VirtuosoAsset *)asset
{
    if( [asset.assetID isEqualToString:@"<ASSET_THAT_NEEDS_SPECIAL_TOKENS>"] )
    {
        *licenseID = @"<LICENSE ID>";
        *licenseToken = @"<URL ENCODED TOKEN>";
    }
    else
    {
        *licenseID = nil;
        *licenseToken = nil;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
