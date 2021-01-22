#import <React/RCTBridgeModule.h>
#define OnPaySuccessResponse @"onPaySuccessResponse"
#define OnPayFailResponse @"onPayFailResponse"

@interface AlipaySdkLib : NSObject <RCTBridgeModule>

+(void) handleCallback:(NSURL *)url;
@end
