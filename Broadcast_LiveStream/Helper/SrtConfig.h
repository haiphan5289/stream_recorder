#import <Foundation/Foundation.h>
#import "StreamerEngineDelegate.h"

@interface SrtConfig : NSObject

@property NSString* host;
@property int port;
@property ConnectionMode mode;
@property NSString* passphrase;
@property int pbkeylen;
@property int latency;
@property int maxbw;
@property NSString* streamid;

@end
