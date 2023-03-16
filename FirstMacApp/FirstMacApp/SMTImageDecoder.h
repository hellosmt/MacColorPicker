//
//  SMTImageDecoder.h
//  FirstMacApp
//
//  Created by sunmengtuo on 2021/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 图片类型
typedef NS_ENUM (NSUInteger, SMTImageType){
	SMTImageTypeUnknown = 0,
	SMTImageTypePNG,
    SMTImageTypeTIFF,
	SMTImageTypeJPEG,
	SMTImageTypeBMP,
    SMTImageTypeWEBP,
};

typedef struct {
    uint8_t A;
    uint8_t R;
    uint8_t G;
    uint8_t B;
}Color;

@interface SMTImageDecoder : NSObject

@property(nonatomic, assign, readonly)BOOL hasAlpha;
@property(nonatomic, assign, readonly)NSUInteger width;
@property(nonatomic, assign, readonly)NSUInteger height;

+ (instancetype)decoderWithData:(NSData*)data scale:(CGFloat)scale;

- (CGImageRef)decodeWithData:(NSData*)data;

- (Color)getColorAtPoint:(NSPoint)point;

@end


#pragma mark - Helper

SMTImageType imageTypeDetectWithData(NSData* data);

NS_ASSUME_NONNULL_END
