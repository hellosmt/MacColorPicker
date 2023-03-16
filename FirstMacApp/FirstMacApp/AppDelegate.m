//
//  AppDelegate.m
//  TestProject
//
//  Created by sunmengtuo on 2021/8/20.
//

#import "AppDelegate.h"
#import "SMTImageViewController.h"
#import "SMTImageWindow.h"
#import "SMTImageDecoder.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 不显示窗口的tabbar
    [NSWindow setAllowsAutomaticWindowTabbing:NO];
    [self displayOpenPanel];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

# pragma mark - NSMenu

- (IBAction)openFileClicked:(id)sender {
    [self displayOpenPanel];
}

- (void)displayOpenPanel
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSArray *fileTypes = @[@"jpg", @"JPEG", @"jpe", @"png", @"tif", @"tiff", @"bmp", @"webp"]; // 支持打开的文件类型
    
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    [panel setAllowedFileTypes:fileTypes];
    
    NSInteger result = [panel runModal];
    if (result == NSModalResponseOK) {
        NSURL *fileURL = [panel URL];
        NSString* filePath = [fileURL path];
         // 判断文件类型
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        SMTImageType imageType = imageTypeDetectWithData(data);
        if (imageType == SMTImageTypeUnknown) {
            NSAlert *alert = [[NSAlert alloc]init];
            alert.alertStyle = NSAlertStyleInformational;
            [alert addButtonWithTitle:@"关闭"];
            alert.messageText = @"不支持此类文件，换个试试吧！";
            [alert runModal];
        }else{
            // 打开图片
            [self openPictureWithFilePath:filePath];
        }
    }
}

- (void)openPictureWithFilePath:(NSString*)filePath
{
    SMTImageWindow *window = [[SMTImageWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:YES];
    window.delegate = self;
    // 将该窗口放入应用的窗口列表
    [window makeKeyAndOrderFront:nil];
    SMTImageViewController *viewController = [[SMTImageViewController alloc] initWithImagePath:filePath];
    window.contentViewController = viewController;
    [self setupTitlebarAccessoryViewOnWindow:window];
    [window center];
}

- (void)setupTitlebarAccessoryViewOnWindow:(NSWindow*)window
{
    NSButton *zoomInButton =[NSButton buttonWithImage:[NSImage imageNamed:@"zoom-in-2"] target:self action:@selector(zoomInClicked:)];
    zoomInButton.imageScaling = NSImageScaleProportionallyDown;
    zoomInButton.imagePosition = NSImageOnly;
    zoomInButton.showsBorderOnlyWhileMouseInside = YES;
    zoomInButton.toolTip = @"放大图片";
    
    NSButton *zoomOutButton =[NSButton buttonWithImage:[NSImage imageNamed:@"zoom-out-2"] target:self action:@selector(zoomOutClicked:)];
    zoomOutButton.imageScaling = NSImageScaleProportionallyDown;
    zoomOutButton.imagePosition = NSImageOnly;
    zoomOutButton.showsBorderOnlyWhileMouseInside = YES;
    zoomOutButton.toolTip = @"缩小图片";
    
    NSStackView *stackView = [[NSStackView alloc]initWithFrame:NSMakeRect(0, 0, 100, 100)];
    [stackView addArrangedSubview:zoomInButton];
    [stackView addArrangedSubview:zoomOutButton];
    stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    stackView.spacing = 10;
    
    NSTitlebarAccessoryViewController *vc = [[NSTitlebarAccessoryViewController alloc]init];
    vc.view = stackView;
    vc.layoutAttribute = NSLayoutAttributeRight;

    [window addTitlebarAccessoryViewController:vc];
}

- (IBAction)zoomInClicked:(id)sender {
    SMTImageViewController* viewController = (SMTImageViewController*)[[NSApplication sharedApplication] mainWindow].contentViewController;
    [viewController resizeImageWithOption:ResizeImageOptionZoomIn];
}

- (IBAction)zoomOutClicked:(id)sender {
    SMTImageViewController* viewController = (SMTImageViewController*)[[NSApplication sharedApplication] mainWindow].contentViewController;
    [viewController resizeImageWithOption:ResizeImageOptionZoomOut];
}

# pragma mark - NSWindow delegate

- (BOOL)windowShouldClose:(NSWindow *)sender
{
    // 不销毁窗口，隐藏窗口
    // 将窗口移除显示队列，仍然能够保证左上角菜单栏存在
    // 这里打印了dealloc？？？
    [sender orderOut:self];
    return NO;
}


@end
