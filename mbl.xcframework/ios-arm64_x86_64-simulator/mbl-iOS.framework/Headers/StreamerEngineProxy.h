#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

#import "StreamerEngineDelegate.h"
#import "AudioEncoderConfig.h"
#import "VideoEncoderConfig.h"
#import "ConnectionConfig.h"
#import "SrtConfig.h"
#import "RistConfig.h"

@interface StreamerEngineProxy : NSObject

@property (readonly) AudioEncoderConfig *audioConfig;
@property (readonly) VideoEncoderConfig *videoConfig;
@property (weak, readonly) id<StreamerEngineDelegate> delegate;

// buffer size is video frames per second + audio frames per second
// average video framerate is approximately 30 fps
// audio also is frame based (for AAC, it's 1024 samples frames),
// so for 44.1 kHz, you can have audio duration only with a 23 ms granularity
//
// 1 second buffer will need 30 video frames + 42 audio frames
//
// default buffer size is 200 items (approx. 3 sec), at least 1 sec buffer is mandatory
- (id)initWithMaxItems:(int)capacity;

/*! @brief Set delegate for StreamerEngine
    @param newDelegate The object to which messages about connection and recording state should be sent
 */
- (void)setDelegate:(id<StreamerEngineDelegate>)newDelegate;

/*! @brief Set audio encoding parameters
 @param newConfig Settings for audio encoding (sample rate, bitrate etc.)
 */
- (void)setAudioConfig:(AudioEncoderConfig *)newConfig;

/*! @brief Set video encoding parameters
 @param newConfig Settings for video encoding (resolution, bitrate etc.)
 @link setVideoConfig @/setVideoConfig
 */
- (void)setVideoConfig:(VideoEncoderConfig *)newConfig;

/*! @brief set custom flashVer for rtmp protocol
    @param customUserAgent version string (e.g "FMLE/3.0 (compatible; customUserAgent)" )
 */
- (void)setUserAgent:(NSString *)customUserAgent;

/*! @brief Enable audio/video inteleaving
    @discussion When enabled, audio/video frames will be rearranged according to timestams.
            It will bring some delay, but can solve issues with some servers that can't handle timestamp jumbacks
    @param enabled  Enable interleaving
 */
-(void)setInterleaving:(Boolean)enabled;

/*! @brief Create video compression session
    @discussion Call  @link setVideoConfig @/link prior to this function call
    @return true if compression session successfully created, false otherwise
 */
- (bool)startVideoEncoding;

/*! @brief Release video compression session
 */
- (void)stopVideoEncoding;

/*! @brief Change average video bitrate on the fly
    @param newBitrate bitrate in bits per second
 */
- (void)updateBitrate:(int)newBitrate;

/*! @brief Change maximum video bitrate on the fly
    @param newLimit bitrate in bits per second
 */
- (void)updateLimit:(int)newLimit;

/*! @brief Release audio compression session
    @discussion There is no startAudioEncoding function - audio conpression will start implicitly with first *didOutputAudioSampleBuffer* call
 */
- (void)stopAudioEncoding;


/*! @brief Get current video encoding frame rate
    @discussion Actual frame rate may be lower than one set in video config due to frame skip
    @return number of frames per second
 */
- (double)getFps;

/*! @brief Get number of bytes sent
    @return number of bytes sent for connection
 */
- (uint64_t)getBytesSent:(int)connectionID;

/*! @brief Get number of bytes delivered
    @discussion Network framework may queue data if connection has no sufficient bandwidth.
    In this case diffrence between bytes send and bytes delivered will mean amount of queued data
    @return number of bytes delivered for connection
 */
- (uint64_t)getBytesDelivered:(int)connectionID;

/*! @brief Get number of bytes received
    @return number of bytes received for connection
 */
- (uint64_t)getBytesRecv:(int)connectionID;

- (uint64_t)getAudioPacketsSent:(int)connectionID __attribute__((deprecated("use getBytesSent instead.")));
- (uint64_t)getVideoPacketsSent:(int)connectionID __attribute__((deprecated("use getBytesSent instead.")));;

