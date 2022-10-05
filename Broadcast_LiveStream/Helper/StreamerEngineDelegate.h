typedef NS_ENUM(int, ConnectionAuthMode) {
    kConnectionAuthModeDefault = 0,
    kConnectionAuthModeLlnw = 1,
    kConnectionAuthModePeriscope = 2,
    kConnectionAuthModeRtmp = 3,
    kConnectionAuthModeAkamai = 4
};

typedef NS_ENUM(int, ConnectionMode) {
    kConnectionModeVideoAudio = 0,
    kConnectionModeVideoOnly = 1,
    kConnectionModeAudioOnly = 2
};

typedef NS_ENUM(int, ConnectionState) {
    kConnectionStateInitialized,
    kConnectionStateConnected,
    kConnectionStateSetup,
    kConnectionStateRecord,
    kConnectionStateDisconnected
};

typedef NS_ENUM(int, ConnectionStatus) {
    kConnectionStatusSuccess,
    kConnectionStatusConnectionFail,
    kConnectionStatusAuthFail,
    kConnectionStatusUnknownFail
};

@protocol StreamerEngineDelegate
- (void)connectionStateDidChangeId:(int)connectionID State:(ConnectionState)state Status:(ConnectionStatus)status Info:(NSDictionary*)info;
@end
