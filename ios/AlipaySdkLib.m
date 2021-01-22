#import "AlipaySdkLib.h"
#import <AlipaySDK/AlipaySDK.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AlipaySdkLibManager : NSObject

@property(strong,nonatomic)NSMutableArray *sdkLibs;

+(AlipaySdkLibManager *)shareManager;
-(void) handleResult:(NSDictionary *)resultDic;
-(void)addAlipaySdkLib:(AlipaySdkLib *)alipay;
-(void)destory;
@end

NS_ASSUME_NONNULL_END

static AlipaySdkLibManager *sdkLibManager = nil;

@implementation AlipaySdkLibManager

+(AlipaySdkLibManager *)shareManager{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sdkLibManager = [[[self class]alloc]init];
        
    });
    
    return sdkLibManager;

}
-(instancetype)init{
    self = [super init];
    if (self) {
        _sdkLibs = [NSMutableArray new];
    }
    return self;

}

-(void)handleResult:(NSDictionary *)resultDic{
    NSLog([NSString stringWithFormat:@"%d",self.sdkLibs.count]);
    for (int i=0; i<self.sdkLibs.count; i++) {
        AlipaySdkLib *sdkLib = self.sdkLibs[i];
        [sdkLib handleResult:resultDic];
    }
}

-(void)addAlipaySdkLib:(AlipaySdkLib *)alipay{
    if(![self.sdkLibs containsObject:alipay]){
        [self.sdkLibs addObject:alipay];

    }
}
-(void)destory{
    
    [self.sdkLibs removeAllObjects];
}

@end



@implementation AlipaySdkLib

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[AlipaySdkLibManager shareManager] addAlipaySdkLib:self];
    }
    return self;
}

-(void)dealloc{
    
    [[AlipaySdkLibManager shareManager] destory];
}

RCT_EXPORT_MODULE(AlipaySdkLib)

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (NSDictionary *)constantsToExport
{
  return @{ @"AlipaySdk": @"com.reactnativealipaysdk" };
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[OnPaySuccessResponse,OnPayFailResponse];
}
RCT_EXPORT_METHOD(pay:(NSString *)payInfo resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray *urls = [[NSBundle mainBundle] infoDictionary][@"CFBundleURLTypes"];
    NSMutableString *appScheme = [NSMutableString string];
    BOOL multiUrls = [urls count] > 1;
    for (NSDictionary *url in urls) {
        NSArray *schemes = url[@"CFBundleURLSchemes"];
        if (!multiUrls ||
            (multiUrls && [@"alipay" isEqualToString:url[@"CFBundleURLName"]])) {
            [appScheme appendString:schemes[0]];
            break;
        }
    }
    
    if ([appScheme isEqualToString:@""]) {
        NSString *error = @"scheme cannot be empty";
        reject(@"10000", error, [NSError errorWithDomain:error code:10000 userInfo:NULL]);
        return;
    }
    
    [[AlipaySDK defaultService] payOrder:payInfo fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        [[AlipaySdkLibManager shareManager] handleResult:resultDic];
    }];
    resolve([NSNumber numberWithBool:YES]);
}

+(void) handleCallback:(NSURL *)url
{
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) { //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            [[AlipaySdkLibManager shareManager] handleResult:resultDic];
            
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            [[AlipaySdkLibManager shareManager] handleResult:resultDic];
        }];
    }
}

-(void) handleResult:(NSDictionary *)resultDic
{
    NSString *status = resultDic[@"resultStatus"];
    NSString *memo = resultDic[@"memo"];
    NSString *result = resultDic[@"result"];
    NSMutableDictionary *body = [NSMutableDictionary new];
    body[@"status"] = status;
    body[@"memo"] = memo;
    body[@"result"] = result;
   if ([status integerValue] == 9000) {

       [self sendEventWithName:OnPaySuccessResponse body:body];

   } else {
       [self sendEventWithName:OnPayFailResponse body:body];
   }
}


@end


