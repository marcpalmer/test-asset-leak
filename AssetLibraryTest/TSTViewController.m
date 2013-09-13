//
//  TSTViewController.m
//  AssetLibraryTest
//
//  Created by Marc Palmer on 13/09/2013.
//  Copyright (c) 2013 AnyWare. All rights reserved.
//

@import AssetsLibrary;

#import <mach/mach.h>
#import "TSTViewController.h"

void report_memory(void) {
    static unsigned last_resident_size=0;
    static unsigned greatest = 0;
    static unsigned last_greatest = 0;

    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                               TASK_BASIC_INFO,
                               (task_info_t)&info,
                               &size);
    if( kerr == KERN_SUCCESS ) {
        int diff = (int)info.resident_size - (int)last_resident_size;
        unsigned latest = info.resident_size;
        if( latest > greatest   )   greatest = latest;  // track greatest mem usage
        int greatest_diff = greatest - last_greatest;
        int latest_greatest_diff = latest - greatest;
        NSLog(@"Mem: %10u (%10d) : %10d :   greatest: %10u (%d)", info.resident_size, diff,
          latest_greatest_diff,
          greatest, greatest_diff  );
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
    last_resident_size = info.resident_size;
    last_greatest = greatest;
}

@interface TSTViewController ()
- (IBAction)performScan:(id)sender;

@end

@implementation TSTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)loadSomeImages {
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    NSLog(@"Memory stats before accessing assets");
    report_memory();
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group) {
            return;
        }
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];

        NSInteger oldestPhotoIndex = MAX(0, group.numberOfAssets-5);
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(oldestPhotoIndex, group.numberOfAssets-oldestPhotoIndex)];

        @autoreleasepool {
            [group enumerateAssetsAtIndexes:indexes options:0 usingBlock:^(ALAsset *foundAsset, NSUInteger index, BOOL *innerstop) {
                if (!foundAsset) {
                    return;
                }
                
                NSDate *assetDate = [foundAsset valueForProperty:ALAssetPropertyDate];
                @autoreleasepool {
                    NSLog(@"Checking photo taken on %@", assetDate);
                    #warning we are about to leak approx 30MB
                    CGImageRef fullResolutionImage = CGImageRetain(foundAsset.defaultRepresentation.fullResolutionImage);
                    NSLog(@"Got image of photo taken on %@", assetDate);
                    
                    // do something
                    
                    CGImageRelease(fullResolutionImage);
                }
            }];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Memory stats after accessing assets");
            report_memory();
        });

    } failureBlock:^(NSError *error) {
        NSLog(@"Oops %@", error);
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performScan:(id)sender {
    [self loadSomeImages];
}
@end
