//
//  SMTImageDecoder.m
//  FirstMacApp
//
//  Created by sunmengtuo on 2021/8/26.
//

#import "SMTImageDecoder.h"
#import <Cocoa/Cocoa.h>

#define FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

@interface SMTImageDecoder ()

@property(nonatomic, assign, readonly)CGFloat scale;
@property(nonatomic, assign, readonly)SMTImageType imageType;
@property uint32_t* bitmapData; // 解码后的数据

@end

@implementation SMTImageDecoder


+(instancetype)decoderWithData:(NSData*)data scale:(CGFloat)scale
{
    if (!data) {
        return nil;
    }
    SMTImageDecoder *decoder = [[SMTImageDecoder alloc]initWithScale:scale];
    [decoder updateImageInformation:data];
    return decoder;
}

-(instancetype)initWithScale:(CGFloat)scale
{
    self = [super init];
    if (self) {
        _scale = scale;
    }
    return self;
}

-(BOOL)updateImageInformation:(NSData*)data
{
    _imageType = imageTypeDetectWithData(data);
    return YES;
}

-(CGImageRef)decodeWithData:(NSData*)data
{
    if (!data) {
        return NULL;
    }
    NSArray * imageReps = [NSBitmapImageRep imageRepsWithData:data];

    NSUInteger width = 0;
    NSUInteger height = 0;

    // 图片可能由多张图片组成，比如gif、APNG等
    for (NSImageRep * imageRep in imageReps) {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    
    NSRect imageRect = NSMakeRect(0, 0, width, height);

    // 获取CGImageRef
    CGImageRef imageRef = [[[NSImage alloc] initWithData:data] CGImageForProposedRect:&imageRect context:nil hints:nil];

    // 判断图片是否有透明度通道
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = NO;
    if (alphaInfo == kCGImageAlphaFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaPremultipliedLast) {
        hasAlpha = YES;
    }

//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    // 位图信息
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    
    size_t bytesPerRow = 4 * width;
    _bitmapData = (uint32_t*)malloc(bytesPerRow * height);
    // 创建位图上下文
    CGContextRef contextRef = CGBitmapContextCreate(_bitmapData,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    bitmapInfo);
    
    //使用CGContextDrawImage解码图片时会带上一次解码的残影，即使是一个新的CGContext也会，需要在draw前clearRect
    CGContextClearRect(contextRef, imageRect);
    CGContextDrawImage(contextRef, imageRect, imageRef);  // decode
    CGImageRef newImage = CGBitmapContextCreateImage(contextRef);
    
    // release
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    _width = width;
    _height = height;
    _hasAlpha = hasAlpha;
    
    return newImage;
}

- (Color)getColorAtPoint:(NSPoint)point
{
    uint32_t *pixel = _bitmapData + (int)point.y * self.width + (int)point.x;
    uint32_t bgra = *pixel;

    Color c;
    c.A = (bgra & 0xff000000)>>24;
    c.R = (bgra & 0x00ff0000)>>16;
    c.G = (bgra & 0x0000ff00)>>8;
    c.B = (bgra & 0x000000ff)>>0;

    return c;
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    free(_bitmapData);
}

@end


#pragma mark - Helper

SMTImageType imageTypeDetectWithData(NSData* data)
{
    if (!data) {
        return SMTImageTypeUnknown;
    }
    
    const char *bytes = data.bytes;
    uint32_t magic4 = *((uint32_t*)bytes);
    switch (magic4) {
        case FOUR_CC(0x89, 'P', 'N', 'G'):{  // PNG
            uint32_t tmp = *((uint32_t*)(bytes+4));
            if (tmp == FOUR_CC(0x0D, 0x0A, 0x1A, 0x0A)) {
                return  SMTImageTypePNG;
            }
        }break;
            
        case FOUR_CC(0x49, 0x49, 0x2A, 0x00):{  // 小端tiff
            return SMTImageTypeTIFF;
        }break;
            
        case FOUR_CC(0x4D, 0x4D, 0x00, 0x2A):{  // 大端tiff
            return SMTImageTypeTIFF;
        }break;
            
        case FOUR_CC('R', 'I', 'F', 'F'):{  // webp
            uint32_t tmp = *((uint32_t*)(bytes+8));
            if (tmp == FOUR_CC('W', 'E', 'B', 'P')) {
                return  SMTImageTypeWEBP;
            }
        }break;
    }
    
    uint16_t magic2 = *((uint16_t*)bytes);
    switch (magic2) {
        case TWO_CC('B', 'M'):
        case TWO_CC('B', 'A'):
        case TWO_CC('C', 'I'):
        case TWO_CC('C', 'P'):
        case TWO_CC('I', 'C'):
        case TWO_CC('P', 'T'):{
            return SMTImageTypeBMP;    // bmp
        }break;
        
        case TWO_CC(0xFF, 0xD8):{
            uint8_t tmp = *((uint8_t*)(bytes+2));
            if (tmp == 0xFF) {
                return SMTImageTypeJPEG;   // JPEG
            }
        }
    }
    
    return SMTImageTypeUnknown;
}


