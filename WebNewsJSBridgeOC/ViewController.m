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
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    NSString *content = [appHtml stringByReplacingOccurrencesOfString:@"img src" withString:@"img esrc"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<img[^>]+esrc=\")(\\S+)\"" options:0 error:nil];
    //<!--separateStart-->
    NSRegularExpression *regexSeparate = [NSRegularExpression regularExpressionWithPattern:@"(\\s)*(<div class=\"col-xs-12 col-md-12 content\" style=\"margin-top: 10px\">)([\\s\\S])*(</div>)(\\s)*(</div>)(\\s)*(</div>)" options:0 error:nil];
    NSArray *matchStrings = [regexSeparate matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    if (matchStrings.count != 0)
    {
        for (NSTextCheckingResult *matc in matchStrings)
        {
            NSRange range = [matc range];
            NSLog(@"%lu,%lu,%@",(unsigned long)range.location,(unsigned long)range.length,[content substringWithRange:range]);
        }  
    }

    NSString *result = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"<img esrc=\"$2\" onClick=\"javascript:onImageClick('$2')\""];
    
    [self.webView loadHTMLString:result baseURL:baseURL];
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        [self downloadAllImagesInNative:data];
        responseCallback(@"Response for message from ObjC");
    }];
    
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
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
