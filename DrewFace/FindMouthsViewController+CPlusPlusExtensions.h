//
//  FindMouthsViewController+CPlusPlusExtensions.h
//  DrewFace
//
//  Created by Drew Crawford on 4/2/13.
//  Copyright (c) 2013 FCW Consulting LLC. All rights reserved.
//

#import "FindMouthsViewController.h"

/**Don't ask too many questions about why this code is structured this way.  it has to do with writing the minimal viable C++. */
@interface FindMouthsViewController (CPlusPlusExtensions)
-(UIImage *)lookForTeethInMouthImage:(UIImage*)mouthImage;
@end
