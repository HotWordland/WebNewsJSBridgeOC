//
//  ViewImageVC.m
//  WebNewsJSBridgeOC
//
//  Created by Ronaldinho on 15/8/21.
//  Copyright (c) 2015年 HotWordLand. All rights reserved.
//
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import "ViewImageVC.h"

@interface ViewImageVC ()<UIScrollViewDelegate>
{
    UIViewController *_applicationTopViewController;
    int _previousModalPresentationStyle;
    UIImageView *imageView;
    UIScrollView *scrollview;
}
@end

@implementation ViewImageVC
-(instancetype)initWithImageView:(UIImageView *)imParam
{
    self = [super init];
    if (self) {
        imageView = imParam;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            
            self.modalPresentationStyle = UIModalPresentationCustom;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            self.modalPresentationCapturesStatusBarAppearance = YES;
            
        }else{
            _applicationTopViewController = [self topviewController];
            _previousModalPresentationStyle = _applicationTopViewController.modalPresentationStyle;
            _applicationTopViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        }
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}
#pragma Helper method
- (UIViewController *)topviewController
{
    UIViewController *topviewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topviewController.presentedViewController) {
        topviewController = topviewController.presentedViewController;
    }
    
    return topviewController;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    scrollview = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [scrollview setPagingEnabled:YES];
    [scrollview setContentSize:CGSizeMake(self.view.bounds.size.width * 2, self.view.bounds.size.height)];
    [self.view addSubview:scrollview];
    UIScrollView *contentOne = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [contentOne setDelegate:self];
    [contentOne addSubview:imageView];
    [contentOne setMaximumZoomScale:4.0];
    UIImageView *imContentTwo = [[UIImageView alloc]initWithImage:imageView.image];
    UIScrollView *contentTwo = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [imContentTwo setCenter:self.view.center];
    [contentTwo addSubview:imContentTwo];
    [scrollview addSubview:contentOne];
    [contentTwo setCenter:CGPointMake(self.view.bounds.size.width + self.view.center.x, self.view.center.y)];
    [scrollview addSubview:contentTwo];

}
#pragma UISrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return imageView;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:1 initialSpringVelocity:7 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [imageView setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
        [imageView setCenter:self.view.center];
    } completion:^(BOOL finished) {
    }];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
