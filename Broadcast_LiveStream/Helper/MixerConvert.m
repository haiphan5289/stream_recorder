#import <Foundation/Foundation.h>
#import "MixerConvert.h"

@implementation MixerConvert

const Float32 conversion16Base = 32768.0f;

+ (void)covert16bitsTo32bits:(const AudioBufferList *)inputBufferList
            outputBufferList:(AudioBufferList *)outputBufferList
               inputChannels: (UInt32) inputChannels
              outputChannels: (UInt32) outputChannels {
    for(UInt32 i = 0; i < outputChannels; i++) {
        const AudioBuffer* input_buffer = inputBufferList[0].mBuffers;
        AudioBuffer* output_buffer = outputBufferList[i].mBuffers;
        int numberFrames = MIN(input_buffer->mDataByteSize/2, output_buffer->mDataByteSize/4);
        const SInt16* input_data = (SInt16*)input_buffer->mData;
        Float32* output_data = (Float32*)output_buffer->mData;

        if (inputChannels == outputChannels) {
            for(int frame=0; frame <numberFrames; frame++) {
                output_data[frame] = (Float32)input_data[frame*inputChannels+i] / conversion16Base;
            }
        } else {
            assert(inputChannels == 1);
            for(int frame=0; frame <numberFrames; frame++) {
                output_data[frame] = (Float32)input_data[frame] / conversion16Base;
            }
        }
    }
}


+ (void)covert32bitsTo16bits:(const AudioBufferList *)inputBufferList outputBufferList:(AudioBufferList *)outputBufferList channels: (UInt32) channels {
    for(UInt32 i = 0; i < channels; i++) {
        const AudioBuffer* input_buffer = inputBufferList[i].mBuffers;
        AudioBuffer* output_buffer = outputBufferList[0].mBuffers;
        UInt32 numberFrames = MIN(input_buffer->mDataByteSize/4 , output_buffer->mDataByteSize/2);
        const Float32* input_data = (Float32*)input_buffer->mData;
        SInt16* output_data = (SInt16*)output_buffer->mData;

        for(UInt32 frame = 0; frame<numberFrames; frame++) {
            output_data[frame*channels+i] = (SInt16)(input_data[frame] * conversion16Base);
        }
    }
}

+ (void)reorderBuffer:(AudioBufferList *)audioBufferList {
    
    AudioBuffer buffer = audioBufferList->mBuffers[0];
    UInt32 count = buffer.mDataByteSize / 2;
    UInt16* data = (UInt16 *)buffer.mData;
    for (UInt32 i=0; i < count; i++) {
        UInt16 x = data[i];
        x = ((x & 0xff00) >> 8) | ((x & 0x00ff) << 8);
        data[i] = x;
    }
}


@end

