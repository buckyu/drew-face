//
//  ShowMouthsViewController.m
//  DrewFace
//
//  Created by FCW Consulting LLC on 2/19/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#define TABLEVIEW_CELL_HEIGHT 100

#import "ShowMouthsViewController.h"

@interface ShowMouthsViewController ()

@end

@implementation ShowMouthsViewController

@synthesize tableview;
@synthesize backButton;
@synthesize activity;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // data source for tableview
        fileInfos = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    backButton.enabled = NO;
    
    // directory and file IO stuff
    manager = [NSFileManager defaultManager];
    docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    extractedMouthsDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS"];
    
    [activity startAnimating];
    self.tableview.hidden = YES;
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
    
}



-(void)loadTableView {
    @autoreleasepool {
        
        NSArray *fileList;
        fileList = [manager contentsOfDirectoryAtPath:extractedMouthsDir error:NULL];
        
        for (int i=0; i < fileList.count; i++) {
            NSString *fileName = [fileList objectAtIndex:i];
            NSString *fileNamePath = [extractedMouthsDir stringByAppendingPathComponent:fileName];
            
            NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             fileName,@"mouthFileName",
                                             fileNamePath,@"mouthFilePathName",
                                             nil];
            [fileInfos addObject:fileInfo];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
        self.tableview.hidden = NO;
        [activity stopAnimating];
        backButton.enabled = YES;
    });
    
}



-(IBAction)backButtonPressed {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
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
        return TABLEVIEW_CELL_HEIGHT;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.adjustsFontSizeToFitWidth  = YES;
    }
    
    if (fileInfos.count == 0) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"No Teeth Images To Display";
        cell.detailTextLabel.text = nil;
    } else {
        NSDictionary *fileInfo = [fileInfos objectAtIndex:indexPath.row];
        
        cell.imageView.image = [UIImage imageWithContentsOfFile:[fileInfo objectForKey:@"mouthFilePathName"]];
        int w = cell.imageView.image.size.width;
        int h = cell.imageView.image.size.height;
        cell.textLabel.text = [fileInfo objectForKey:@"mouthFileName"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d x %d",w,h];
    }
    
    return cell;
}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
