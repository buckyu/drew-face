//
//  FindMouthsViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/15/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FindMouthsViewController.h"

@interface FindMouthsViewController ()

@end

@implementation FindMouthsViewController

@synthesize tableview;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // data source for tableview
        fileInfos = [NSMutableArray new];
        
        // directory and file IO stuff
        manager = [NSFileManager defaultManager];
        docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        originalDir = [docsDir stringByAppendingPathComponent:@"ORIGINAL"];
        extractedTeethDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_TEETH"];
        if (![manager fileExistsAtPath:extractedTeethDir]) {
            [manager createDirectoryAtPath:extractedTeethDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    progress = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 400, 280, 30)];
    progress.progress = 0.0;
    [self.view addSubview:progress];
    
    activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(135, 200, 50, 50)];
    activity.hidesWhenStopped = YES;
    activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [activity startAnimating];
    [self.view addSubview:activity];
    
    self.tableview.hidden = YES;
    
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
    
}

-(void)loadTableView {
    
    NSArray *fileList;
    fileList = [manager contentsOfDirectoryAtPath:originalDir error:NULL];
    
    
    for (int i=0; i < fileList.count; i++) {
        
        NSString *fileName = [fileList objectAtIndex:i];
        NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         fileName,@"originalFileName",
                                         nil];
        [fileInfos addObject:fileInfo];
        
        // Process originals for mouths here
        usleep(100000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            progress.progress = (float)(i+1)/(float)fileList.count;
        });
        
    }

    // reload tableview with created data model
    usleep(100000);
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
        self.tableview.hidden = NO;
        [activity stopAnimating];
        progress.hidden = YES;
    });
    
}







- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (fileInfos.count > 0) {
        return fileInfos.count;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (fileInfos.count == 0) {
        return 568;
    } else {
        return 100;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];
    
    if (fileInfos.count == 0) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"No Teeth Images To Display";
        cell.detailTextLabel.text = nil;
    } else {
        cell.imageView.image = [UIImage imageWithContentsOfFile:[originalDir stringByAppendingPathComponent:[fileInfo objectForKey:@"originalFileName"]]];
        cell.textLabel.text = [fileInfo objectForKey:@"originalFileName"];
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
