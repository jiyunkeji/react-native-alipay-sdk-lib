#import "AlipaySdkLib.h"
#import <AlipaySDK/AlipaySDK.h>
#import <React/RCTEventEmitter.h>
@interface AlipayEventManager : RCTEventEmitter
+(void)sendEventWithName:(NSString *)eventName body:(NSMutableDictionary *)body;
@end
@implementation AlipayEventManager
+(void)sendEventWithName:(NSString *)eventName body:(NSMutableDictionary *)body{
    [self sendEventWithName:eventName body:body];
}
@end



@implementation AlipaySdkLib

RCT_EXPORT_MODULE(AlipaySdkLib)

- (NSArray<NSString *> *)supportedEvents
{
    return @[OnPayFailResponse,OnPaySuccessResponse];
}
RCT_REMAP_METHOD(pay, payInfo:(NSString *)payInfo resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
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
        [AlipaySdkLib handleResult:resultDic];
    }];
    resolve([NSNumber numberWithBool:YES]);
}

+(void) handleCallback:(NSURL *)url
{
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) { //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            [self handleResult:resultDic];
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            [self handleResult:resultDic];
        }];
    }
}

+(void) handleResult:(NSDictionary *)resultDic
{
    NSString *status = resultDic[@"resultStatus"];
    NSString *memo = resultDic[@"memo"];
    NSString *result = resultDic[@"result"];
    NSMutableDictionary *body = [NSMutableDictionary new];
    body[@"status"] = status;
    body[@"memo"] = memo;
    body[@"result"] = result;
    if ([status integerValue] == 9000) {
        
        [AlipayEventManager sendEventWithName:OnPaySuccessResponse body:body];
        
    } else {
        [AlipayEventManager sendEventWithName:OnPayFailResponse body:body];
    }
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return NO;
}


@end