- (uint64_t)getAudioPacketsLost:(int)connectionID __attribute__((deprecated("use getBytesSent and getBytesDelivered instead.")));
- (uint64_t)getVideoPacketsLost:(int)connectionID __attribute__((deprecated("use getBytesSent and getBytesDelivered instead.")));

/*! @brief Get numberof packets lost on SRT connection
    @discussion We sent 1316 bytes per packet (188*7), so you can get number of bytes based on this
    @return number of packers  lost
 */
- (uint64_t)getUdpPacketsLost:(int)connectionID;

/*! @brief Sent video frame for encoding
    @param sampleBuffer frame received from camera
    @discussion if you don't do postprocessing with CoreImage, simply pass CMSampleBuffer to h264 encoder
 */
- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/*! @brief Sent video frame for encoding
    @param pixelBufferRef pixel buffer with processed camera image
    @param time frame timestamp
    @discussion if you do postprocessing with CoreImage, your output will be of CVPixelBuffer type
 pass timestamp from camera as is for better audio/video sync
 */
- (void)didOutputVideoPixelBuffer:(CVPixelBufferRef)pixelBufferRef withPresentationTime:(CMTime)time;

/*! @brief Sent video frame for encoding with current timestamp
    @param pixelBufferRef pixel buffer
    @discussion if you render static image, let libmbl2 take care of timestamp (<code>CACurrentMediaTime()</code> will be used)
 */
- (void)didOutputVideoPixelBuffer:(CVPixelBufferRef)pixelBufferRef;

/*! @brief Sent audio frame for encoding
    @param sampleBuffer frame received from microphone
 */
- (void)didOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/*! @brief Create connection with RTMP/RTSP server
    @param config connection URL and settings
    @return ID of new connection in a case of success, -1 otherwise
 */
- (int)createConnection:(ConnectionConfig *)config;

/*! @brief Create connection over SRT protocol
    @param config connection host/port and settings
    @return ID of new connection in a case of success, -1 otherwise
 */
- (int)createSrtConnection:(SrtConfig *)config;

/*! @brief Create connection over RIST protocol
    @param config connection url and settings
    @discussion additional RIST parameters can be provided in URL.
    See RIST documentaion:  https://code.videolan.org/rist/librist/-/wikis/3.%20rist%20URL%20Syntax%20and%20Examples  for details
    @return ID of new connection in a case of success, -1 otherwise
 */
- (int)createRistConnection:(RistConfig *)config;

/*! @brief Release connection
    @param connectionId id of connectin returned by createConnection / createSrtConnection / createRistConnection
 */
- (void)releaseConnection:(int)connectionId;

/*! @brief Start stream recording to file
    @param fileUrl local file URL to store file
    @param mode recording mode (audio+video or just audio or video)
    @discussion Video files will be created in QuickTime movie format (,mov), audio files in MP4/AAC format (.m4a)
 */
-(bool)startFileWriter: (NSURL*) fileUrl mode: (ConnectionMode) mode;

/*! @brief Switch recording to another file.
    @param fileUrl local file URL to store file
    @discussion For video recording, switch will be delayed till next keyframe
 */
-(bool)switchFileWriter: (NSURL*) fileUrl;

/*! @brief Stop stream recording
 */
//
-(void)stopFileWriter;

/*! @brief Toggle mute
    @param silence  true to disable audio, false to enable
    @discussion To mute audio client should not stop sending audio frames.
    This will highly likely break playback, because majority of video players depend on audio timestamps continuity.
    Instead libmbl2 produces silence in audio stream and keeps continious audio timestamp sequence.
 */
- (void)setSilence:(Boolean)silence;

/*! @brief Send "@setDataFrame", "onMetaData", metadata
    @param connectionID ID of the connection
    @param params metadata items
    @discussion https://helpx.adobe.com/adobe-media-server/dev/adding-metadata-live-stream.html
    Each metadata item is a property with a name and a value set in the metadata dictionary
    NSString and NSNumber values are supported. To add boolean value, use [NSNumber numberWithBool:YES]
 */
- (bool)pushMetaData:(int)connectionID metadata:(NSDictionary *)params;

/*! @brief Send "handler", metadata
    @param connectionID ID of the connection
    @param params metadata items
 */
- (bool)sendDirect:(int)connectionID handler:(NSString *)handler metadata:(NSDictionary *)params;

@end
