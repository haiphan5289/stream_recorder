#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MixerConvert : NSObject

+ (void)reorderBuffer:(AudioBufferList *)audioBufferList;

+ (void)covert16bitsTo32bits:(const AudioBufferList *)inputBufferList
            outputBufferList:(AudioBufferList *)outputBufferList
               inputChannels: (UInt32) inputChannels
              outputChannels: (UInt32) outputChannels;

+ (void)covert32bitsTo16bits:(const AudioBufferList *)inputBufferList outputBufferList:(AudioBufferList *)outputBufferList channels: (UInt32) channels;


@end
