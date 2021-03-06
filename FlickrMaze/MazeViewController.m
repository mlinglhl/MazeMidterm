//
//  MazeViewController.m
//  FlickrMaze
//
//  Created by Minhung Ling on 2017-02-03.
//  Copyright © 2017 Minhung Ling. All rights reserved.
//

#import "MazeViewController.h"
#import "GameManager.h"
#import "MazeCell.h"
#import "MazeTile+CoreDataClass.h"
#import "TitleCell.h"
#import "MapViewController.h"
#import "DetailViewController.h"
#import "EndGameViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MazeViewController ()

@property int rowCount;
@property int sectionCount;
@property (weak, nonatomic) IBOutlet UICollectionView *mazeCollectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetMovesLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *playerImage;
@property (nonatomic) AVAudioPlayer *backgroundPlayer;
@property (nonatomic) NSMutableArray *titles;
@property (nonatomic) NSTimer *timer;
@property GameManager *manager;
@property long tableInt;
@property NSArray *randomArray;

@end

@implementation MazeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [GameManager sharedManager];
    self.rowCount = 3;
    self.sectionCount = 3;
    self.tableInt = 0;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playerLoses) name:@"playerLoses" object:nil];
    [notificationCenter addObserver:self selector:@selector(playerWins) name:@"playerWins" object:nil];
    [notificationCenter addObserver:self selector:@selector(startGame) name:@"startGame" object:nil];
    [notificationCenter addObserver:self selector:@selector(ghostClose) name:@"ghostClose" object:nil];
    [notificationCenter addObserver:self selector:@selector(updateTimeLabel) name:@"playerTimeIncrement" object:nil];
    self.playerImage.image = [UIImage imageWithData:self.manager.player.image];
    [self.mazeCollectionView addSubview:self.playerImage];
    self.randomArray = [self randomize];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.tableInt = 0;
    self.movesLabel.text = [NSString stringWithFormat:@"Moves: %hd", self.manager.player.moveCount];
    self.targetMovesLabel.text = @"10";
    NSDataAsset *music = [self.manager getMusic];
    NSError *error;
    self.backgroundPlayer = [[AVAudioPlayer alloc] initWithData:music.data error:&error];
    if(error)
        NSLog(@"error");
    self.backgroundPlayer.numberOfLoops = -1;
    self.backgroundPlayer.volume = 0.5;
    [self.backgroundPlayer play];
}

-(void)viewDidLayoutSubviews{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.mazeCollectionView.collectionViewLayout;
    CGFloat width = self.mazeCollectionView.frame.size.width/3;
    CGSize size = CGSizeMake(width, width);
    layout.itemSize = size;
//    self.playerImage.center = self.mazeCollectionView.center;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.backgroundPlayer stop];
}

#pragma mark Collection View Data Source Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sectionCount;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.rowCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MazeCell *cell = (MazeCell *)[self.mazeCollectionView dequeueReusableCellWithReuseIdentifier:@"MazeCell" forIndexPath:indexPath];
    NSArray *array = [self.manager getArray];
    NSInteger section = self.manager.player.currentY + indexPath.section - 1;
    NSInteger row = self.manager.player.currentX +indexPath.row -1;
    if (section < 0 || row < 0 || section > 9 || row > 9) {
        cell.mazeCellImageView.image = [UIImage imageWithData:[self.manager getOutOfBoundsImage]];
        return cell;
    }
    NSArray *tileArray = array[section];
    MazeTile *tile = tileArray[row];
    NSData *data = tile.image;
    cell.mazeCellImageView.image = [UIImage imageWithData:data];
    return cell;
}

#pragma Table View Data Source Methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TitleCell *cell = (TitleCell *)[tableView dequeueReusableCellWithIdentifier:@"TitleCell" forIndexPath:indexPath];
    NSNumber *num = self.randomArray[self.tableInt];
    cell.tag = num.longValue;
    cell.title.text = [self cellTitle:cell.tag];//(long)self.randomArray[self.tableInt]];
    ++self.tableInt;
    return cell;
}

-(NSArray*)randomize{
    NSMutableArray *temp = [NSMutableArray new];
    int i = 0;
    while(i<=3){
        int num = arc4random_uniform(4)+1;
        if(![temp containsObject:@(num)]){
            [temp addObject: @(num)];
            ++i;
        }
    }
    return [temp copy];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSString*)cellTitle:(NSInteger)tag{
    NSArray *array = [self.manager getArray];
    Player *player = self.manager.player;
    NSArray  *tileArray;
    MazeTile *tile;
    switch (tag) {
        case 1:{
            if(player.currentY-1 < 0)
                return @"Out Of Bounds";
            tileArray = array[player.currentY-1];
            tile = tileArray[player.currentX];
            return tile.title;
            break;
        }
        case 2:{
            if(player.currentX-1 < 0)
                return @"Out Of Bounds";
            tileArray = array[player.currentY];
            tile = tileArray[player.currentX-1];
            return tile.title;
            break;
        }
        case 3:{
            if(player.currentX+1 > 9)
                return @"Out Of Bounds";
            tileArray = array[player.currentY];
            tile = tileArray[player.currentX+1];
            return tile.title;
            break;
        }
        case 4:{
            if(player.currentY+1 > 9)
                return @"Out Of Bounds";
            tileArray = array[player.currentY+1];
            tile = tileArray[player.currentX];
            return tile.title;
            break;
        }
        default:{
            tileArray = array[player.currentY];
            tile = tileArray[player.currentX];
            return tile.title;
            break;
        }
    }
}

