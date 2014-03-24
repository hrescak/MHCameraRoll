MHCameraRoll
============

A wrapper somewhat simplifying work with camera roll on iOS, with the option of only loading screenshots, photos or both. Features handy accessors for thumbs, full images and count, and is ready for populating a UITableView or UICollectionView. The collection view example attached. also has a cache for thumbnails so images don't need to be loaded twice.

### Usage
Initialize a camera roll instance, set it's properties up and load it. . This can be done in a **ViewDidLoad:** method.
```Objective-C
- (void)viewDidLoad
{
    self.cameraRoll = [[MHCameraRoll alloc] init];
    self.cameraRoll.fileTypes = MHCameraRollFileTypesAll; //load both photos and screenshots
    self.cameraRoll.thumbScale = 0.33; //make scale to be a third of the screen
    
    [self.cameraRoll loadCameraRollWithSuccess:^{
        // camera roll has loaded images, this is a good place to call reloadData
        // on your table or collection view and hide view for unauthorized state
        // and reload collectionview's data.
    } unauthorized:^{
        // unauthorized state: access to camera roll was denied by the user so
        // we should show an unauthorized state with text explaining how to
        // re-authorize the app to use camera roll.
        self.unauthorizedView.alpha = 1;
    }];
   
		// do any other setup 
    [super viewDidLoad];
}
```

A handy count method to use in a table or collection view datasource methods:
```Objective-C
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.cameraRoll imageCount];
}
```

thumbnail can become handy when constructing cells:
```Objective-C
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionCell" forIndexPath:indexPath];
    [self.cameraRoll thumbAtIndex:indexPath.row completionHandler:^(UIImage *thumb) {
       // do something with the thumbnail, like add it to
       // an imageView in the cell 
    }];
    return cell;
}
```

the full image accessor can be handy when you're ready to manipulate the full scale image
```Objective-C
[self.cameraRoll imageAtIndex:indexPath.row completionHandler:^(UIImage *image) {
        // do something with the full scale image, like upload 
        // it to the server.
    }];
```
