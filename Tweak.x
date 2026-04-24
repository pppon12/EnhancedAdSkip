//
//  EnhancedAdSkip - 增强版广告跳过
//  支持: AVPlayer, WKWebView, UIWebView, 穿山甲SDK, 广点通SDK
//

#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// ============ 工具函数 ============

// 交换实例方法
void instanceSwap(Class targetClass, SEL originalSel, SEL newSel) {
    Method originalMethod = class_getInstanceMethod(targetClass, originalSel);
    Method newMethod = class_getInstanceMethod(targetClass, newSel);
    if (originalMethod && newMethod) {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

// 交换类方法
void classSwap(Class targetClass, SEL originalSel, SEL newSel) {
    Method originalMethod = class_getClassMethod(targetClass, originalSel);
    Method newMethod = class_getClassMethod(targetClass, newSel);
    if (originalMethod && newMethod) {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

// ============ AVPlayer Hook ============

%hook AVPlayer

+ (void)load {
    %orig;
    NSLog(@"[YYYAD] AVPlayer load hooked");
    
    // 交换 play 方法
    instanceSwap([AVPlayer class], @selector(play), @selector(yyy_ad_play));
    
    // 交换 replaceCurrentItemWithPlayerItem
    instanceSwap([AVPlayer class], @selector(replaceCurrentItemWithPlayerItem:), @selector(yyy_replaceItem:));
}

// 替换 play 方法 - 跳过广告
- (void)yyy_ad_play {
    NSLog(@"[YYYAD] AVPlayer play called - speeding up");
    
    // 设置播放速度为2倍或更高
    self.rate = 2.0;
    
    // 调用原始 play
    [self yyy_ad_play];
}

// 替换 replaceCurrentItemWithPlayerItem
- (void)yyy_replaceItem:(id)playerItem {
    NSLog(@"[YYYAD] replaceCurrentItemWithPlayerItem called");
    %orig(playerItem);
}

%end

// ============ WKWebView Hook ============

%hook WKWebView

+ (void)load {
    %orig;
    NSLog(@"[YYYAD] WKWebView load hooked");
    
    // Hook evaluateJavaScript
    instanceSwap([WKWebView class], @selector(evaluateJavaScript:completionHandler:), @selector(yyy_evaluateJavaScript:completionHandler:));
}

// 拦截 JavaScript 广告检测
- (void)yyy_evaluateJavaScript:(NSString *)script completionHandler:(void (^)(id, NSError *))completionHandler {
    
    // 检测广告相关 JS
    if ([script containsString:@"ad"] || [script containsString:@"Ad"]) {
        NSLog(@"[YYYAD] Detected ad-related JS: %@", script);
        
        // 返回假数据绕过检测
        if (completionHandler) {
            completionHandler(@{@"isAd": @NO}, nil);
        }
        return;
    }
    
    [self yyy_evaluateJavaScript:script completionHandler:completionHandler];
}

%end

// ============ UIWebView Hook ============

%hook UIWebView

+ (void)load {
    %orig;
    NSLog(@"[YYYAD] UIWebView load hooked");
    
    // Hook stringByEvaluatingJavaScriptFromString
    instanceSwap([UIWebView class], @selector(stringByEvaluatingJavaScriptFromString:), @selector(yyy_evaluateJS:));
}

- (NSString *)yyy_evaluateJS:(NSString *)script {
    NSLog(@"[YYYAD] UIWebView JS: %@", script);
    
    // 绕过广告检测
    if ([script containsString:@"ad"]) {
        return @"false";
    }
    
    return [self yyy_evaluateJS:script];
}

%end

// ============ 穿山甲广告 SDK Hook ============

%hook BUVideoPlayer

+ (void)load {
    %orig;
    NSLog(@"[YYYAD] BUVideoPlayer found");
    
    // Hook play 方法
    instanceSwap(objc_getClass("BUVideoPlayer"), @selector(play), @selector(yyy_play));
}

- (void)yyy_play {
    NSLog(@"[YYYAD] BUVideoPlayer play - speeding up");
    self.rate = 2.0;
    %orig;
}

%end

// ============ 广点通广告 SDK Hook ============

%hook GDTNativeExpressVideoAd

+ (void)load {
    %orig;
    NSLog(@"[YYYAD] GDTNativeExpressVideoAd found");
    
    Class gdtVideo = objc_getClass("GDTNativeExpressVideoAd");
    if (gdtVideo) {
        instanceSwap(gdtVideo, @selector(play), @selector(yyy_gdt_play));
    }
}

- (void)yyy_gdt_play {
    NSLog(@"[YYYAD] GDT video play - speeding up");
    self.rate = 2.0;
    %orig;
}

%end

// ============ 跳过按钮自动点击 ============

@interface YYYAdSkipper : NSObject
@end

@implementation YYYAdSkipper

+ (void)start {
    // 定时检查跳过按钮
    [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
        [self clickSkipButton];
    }];
}

+ (void)clickSkipButton {
    // 遍历所有 window
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        [self findAndClickSkipButtonInView:window];
    }
}

+ (void)findAndClickSkipButtonInView:(UIView *)view {
    if (!view) return;
    
    // 检查是否是跳过按钮
    NSString *title = @"";
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        title = [btn titleForState:UIControlStateNormal] ?: @"";
    }
    
    // 常见跳过按钮文字
    NSArray *skipTexts = @[@"跳过", @"skip", @"SKIP", @"关闭", @"Close", @"X"];
    
    for (NSString *text in skipTexts) {
        if ([title containsString:text]) {
            NSLog(@"[YYYAD] Found skip button: %@", title);
            
            // 模拟点击
            [view touchesBegan:[NSSet set] withEvent:nil];
            [view touchesEnded:[NSSet set] withEvent:nil];
            
            NSLog(@"[YYYAD] Clicked skip button!");
            return;
        }
    }
    
    // 递归检查子视图
    for (UIView *subview in view.subviews) {
        [self findAndClickSkipButtonInView:subview];
    }
}

@end

// ============ 入口 ============

%ctor {
    NSLog(@"[YYYAD] Enhanced Ad Skipper loaded!");
    
    // 启动跳过按钮检测
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [YYYAdSkipper start];
    });
}
