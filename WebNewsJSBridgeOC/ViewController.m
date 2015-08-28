//
//  ViewController.m
//  WebNewsJSBridgeOC
//
//  Created by Ronaldinho on 15/8/20.
//  Copyright (c) 2015年 HotWordLand. All rights reserved.
//

#import "ViewController.h"
#import "SDWebImageManager.h"
#import "WebViewJavascriptBridge.h"
#import "NSString+Separate.h"
#import "ViewImageVC.h"
#import "KYPhotoGallery.h"
#import "UIImageView+WebCache.h"
@interface ViewController ()<UIWebViewDelegate>
{
    NSMutableArray *allImagesOfThisArticle;
    NSMutableArray *imgUrls;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property WebViewJavascriptBridge* bridge;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /****** 加载html文件 ******/
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    NSString *content = [appHtml stringByReplacingOccurrencesOfString:@"img src" withString:@"img esrc"];
    /******  ******/

    /****** 正则替换img src 成 img esrc 让网页的图片不加载出来******/
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<img[^>]+esrc=\")(\\S+)\"" options:0 error:nil];
 
    NSString *result = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"<img esrc=\"$2\" onClick=\"javascript:onImageClick('$2')\""];
    /****** ******/

    [self.webView loadHTMLString:result baseURL:baseURL];
    
    /****** 加载桥梁对象 ******/
    [WebViewJavascriptBridge enableLogging];
    /******  ******/

    /****** 初始化 ******/
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        /****** js端逻辑 页面加载完成捕获完src里的链接 就通知OC进行图片下载******/
        [self downloadAllImagesInNative:data];
        /****** ******/
        responseCallback(@"Response for message from ObjC");
    }];
    /****** ******/

    /****** OC端注册一个方法 (测试)******/
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    /****** ******/

    /****** JS端得到当前DOM元素点击到了就通知OC ******/
  [_bridge registerHandler:@"imageDidClicked" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSInteger index = [[data objectForKey:@"index"] integerValue];
        NSInteger originX = [[data objectForKey:@"x"] floatValue];
        NSInteger originY = [[data objectForKey:@"y"] floatValue] + 64;
        NSInteger width = [[data objectForKey:@"width"] floatValue];
        NSInteger height = [[data objectForKey:@"height"] floatValue];
        UIImageView *tappedImageView = [[UIImageView alloc]init];
        [tappedImageView sd_setImageWithURL:[NSURL URLWithString:imgUrls[index]]];
        [tappedImageView setFrame:CGRectMake(originX, originY, width, height)];
        /**** 用一个白块遮住底层****/
        UIView *bgWhite = [[UIView alloc]initWithFrame:tappedImageView.frame];
        [bgWhite setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:bgWhite];
        /**** ****/
        [self.view addSubview:tappedImageView];
        KYPhotoGallery *mainPhotoGallery = [[KYPhotoGallery alloc]initWithTappedImageView:tappedImageView andImageUrls:[[NSMutableArray alloc] initWithArray:@[imgUrls[index]]] andInitialIndex:1 dismissBlock:^{
            //完成后移除
            [tappedImageView removeFromSuperview];
            [bgWhite removeFromSuperview];
        }];
        mainPhotoGallery.imageViewArray = [[NSMutableArray alloc]initWithArray:@[tappedImageView]];
        [self presentViewController:mainPhotoGallery animated:NO completion:nil];
         }];
    /****** ******/

}

#pragma mark -- 下载全部图片
-(void)downloadAllImagesInNative:(NSArray *)imageUrls{
    imgUrls = imageUrls;
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    //初始化一个置空元素数组
    if (!allImagesOfThisArticle) {
        allImagesOfThisArticle = [[NSMutableArray alloc]init];//本地的一个用于保存所有图片的数组
    }
    
    for (NSUInteger i = 0; i < imageUrls.count; i++) {
        NSString *_url = imageUrls[i];
        [manager downloadImageWithURL:[NSURL URLWithString:_url] options:SDWebImageHighPriority progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (image) {
                [allImagesOfThisArticle addObject:image];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *imgB64 = [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                    //把图片在磁盘中的地址传回给JS
                    NSString *key = [manager cacheKeyForURL:imageURL];
                    NSString *source = [NSString stringWithFormat:@"data:image/png;base64,%@", imgB64];
                    [_bridge callHandler:@"imagesDownloadComplete" data:@[key,source]];
                });
            }
        }];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
