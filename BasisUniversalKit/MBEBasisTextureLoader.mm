//
//  MBEBasisTextureLoader.mm
//  BasisUniversalKit
//  From https://metalbyexample.com/basis-universal/
//

#import "MBEBasisTextureLoader.h"
#import <MetalKit/MetalKit.h>

#define BASISD_SUPPORT_PVRTC2
#include "basisu_transcoder.h"

NSString *__nonnull const MBEBasisTextureLoaderErrorDomain = @"com.metalbyexample.metalbasis";

MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionTextureUsage = @"textureUsage";
MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionTextureStorageMode = @"storageMode";
MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionPixelFormat = @"pixelFormat";

static MTLTextureUsage MBEBasisTextureLoaderDefaultUsage = MTLTextureUsageShaderRead;
#if TARGET_OS_OSX
static MTLStorageMode MBEBasisTextureLoaderDefaultStorage = MTLStorageModeManaged;
static MTLPixelFormat MBEBasisTextureLoaderDefaultPixelFormat = MTLPixelFormatBC7_RGBAUnorm;
#else
static MTLStorageMode MBEBasisTextureLoaderDefaultStorage = MTLStorageModeShared;
static MTLPixelFormat MBEBasisTextureLoaderDefaultPixelFormat = MTLPixelFormatEAC_RGBA8;
#endif

static MTLTextureType MBEMetalTextureTypeFromBasisTextureType(basist::basis_texture_type type, size_t imageCount) {
    switch (type) {
        case basist::cBASISTexType2D:
            return MTLTextureType2D;
        case basist::cBASISTexType2DArray:
            return MTLTextureType2DArray;
        case basist::cBASISTexTypeCubemapArray:
            return MTLTextureTypeCube;
        case basist::cBASISTexTypeVolume:
            return MTLTextureType3D;
        default:
            assert(!"Unsupported Basis texture type");
            break;
    }
    return MTLTextureType2D;
}

static uint32_t MBEBlockSizeInBytesFromPixelFormat(MTLPixelFormat format) {
    switch (format) {
#if TARGET_OS_OSX
        case MTLPixelFormatBC1_RGBA:
        case MTLPixelFormatBC4_RUnorm:
            return 8;
        case MTLPixelFormatBC2_RGBA:
        case MTLPixelFormatBC3_RGBA:
        case MTLPixelFormatBC5_RGUnorm:
        case MTLPixelFormatBC7_RGBAUnorm:
            return 16;
#endif
#if !TARGET_OS_OSX
        case MTLPixelFormatPVRTC_RGB_4BPP:
            return 8;
        case MTLPixelFormatEAC_RGBA8:
            return 16;
#endif
        default:
            assert(!"Unsupported pixel format");
            return -1;
    }
}

basist::transcoder_texture_format MBEBasisTranscoderFormatFromMetalPixelFormat(MTLPixelFormat format) {
    switch (format) {
#if TARGET_OS_OSX
        case MTLPixelFormatBC1_RGBA:
            return basist::transcoder_texture_format::cTFBC1_RGB;
        case MTLPixelFormatBC4_RUnorm:
            return basist::transcoder_texture_format::cTFBC4_R;
        case MTLPixelFormatBC7_RGBAUnorm:
            return basist::transcoder_texture_format::cTFBC7_M6_RGB;
        case MTLPixelFormatBC3_RGBA:
            return basist::transcoder_texture_format::cTFBC3_RGBA;
        case MTLPixelFormatBC5_RGUnorm:
            return basist::transcoder_texture_format::cTFBC5_RG;
#endif
#if !TARGET_OS_OSX
        case MTLPixelFormatPVRTC_RGB_4BPP:
            return basist::transcoder_texture_format::cTFPVRTC1_4_RGB;
        case MTLPixelFormatEAC_RGBA8:
            return basist::transcoder_texture_format::cTFETC2_RGBA;
#endif
        default:
            assert(!"Unsupported pixel format");
    }
}

static basist::etc1_global_selector_codebook *sel_codebook = nullptr;

@interface MBEBasisTranscodingOperation : NSOperation {
    basist::basisu_transcoder *_impl;
}
@property (nonatomic, nonnull, strong) NSData *data;
@property (nonatomic, nonnull, strong) id<MTLDevice> device;
@property (nonatomic, assign) MTLPixelFormat pixelFormat;
@property (nonatomic, assign) MTLTextureUsage textureUsage;
@property (nonatomic, assign) MTLStorageMode storageMode;
@property (atomic, nullable, strong) NSError *error;
@property (nonatomic, nonnull, strong) NSArray *textures;
@property (nonatomic, nullable, strong) MBEBasisTextureLoaderCallback completionHandler;
@property (atomic, assign, getter=isExecuting) BOOL executing;
@property (atomic, assign, getter=isFinished) BOOL finished;
@end

@implementation MBEBasisTranscodingOperation

