#import <Foundation/Foundation.h>
#import "StreamerEngineDelegate.h"

typedef NS_ENUM(int, SrtConnectMode) {
    kSrtConnectModeCaller = 0,
    kSrtConnectModeListen = 1,
    kSrtConnectModeRendezvous = 2
};

@interface SrtConfig : NSObject

/*! @brief name host name or IP address
    @discussion for IPv6, IP addres should be provided in a form [xx:xx:xx:xx:xx:xx]
    If connectMode set to listen, you may set any valid IP; use IPv6 format (you may use simple [::] ) to listen on IPv6 interface.
*/
@property NSString* host;
//! @brief target port in 1-65535 range
@property int port;
//! @brief connection mode: Send both audio and video frames or just audio or video
@property ConnectionMode mode;
/*! @brief SRT connection mode: caller, listener or rendez-vouz
    @discussion In a listener mode multiple client connections may be served. It will remain in connected state even if there are no clients.
    Each client will receive own stream, so traffic will be multiplied to number of clients.
*/
@property SrtConnectMode connectMode;
//! @brief SRTO_PASSPHRASE
@property NSString* passphrase;
/*! @brief SRTO_PBKEYLEN
    @discussion Accepted values are 0 (no encryption), 16 (AES-128), 24 (AES-192), 32 (AES-256)
*/
@property int pbkeylen;
//! @brief SRTO_LATENCY
@property int latency;
/*! @brief SRTO_MAXBW (Mind that it set in BYTES per second)
 @discussion Recommended to set to 0 and let SRT library to decide
 */
@property int32_t maxbw;
/*! @brief SRTO_RETRANSMITALGO  */
@property ConnectionRetransmitAlgo retransmitAlgo;
/*! @brief SRTO_STREAMID */
@property NSString* streamid;

@end
