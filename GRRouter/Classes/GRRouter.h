//
//  GRRouter.h
//  GroooSource
//
//  Created by Assuner on 2017/2/27.
//  Copyright © 2017年 Assuner. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^GRBlankBlock)(void);
typedef UIViewController * (^GRHostBlock)(void);

@interface GRRouter : NSObject

@property (nonatomic, strong) UIViewController *hostViewController;

+ (GRRouter *)sharedRouter;
+ (void)getDynamicHostViewController:(GRHostBlock)block;
+ (void)pushViewController:(UIViewController *)aVC animated:(BOOL)animated;
+ (void)presentViewController:(UIViewController *)aVC animated:(BOOL)animated completion:(GRBlankBlock)completion;
+ (void)open:(NSString *)url params:(NSDictionary *)params completed:(GRBlankBlock)block;
+ (void)open:(NSString *)url params:(NSDictionary *)params;

@end