@synthesize executing=_executing;
@synthesize finished=_finished;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        basist::basisu_transcoder_init();
        sel_codebook = new basist::etc1_global_selector_codebook(basist::g_global_selector_cb_size, basist::g_global_selector_cb);
        NSLog(@"INFO: Basis transcoder initialized.");
    });
}

- (_Nullable instancetype)initWithData:(NSData *)data options:(NSDictionary *)options device:(id<MTLDevice>)device {
    if ((self = [super init])) {
        _data = data;
        _device = device;
        _pixelFormat = MBEBasisTextureLoaderDefaultPixelFormat;
        _textureUsage = MBEBasisTextureLoaderDefaultUsage;
        _storageMode = MBEBasisTextureLoaderDefaultStorage;
        _textures = @[];
        _impl = new basist::basisu_transcoder(sel_codebook);
        
        NSNumber *_Nullable textureUsage = options[MBEBasisTextureLoaderOptionTextureUsage];
        if (textureUsage) {
            _textureUsage = textureUsage.integerValue;
        }
        NSNumber *_Nullable storageMode = options[MBEBasisTextureLoaderOptionTextureStorageMode];
        if (storageMode) {
            _storageMode = (MTLStorageMode)storageMode.integerValue;
        }
        NSNumber *_Nullable pixelFormat = options[MBEBasisTextureLoaderOptionPixelFormat];
        if (pixelFormat) {
            _pixelFormat = (MTLPixelFormat)pixelFormat.integerValue;
        }

    }
    return self;
}

- (void)dealloc {
    delete _impl;
}

- (void)transcodeImageAtIndex:(uint32_t)imageIndex toSlice:(uint32_t)sliceIndex texture:(id<MTLTexture>)texture
{
    basist::basisu_image_info imageInfo;
    _impl->get_image_info(_data.bytes, (uint32_t)_data.length, imageInfo, imageIndex);

    basist::transcoder_texture_format transcoderFormat = MBEBasisTranscoderFormatFromMetalPixelFormat(_pixelFormat);
    uint32_t blockSizeBytes = MBEBlockSizeInBytesFromPixelFormat(_pixelFormat);

    void *levelData = NULL;
    for (int levelIndex = 0; levelIndex < imageInfo.m_total_levels; ++levelIndex) {
        basist::basisu_image_level_info levelInfo;
        _impl->get_image_level_info(_data.bytes, (uint32_t)_data.length, levelInfo, imageIndex, levelIndex);
        
        uint32_t levelDataSizeBlocks = levelInfo.m_total_blocks;
        uint32_t leveDataSizeBytes = levelDataSizeBlocks * blockSizeBytes;
        levelData = realloc(levelData, leveDataSizeBytes);
        
        bool didTranscode = _impl->transcode_image_level(_data.bytes,
                                                         (uint32_t)_data.length,
                                                         imageIndex,
                                                         levelIndex,
                                                         levelData,
                                                         levelDataSizeBlocks,
                                                         transcoderFormat);
        if (didTranscode) {
            [texture replaceRegion:MTLRegionMake2D(0, 0, levelInfo.m_width, levelInfo.m_height)
                       mipmapLevel:levelIndex
                             slice:sliceIndex
                         withBytes:levelData
                       bytesPerRow:levelInfo.m_num_blocks_x * blockSizeBytes
                     bytesPerImage:0];
        } else {
            self.error = [NSError errorWithDomain:MBEBasisTextureLoaderErrorDomain
                                             code:MBEBasisTextureLoaderErrorTranscodingFailed
                                         userInfo:nil];
            goto fail;
        }
    }

fail:
    free(levelData);
}

