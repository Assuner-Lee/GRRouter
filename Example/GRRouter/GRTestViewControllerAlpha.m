//
//  GRTestViewControllerAlpha.m
//  GRRouter
//
//  Created by Assuner on 2017/4/14.
//  Copyright © 2017年 Assuner-Lee. All rights reserved.
//

#import "GRTestViewControllerAlpha.h"
#import "GRRouter.h"

@implementation GRTestViewControllerAlpha

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)push:(UIButton *)sender {
    if (sender.tag == 1) {
        self.title = @"控制器1";
        [GRRouter open:@"push->GRTestViewControllerBeta" params:@{@"color": [UIColor blueColor], @"text": @"push1"}];
    } else if (sender.tag == 2) {
        self.title = @"控制器2";
        [GRRouter open:@"push->GRTestViewControllerBeta?NO" params:@{@"color": [UIColor redColor], @"text": @"push2"}];
    }
}

- (IBAction)present:(UIButton *)sender {
    if (sender.tag == 1) {
        [GRRouter open:@"present->GRTestViewControllerBeta" params:@{@"color": [UIColor blueColor], @"text": @"present1"}];
    } else if (sender.tag == 2) {
        [GRRouter open:@"present->GRTestViewControllerBeta?NO" params:@{@"color": [UIColor redColor], @"text": @"present2"}];
    }
}
@end
