//
//  GRTestViewControllerBeta.m
//  GRRouter
//
//  Created by Assuner on 2017/4/14.
//  Copyright © 2017年 Assuner-Lee. All rights reserved.
//

#import "GRTestViewControllerBeta.h"

@interface GRTestViewControllerBeta ()

@property (weak, nonatomic) IBOutlet UILabel *label;
- (IBAction)back:(id)sender;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSString *text;

@end

@implementation GRTestViewControllerBeta

- (void)viewDidLoad {
    [super viewDidLoad];
    _label.text = _text;
    _label.backgroundColor = _color;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)back:(id)sender {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
