//
//  SMTImageViewController.h
//  FirstMacApp
//
//  Created by sunmengtuo on 2021/8/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM (NSUInteger, ResizeImageOption){
	ResizeImageOptionZoomIn = 0,
	ResizeImageOptionZoomOut,
};

@interface SMTImageViewController : NSViewController

- (instancetype)initWithImagePath:(NSString*)imagePath;

- (void)resizeImageWithOption:(ResizeImageOption)option;

@end

NS_ASSUME_NONNULL_END
