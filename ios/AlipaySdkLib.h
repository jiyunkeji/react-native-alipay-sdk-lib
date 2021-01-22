#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#define OnPaySuccessResponse @"onPaySuccessResponse"
#define OnPayFailResponse @"onPayFailResponse"

@interface AlipaySdkLib : RCTEventEmitter <RCTBridgeModule>

+(void) handleCallback:(NSURL *)url;
-(void) handleResult:(NSDictionary *)resultDic;
@end

