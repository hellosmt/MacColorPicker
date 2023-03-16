//
//  SMTImageViewController.m
//  FirstMacApp
//
//  Created by sunmengtuo on 2021/8/22.
//

#import "SMTImageViewController.h"
#import "SMTImageDecoder.h"
#import "CenteringClipView.h"

#define ImageResizeIncrements 1.3
#define ScrollViewInitialWidth 800.0
#define ScrollViewInitialHeight 400.0

#define MYMINIMUMWIDTH 10
#define MYMINIMUMHEIGHT 10

@interface SMTImageViewController ()

@property(nonatomic, strong) NSImageView *imageView;
@property(nonatomic, copy) NSString *imagePath;
@property(nonatomic, strong) NSImage *decodedImage;
@property(nonatomic, assign) CGFloat scale;
@property(nonatomic, strong) NSScrollView *scrollView;
@property(nonatomic) CGImageRef decodedImageRef;
@property(nonatomic, strong)SMTImageDecoder *decoder;
@property(nonatomic, strong)NSTrackingArea *trackingArea;

@end

@implementation SMTImageViewController

# pragma mark - init

- (instancetype)initWithImagePath:(NSString*)imagePath
{
	self = [super init];
	if (self) {
		NSLog(@"%@", imagePath);
		self.imagePath = imagePath;
        self.scale = 1;
	}
	return self;
}

// ViewController默认从xib文件加载view，但是没有提供对应的xib文件，要自己创建view对象
- (void)loadView
{
	self.view = self.scrollView;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self decodeImage];
    [self setupSubviews];
	[self configTrackingArea];
}

- (void)decodeImage
{
	NSData *data = [NSData dataWithContentsOfFile:self.imagePath];
	if (data == nil) {
		NSLog(@"image nil");
	}
	self.decoder = [SMTImageDecoder decoderWithData:data scale:self.scale];
	self.decodedImageRef = [self.decoder decodeWithData:data];
	self.decodedImage = [[NSImage alloc]initWithCGImage:self.decodedImageRef size:NSZeroSize];
    self.decodedImage.cacheMode = NSImageCacheNever;  // 不写打开相同图片会显示上一次的结果
}

- (void)setupSubviews
{
    CGFloat widthScale = 1.0;
    CGFloat heightScale = 1.0;
    if (self.decodedImage.size.width > ScrollViewInitialWidth) {
        widthScale = ScrollViewInitialWidth / self.decodedImage.size.width;
    }
    if (self.decodedImage.size.height > ScrollViewInitialHeight) {
        heightScale = ScrollViewInitialHeight / self.decodedImage.size.height;
    }
    CGFloat scale = widthScale < heightScale ? widthScale : heightScale;
    if (scale == 1.0) {
        self.imageView.image = self.decodedImage;
        [self.imageView setFrame:NSMakeRect(0,0, self.decodedImage.size.width, self.decodedImage.size.height)];
    }else{
        [self displayImageWithScale:scale];
    }
    self.scale = scale;
}

#pragma mark - NSTrackingArea & Mouse Event

- (void)mouseMoved:(NSEvent *)event
{
	// 鼠标在window坐标系里的位置
	NSPoint eventLocation = event.locationInWindow;

	// 换算成ImageView里面的位置
	NSPoint imageViewLocation = [self.imageView convertPoint:eventLocation fromView:nil];

	// y翻转一下
	NSPoint tmpLocation = NSMakePoint(imageViewLocation.x, self.imageView.frame.size.height-imageViewLocation.y-1);
    
    NSPoint pixelLocation = NSMakePoint(tmpLocation.x / self.scale, tmpLocation.y / self.scale);

	if (pixelLocation.x >= 0 && pixelLocation.y >= 0 && pixelLocation.x < self.decoder.width && pixelLocation.y < self.decoder.height) {
		// 获取像素点的RGBA值
        Color c = [_decoder getColorAtPoint:pixelLocation];

		uint8_t red = c.R;
		uint8_t green = c.G;
		uint8_t blue = c.B;
		uint8_t alpha = c.A;
		// alpha预乘
		if (_decoder.hasAlpha && alpha != 0) {
			red = (red * 255) / c.A;
			green = (green * 255) / c.A;
			blue = (blue * 255) / c.A;
		}
		NSString *pixelInfo = [NSString stringWithFormat:@"坐标:(%d,%d), R:%d, G:%d, B:%d",(int)pixelLocation.x,(int)pixelLocation.y, red, green, blue];
		if (_decoder.hasAlpha) {
			pixelInfo = [pixelInfo stringByAppendingFormat:@", A:%d", alpha];
		}
		[self.view.window setTitle:pixelInfo];
	}
}

- (void)configTrackingArea
{
    if (self.trackingArea && self.imageView) {
        [self.imageView removeTrackingArea:self.trackingArea];
    }
	self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.imageView.bounds options:NSTrackingActiveInActiveApp | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited owner:self userInfo:NULL];

	[self.imageView addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
//	NSLog(@"%s", __func__);
}

- (void)mouseExited:(NSEvent *)event
{
//    NSLog(@"%s", __func__);
	[self.view.window setTitle:self.imagePath];
}

# pragma mark - Pinch Gesture Event

- (void)magnifyWithEvent:(NSEvent *)event
{
    self.scale = self.scale + event.magnification;
    [self displayImageWithScale:self.scale];
}

#pragma mark - resize image

- (void)resizeImageWithOption:(ResizeImageOption)option
{
    switch (option) {
        case ResizeImageOptionZoomIn:{
            self.scale = self.scale * ImageResizeIncrements;
        }
            break;
            
        case ResizeImageOptionZoomOut:
            self.scale = self.scale / ImageResizeIncrements;
            break;
    }
    
    [self displayImageWithScale:self.scale];
}

- (void)displayImageWithScale:(CGFloat)scale
{
    if (scale <= 0 || self.decodedImage.size.width * scale < MYMINIMUMWIDTH || self.decodedImage.size.height * scale < MYMINIMUMHEIGHT) {
        return;
    }
    NSLog(@"=======%f=======", scale);
    NSSize newSize = NSMakeSize(round(self.decodedImage.size.width * scale), round(self.decodedImage.size.height * scale));
    NSImage *image = [[NSImage alloc]initWithCGImage:self.decodedImageRef size:newSize];
    self.imageView.image = image;
    [self.imageView setFrame:NSMakeRect(0,0, image.size.width, image.size.height)];
    [self configTrackingArea];
}

# pragma mark - getters

- (NSImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[NSImageView alloc] init];
        _imageView.imageScaling = NSImageScaleNone;
    }
    return _imageView;
}

- (NSScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, ScrollViewInitialWidth, ScrollViewInitialHeight)];
        [_scrollView setContentView:[[CenteringClipView alloc] init]];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:YES];
        [_scrollView setBorderType:NSNoBorder];
        [_scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_scrollView setDocumentView:self.imageView];
        [_scrollView setBackgroundColor:[NSColor grayColor]];
        [_scrollView setAutohidesScrollers:YES];
        [_scrollView setScrollerStyle:NSScrollerStyleOverlay];
    }
    return _scrollView;
}

# pragma mark - lifecycle

- (void)dealloc
{
    if (self.decodedImageRef) {
        CFRelease(self.decodedImageRef);
    }
}

@end