#pragma mark Table View Delegate Method

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TitleCell *cell = (TitleCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self movePlayer:cell.tag];
    [self.tableView reloadData];
    self.manager.player.moveCount += 1;
    self.tableInt = 0;
    self.movesLabel.text = [NSString stringWithFormat:@"Moves: %d",self.manager.player.moveCount];
    [self.manager saveContext];
}

-(void)movePlayer:(long)tag{
    switch (tag) {
        case 1:{
            [self movePlayerUp];
            self.tableInt = 0;
            break;
        }
        case 2:{
            [self movePlayerLeft];
            self.tableInt = 0;
            break;
        }
        case 3:{
            [self movePlayerRight];
            self.tableInt = 0;
            break;
        }
        case 4:{
            [self movePlayerDown];
            self.tableInt = 0;
            break;
        }
        default:
            return;
    }
    
}

#pragma mark Player Timer Update

- (void) updateTimeLabel {
    self.timeLabel.text = @(self.manager.player.time).stringValue;
}

#pragma mark Movement Methods

- (IBAction)moveLeft:(UIButton *)sender {
    [self movePlayerLeft];
}

- (IBAction)moveRight:(UIButton *)sender {
    [self movePlayerRight];
}

- (IBAction)moveUp:(UIButton *)sender {
    [self movePlayerUp];
}

- (IBAction)moveDown:(UIButton *)sender {
    [self movePlayerDown];
}

-(void)movePlayerLeft{
    if ([self.manager movePlayerOnX: -1]) {
        self.rowCount -= 1;
        [self.mazeCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0],
                                                           [NSIndexPath indexPathForRow:2 inSection:1],
                                                           [NSIndexPath indexPathForRow:2 inSection:2]
                                                           ]];
        self.rowCount += 1;
        [self.mazeCollectionView insertItemsAtIndexPaths:@[
                                                           [NSIndexPath indexPathForRow:0 inSection:0],
                                                           [NSIndexPath indexPathForRow:0 inSection:1],
                                                           [NSIndexPath indexPathForRow:0 inSection:2]                                                       ]];
        self.randomArray = [self randomize];
    }
}

-(void)movePlayerRight{
    if ([self.manager movePlayerOnX: 1]) {
        self.rowCount -= 1;
        [self.mazeCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                           [NSIndexPath indexPathForRow:0 inSection:1],
                                                           [NSIndexPath indexPathForRow:0 inSection:2]
                                                           ]];
        self.rowCount += 1;
        [self.mazeCollectionView insertItemsAtIndexPaths:@[
                                                           [NSIndexPath indexPathForRow:2 inSection:0],
                                                           [NSIndexPath indexPathForRow:2 inSection:1],
                                                           [NSIndexPath indexPathForRow:2 inSection:2]                                                       ]];
        self.randomArray = [self randomize];
    }
}

-(void)movePlayerUp{
    if ([self.manager movePlayerOnY: -1]) {
        self.sectionCount += 1;
        [self.mazeCollectionView insertSections:[NSIndexSet indexSetWithIndex:0]];
        self.sectionCount -= 1;
        [self.mazeCollectionView deleteSections:[NSIndexSet indexSetWithIndex:3]];
        self.randomArray = [self randomize];
    }
}

-(void)movePlayerDown{
    if ([self.manager movePlayerOnY: 1]) {
        self.sectionCount += 1;
        [self.mazeCollectionView insertSections:[NSIndexSet indexSetWithIndex:3]];
        self.sectionCount -= 1;
        [self.mazeCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
        self.randomArray = [self randomize];
    }
}

#pragma mark Start Game

- (void) startGame {
    [self.manager startGame];
    [self.mazeCollectionView reloadData];
}

#pragma mark ghostClose
- (void) ghostClose {
    NSArray *tileArray = [self.manager getArray];
    MazeTile *tile = tileArray[self.manager.player.ghostY][self.manager.player.ghostX];
    NSData *tempStore = tile.image;
    NSData *ghostImage = [self.manager getGhostImage];
    tile.image = ghostImage;
    int ghostXDif = self.manager.player.ghostX - self.manager.player.currentX;
    int ghostYDif = self.manager.player.ghostY - self.manager.player.currentY;
    int XIndex = ghostXDif + 1;
    int YIndex = ghostYDif +1;
    if (XIndex >= 0 && XIndex <=3 && YIndex >=0 && YIndex <= 3) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:XIndex inSection:YIndex];
        [self.mazeCollectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    tile.image = tempStore;
}

#pragma mark Endgame Conditions
- (void) playerLoses {
    NSNotification *notification = [NSNotification notificationWithName:@"gameOver" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    [self gameEnds:NO];
}

- (void) playerWins {
    [self gameEnds:YES];
}

- (void) gameEnds:(BOOL) result {
    [self performSegueWithIdentifier:@"EndGame" sender:self];
}

#pragma mark Segue Methods

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString: @"DetailViewController"]) {
        NSArray *indexArray = [self.mazeCollectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = indexArray[0];
        if (![self.manager getMazeTileAtIndexPath:indexPath])
        {
            return NO;
        }
    }
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString: @"DetailViewController"]) {
        DetailViewController *dvc = segue.destinationViewController;
        NSArray *indexArray = [self.mazeCollectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = indexArray[0];
        dvc.mazeTile = [self.manager getMazeTileAtIndexPath:indexPath];
    }
    if ([segue.identifier isEqualToString:@"MapViewController"]) {
        MapViewController *mvc = segue.destinationViewController;
        mvc.invalidSquareDictionary = [self.manager getDictionary];
    }
}

//-(NSString *)timeString:(NSTimeInterval*)time{
//    int hours = time / 3600;
//    int minutes = time / 60 % 60;
//    int seconds = time % 60;
//    return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
//}

@end
