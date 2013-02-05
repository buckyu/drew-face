//
//  DrewFaceViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/4/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "DrewFaceViewController.h"

@interface DrewFaceViewController ()

@end

@implementation DrewFaceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


-(IBAction)LoadTestImageJPEGButtonPressed {
    
    // iOS UIImageView for debug and showing results on screen
    UIImageView *iv;
    
    // test input image in Documents Directory of iPhone
    NSString *testFileName = @"testimage.jpg";
    
    // load test input file and display on screen in UIImageView *iv
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *testFilePath = [docsDirectory stringByAppendingPathComponent:testFileName];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:testFilePath]) {
        UIImage *testimage = [UIImage imageWithContentsOfFile:testFilePath];
        iv = [[UIImageView alloc] initWithImage:testimage];
        CGFloat w = testimage.size.width;
        CGFloat h = testimage.size.height;
        CGFloat scaleDownfactor = (w>h)? 320.0/w : 320.0/h;
        iv.frame = CGRectMake(0, 100, w*scaleDownfactor, h*scaleDownfactor);
        [self.view addSubview:iv];
    } else {
        // exit, can not continue
        NSLog(@"%@ not in Documents Directory",testFileName);
        return;
    }
    
    
    
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
