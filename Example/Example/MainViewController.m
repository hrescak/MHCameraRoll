//
//  MainViewController.m
//  Example
//
//  Created by Matej Hrescak on 3/23/14.
//  Copyright (c) 2014 hrescak. All rights reserved.
//

#import "MainViewController.h"
#import "MHCameraRoll.h"

@interface MainViewController ()
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIView *unauthorizedView;
@property (nonatomic, strong) MHCameraRoll *cameraRoll;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.cameraRoll = [[MHCameraRoll alloc] init];
    self.cameraRoll.fileTypes = MHCameraRollFileTypesAll; //don't filter by type
    self.cameraRoll.thumbScale = 0.33; //make scale to be a third of the screen
    
    [self.cameraRoll loadCameraRollWithSuccess:^{
        // camera roll has loaded images, this is a good place to call reloadData
        // on your table or collection view and hide view for unauthorized state
        // and reload collectionview's data.
        self.unauthorizedView.alpha = 0;
        [self.collectionView reloadData];
    } unauthorized:^{
        // unauthorized state: access to camera roll was denied by the user so
        // we should show an unauthorized state with text explaining how to
        // re-authorize the app to use camera roll.
        self.unauthorizedView.alpha = 1;
    }];
    
    UINib *nib = [UINib nibWithNibName:@"CollectionCell" bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"collectionCell"];
    self.collectionView.dataSource = self;
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.cameraRoll imageCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
    [self.cameraRoll thumbAtIndex:indexPath.row completionHandler:^(UIImage *thumb) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:thumb];
        imageView.frame = CGRectMake(0,0,cell.frame.size.width, cell.frame.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell.contentView addSubview:imageView];
    }];
    return cell;
}
@end
