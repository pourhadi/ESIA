//
//  ViewController.m
//  EvilStudiosInterviewApp
//
//  Created by Daniel Pourhadi on 1/14/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <AVFoundation/AVFoundation.h>
@import SoundManager;

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, SMSoundManagerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *playerContainerView;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic, strong) NSArray *audioFiles;

@property (nonatomic, weak) IBOutlet UISwitch *autoAdvanceSwitch;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedIndex = -1;
    [self.playerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(20));
    }];
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.97 alpha:1];
    [self.view layoutIfNeeded];
    
    [SMSoundManager sharedInstance].delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
    [self loadAudioFiles];
}

- (void)loadAudioFiles {
    NSArray *files = [[NSBundle mainBundle] URLsForResourcesWithExtension:nil subdirectory:@"Sounds"];
    NSMutableArray *assets = [NSMutableArray new];
    for (NSURL *file in files) {
        [assets addObject:[AVURLAsset assetWithURL:file]];
    }
    self.audioFiles = assets;
}

- (void)playTrackAtIndex:(NSInteger)index {
    AVURLAsset *asset = self.audioFiles[index];
    [[SMSoundManager sharedInstance] loadAsset:asset play:YES];
    [self updateLabel];
}

- (void)updateLabel {
    AVURLAsset *asset = self.audioFiles[self.selectedIndex];
    self.label.text = asset.URL.lastPathComponent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"listCell" forIndexPath:indexPath];
    
    AVURLAsset *asset = self.audioFiles[indexPath.row];
    cell.textLabel.text = asset.URL.lastPathComponent;
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    int minutes = floor(duration/60);
    int seconds = round(duration - minutes * 60);
    int ms = (fmod(duration, 1) * 1000);
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d.%d", minutes, seconds, ms];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.audioFiles.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Select an Audio File", nil);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger lastIndex = self.selectedIndex;
    self.selectedIndex = indexPath.row;
    if (lastIndex == -1) {
        [UIView animateWithDuration:0.3 animations:^{
           [self.playerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
               make.height.equalTo(@82);
           }];
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self playTrackAtIndex:indexPath.row];
}

#pragma mark - Sound Manager delegate

- (void)soundManagerTrackFinishedPlaying:(SMSoundManager *)soundManager {
    if (self.autoAdvanceSwitch.isOn) {
        NSInteger lastIndex = self.selectedIndex;
        self.selectedIndex += 1;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastIndex inSection:0], [NSIndexPath indexPathForRow:self.selectedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self playTrackAtIndex:self.selectedIndex];
    } else {
        self.progressView.progress = 1;
    }
}

- (void)soundManager:(SMSoundManager *)soundManager elapsedTimeUpdated:(NSTimeInterval)elapsedTime {
    dispatch_async(dispatch_get_main_queue(), ^{
        float percent = elapsedTime / soundManager.trackDuration;
        self.progressView.progress = percent;
    });
}

@end
