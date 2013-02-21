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
@synthesize navbar;
@synthesize backButton;
@synthesize activity;
@synthesize toggleListButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // data source for tableview
        //fileInfos = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    backButton.enabled = NO;
    toggleListButton.enabled = NO;
    ShowMouthsBool = YES;
    ShowEdgesBool = NO;
    
    // directory and file IO stuff
    manager = [NSFileManager defaultManager];
    docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    extractedMouthsDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS"];
    extractedMouthsEdgesDir = [docsDir stringByAppendingPathComponent:@"EXTRACTED_MOUTHS_EDGES"];
    
    [activity startAnimating];
    self.tableview.hidden = YES;
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
    
}



-(void)loadTableView {
    
    // data source for tableview
    fileInfos = [NSMutableArray new];

    @autoreleasepool {
        
        NSArray *fileList;
        
        fileList = nil;
        if (ShowMouthsBool) {
            fileList = [manager contentsOfDirectoryAtPath:extractedMouthsDir error:NULL];
        }
        
        for (int i=0; i < fileList.count; i++) {
            NSString *fileName = [fileList objectAtIndex:i];
            NSString *fileNamePath = [extractedMouthsDir stringByAppendingPathComponent:fileName];
            
            NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             fileName,@"fileName",
                                             fileNamePath,@"filePathName",
                                             nil];
            [fileInfos addObject:fileInfo];
        }
        
        fileList = nil;
        if (ShowEdgesBool) {
            fileList = [manager contentsOfDirectoryAtPath:extractedMouthsEdgesDir error:NULL];
        }
        
        for (int i=0; i < fileList.count; i++) {
            NSString *fileName = [fileList objectAtIndex:i];
            NSString *fileNamePath = [extractedMouthsEdgesDir stringByAppendingPathComponent:fileName];
            
            NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             fileName,@"fileName",
                                             fileNamePath,@"filePathName",
                                             nil];
            [fileInfos addObject:fileInfo];
        }

        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
        self.tableview.hidden = NO;
        [activity stopAnimating];
        backButton.enabled = YES;
        toggleListButton.enabled = YES;
    });
    
}



-(IBAction)backButtonPressed {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}


-(IBAction)toggleListButtonPressed {
    backButton.enabled = NO;
    toggleListButton.enabled = NO;
    self.tableview.hidden = YES;
    [activity startAnimating];
    
    if ([toggleListButton.title isEqualToString:@"Mouths"]) {
        self.navbar.topItem.title = @"Mouths";
        toggleListButton.title = @"Teeth";
        ShowMouthsBool = YES;
        ShowEdgesBool = NO;
    } else {
        toggleListButton.title = @"Mouths";
        self.navbar.topItem.title = @"Teeth";
        ShowMouthsBool = NO;
        ShowEdgesBool = YES;
    }
    
    [self performSelectorInBackground:@selector(loadTableView) withObject:nil];
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
        
        cell.imageView.image = [UIImage imageWithContentsOfFile:[fileInfo objectForKey:@"filePathName"]];
        int w = cell.imageView.image.size.width;
        int h = cell.imageView.image.size.height;
        cell.textLabel.text = [fileInfo objectForKey:@"fileName"];
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