- (void)main {
    self.executing = YES;
    
    bool success = _impl->start_transcoding(_data.bytes, (uint32_t)_data.length);
    if (!success) {
        self.error = [NSError errorWithDomain:MBEBasisTextureLoaderErrorDomain
                                         code:MBEBasisTextureLoaderErrorTranscodingFailed
                                     userInfo:nil];
        self.executing = NO;
        self.finished = YES;
        return;
    }
    
    basist::basis_texture_type basisTextureType = _impl->get_texture_type(_data.bytes, (uint32_t)_data.length);
    size_t imageCount = _impl->get_total_images(_data.bytes, (uint32_t)_data.length);
    
    if (basisTextureType == basist::cBASISTexTypeVideoFrames) {
        self.error = [NSError errorWithDomain:MBEBasisTextureLoaderErrorDomain
                                         code:MBEBasisTextureLoaderErrorUnsupportedTextureType
                                     userInfo:nil];
        self.executing = NO;
        self.finished = YES;
        return;
    }
    
    MTLTextureType textureType = MBEMetalTextureTypeFromBasisTextureType(basisTextureType, imageCount);

    NSMutableArray *textures = [NSMutableArray array];
    
    int imageIndex = 0;
    while (imageIndex < imageCount) {
        basist::basisu_image_info imageInfo;
        _impl->get_image_info(_data.bytes, (uint32_t)_data.length, imageInfo, imageIndex);
        
        uint32_t width = imageInfo.m_width;
        uint32_t height = imageInfo.m_height;
        uint32_t mipLevels = imageInfo.m_total_levels;
        
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
        textureDescriptor.textureType = textureType;
        textureDescriptor.pixelFormat = _pixelFormat;
        textureDescriptor.width = width;
        textureDescriptor.height = height;
        textureDescriptor.depth = (textureType == MTLTextureType3D) ? imageCount : 1;
        textureDescriptor.mipmapLevelCount = mipLevels;
        if (textureType == MTLTextureType2DArray) {
            textureDescriptor.arrayLength = imageCount;
        }
        textureDescriptor.storageMode = _storageMode;
        textureDescriptor.usage = _textureUsage;
        
        id<MTLTexture> texture = nil;
        texture = [_device newTextureWithDescriptor:textureDescriptor];
        
        if (texture == nil) {
            self.error = [NSError errorWithDomain:MBEBasisTextureLoaderErrorDomain
                                             code:MBEBasisTextureLoaderErrorTextureCreationFailed
                                         userInfo:nil];
            self.executing = NO;
            self.finished = YES;
            return;
        }

        if (textureType == MTLTextureType2D) {
            [self transcodeImageAtIndex:imageIndex toSlice:0 texture:texture];
            ++imageIndex;
        } else if (textureType == MTLTextureType2DArray) {
            for (int i = 0; i < imageCount; ++i) {
                [self transcodeImageAtIndex:imageIndex + i toSlice:i texture:texture];
            }
            imageIndex += imageCount;
        } else if (textureType == MTLTextureType3D) {
            for (int i = 0; i < imageCount; ++i) {
                [self transcodeImageAtIndex:imageIndex + i toSlice:i texture:texture];
            }
            imageIndex += imageCount;
        } else if (textureType == MTLTextureTypeCube) {
            for (int i = 0; i < 6; ++i) {
                [self transcodeImageAtIndex:imageIndex + i toSlice:i texture:texture];
            }
            imageIndex += 6;
        }
        
        [textures addObject:texture];
    }
    
    _textures = [textures copy];
    
    self.executing = NO;
    self.finished = YES;
}

- (void)start {
    [self main];
    if (self.completionHandler) {
        self.completionHandler(self.textures.firstObject, self.error);
    }
}

- (BOOL)asynchronous {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    @synchronized(self) {
        [self willChangeValueForKey:@"executing"];
        _executing = executing;
        [self didChangeValueForKey:@"executing"];
    }
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setFinished:(BOOL)finished {
    @synchronized(self) {
        [self willChangeValueForKey:@"finished"];
        _finished = finished;
        [self didChangeValueForKey:@"finished"];
    }
}

- (BOOL)isFinished {
    return _finished;
}

@end

@interface MBEBasisTextureLoader ()
@property (nonatomic, strong) NSOperationQueue *transcodingQueue;
@end

@implementation MBEBasisTextureLoader

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if ((self = [super init])) {
        _device = device;
        _transcodingQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)newTextureWithContentsOfURL:(nonnull NSURL *)URL
                            options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                  completionHandler:(nonnull MBEBasisTextureLoaderCallback)completionHandler
{
    NSData *data = [NSData dataWithContentsOfURL:URL];
    [self newTextureWithData:data
                     options:options
           completionHandler:^(id<MTLTexture> _Nullable texture, NSError *_Nullable error) {
        completionHandler(texture, error);
    }];
}

- (void)newTextureWithData:(nonnull NSData *)data
                   options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
         completionHandler:(nonnull MBEBasisTextureLoaderCallback)completionHandler
{
    MBEBasisTranscodingOperation *op = [[MBEBasisTranscodingOperation alloc] initWithData:data
                                                                                  options:options
                                                                                   device:_device];
    op.completionHandler = completionHandler;
    
    [self.transcodingQueue addOperation:op];
}

- (nullable id <MTLTexture>)newTextureWithContentsOfURL:(nonnull NSURL *)URL
                                                options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                                  error:(NSError *__nullable *__nullable)error
{
    NSData *data = [NSData dataWithContentsOfURL:URL];
    return [self newTextureWithData:data options:options error:error];
}

- (nullable id <MTLTexture>)newTextureWithData:(nonnull NSData *)data
                                       options:(nullable NSDictionary <MTKTextureLoaderOption, id> *)options
                                         error:(NSError *__nullable *__nullable)error
{
    MBEBasisTranscodingOperation *op = [[MBEBasisTranscodingOperation alloc] initWithData:data
                                                                                  options:options
                                                                                   device:_device];
    [op main];
    
    if (op.error != nil && error != nil) {
        *error = op.error;
    }
    return op.textures.firstObject;
}

@end
