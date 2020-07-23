//
//  MBEBasisTextureLoader.h
//  BasisUniversalKit
//  From https://metalbyexample.com/basis-universal/
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

extern NSString *__nonnull const MBEBasisTextureLoaderErrorDomain;

typedef NS_ENUM(NSInteger, MBEBasisTextureLoaderError) {
    MBEBasisTextureLoaderErrorUnsupportedTextureType = -1,
    MBEBasisTextureLoaderErrorTranscodingFailed = -2,
    MBEBasisTextureLoaderErrorTextureCreationFailed = -3,
}
NS_SWIFT_NAME(MBEBasisTextureLoader.Error);

typedef NSString * MBEBasisTextureLoaderOption NS_STRING_ENUM
NS_SWIFT_NAME(MBEBasisTextureLoader.Option);

extern MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionTextureUsage;
extern MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionTextureStorageMode;

/// The preferred pixel format for the texture.
/// On macOS, one of:
///  - MTLPixelFormatBC1_RGBA
///  - MTLPixelFormatBC4_RUnorm
///  - MTLPixelFormatBC3_RGBA
///  - MTLPixelFormatBC5_RGUnorm
///  - MTLPixelFormatBC7_RGBAUnorm
/// On iOS or tvOS, one of:
///  - MTLPixelFormatPVRTC_RGB_4BPP
///  - MTLPixelFormatEAC_RGBA8
extern MBEBasisTextureLoaderOption __nonnull const MBEBasisTextureLoaderOptionPixelFormat;

typedef void (^MBEBasisTextureLoaderCallback) (id <MTLTexture> __nullable texture, NSError * __nullable error)
NS_SWIFT_NAME(MBEBasisTextureLoader.Callback);

@interface MBEBasisTextureLoader : NSObject

@property (nonatomic, nonnull, strong) id<MTLDevice> device;

- (_Nonnull instancetype)initWithDevice:(id<MTLDevice> _Nonnull)device;

- (void)newTextureWithContentsOfURL:(nonnull NSURL *)URL
                            options:(nullable NSDictionary <MBEBasisTextureLoaderOption, id> *)options
                  completionHandler:(nonnull MBEBasisTextureLoaderCallback)completionHandler
NS_SWIFT_NAME(newTexture(URL:options:completionHandler:));

- (void)newTextureWithData:(nonnull NSData *)data
                   options:(nullable NSDictionary <MBEBasisTextureLoaderOption, id> *)options
         completionHandler:(nonnull MBEBasisTextureLoaderCallback)completionHandler
NS_SWIFT_NAME(newTexture(data:options:completionHandler:));

- (nullable id <MTLTexture>)newTextureWithContentsOfURL:(nonnull NSURL *)URL
                                                options:(nullable NSDictionary <MBEBasisTextureLoaderOption, id> *)options
                                                  error:(NSError *__nullable *__nullable)error
NS_SWIFT_NAME(newTexture(URL:options:));

- (nullable id <MTLTexture>)newTextureWithData:(nonnull NSData *)data
                                       options:(nullable NSDictionary <MBEBasisTextureLoaderOption, id> *)options
                                         error:(NSError *__nullable *__nullable)error
NS_SWIFT_NAME(newTexture(data:options:));

@end
