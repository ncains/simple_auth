//
//  WebAuthenticatorViewController.m
//  Runner
//
//  Created by James Clancey on 6/6/18.
//  Copyright © 2018 The Chromium Authors. All rights reserved.
//

#import "WebAuthenticatorViewController.h"
#import "WebAuthenticator.h"

@implementation WebAuthenticatorViewController
UIWebView *webview;
UIActivityIndicatorView *activity;

-(id)initWithAuthenticator:(WebAuthenticator *)authenticator
{
    self = [super init];
    NSLog(@"webauthenticator init");
    if (self) {
        self.authenticator = authenticator;
        NSLog(@"set authenticator");
        if(authenticator.title != nil){
            self.title = authenticator.title;
        }
        NSLog(@"set title");
        if(self.authenticator.allowsCancel)
        {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
        }
        __weak typeof(self) weakSelf = self;
        self.authenticator.onTokenFound = ^(){
            [webview stopLoading];
            weakSelf.dismiss();
        };
        NSLog(@"set ontokenFound");
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        NSLog(@"setup activity");
        UIBarButtonItem *refreshButton =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        UIBarButtonItem *activityButton =[[UIBarButtonItem alloc] initWithCustomView:activity];
        NSLog(@"setting nav buttons");
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:refreshButton, activityButton, nil];
        NSLog(@"set nav buttons");
    }
    NSLog(@"webauthenticator init complete");
    return self;
}

- (void) viewDidLoad{
    NSLog(@"webauthenticator view did load");
    self.view.backgroundColor = UIColor.blackColor;
    webview = [[UIWebView alloc] init];
    webview.delegate = self;
    [self.view addSubview:webview];
}
-(void)viewDidAppear:(BOOL)animated{
    [webview loadRequest:[NSURLRequest requestWithURL:self.authenticator.initialUrl]];
}

-(void) viewDidLayoutSubviews{
    webview.frame = self.view.bounds;
}

-(void)cancel
{
    NSLog(@"Canceled");
    [self.authenticator cancel];
}
-(void)refresh {
    [webview reload];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if(!self.authenticator.isCompleted){
        [self.authenticator checkUrl:request.URL forceComplete:NO];
    }
    return true;
}
-(void)webViewDidStartLoad:(UIWebView *)webView{
    [activity startAnimating];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [activity stopAnimating];
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [activity stopAnimating];
}

@end
