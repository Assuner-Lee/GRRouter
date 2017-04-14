//
//  GRRouter.m
//  GroooSource
//
//  Created by Assuner on 2017/2/27.
//  Copyright © 2017年 Assuner. All rights reserved.
//

#import "GRRouter.h"
#import <objc/runtime.h>

@interface GRRouter ()

@property (nonatomic, copy) GRHostBlock hostBlock;

@end

@implementation GRRouter

+ (GRRouter *)sharedRouter {
    static GRRouter *router = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [[GRRouter alloc] init];
    });
    return router;
}

+ (UIViewController *)hostViewController {
    return [[self sharedRouter] hostViewController];
}

- (UIViewController *)hostViewController {
    if (self.hostBlock) {
        _hostViewController = self.hostBlock();
    }
    return _hostViewController;
}

//** 此方法可动态指定主控制器，若为静态，请直接设置hostViewController
+ (void)getDynamicHostViewController:(GRHostBlock)block {
    [self sharedRouter].hostBlock = block;
}

+ (void)pushViewController:(UIViewController *)aVC animated:(BOOL)animated {
    UIViewController *hostVC = [self sharedRouter].hostViewController;
    if (hostVC) {
        if ([hostVC isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController *)hostVC pushViewController:aVC animated:animated];
        } else {
            [NSException raise:@"GRRouterHostVCError" format:@"hostViewController of Router is not a UINavigationController"];
        }
    } else {
        [NSException raise:@"GRRouterHostVCError" format:@"hostViewController of Router is nil"];
    }
}

+ (void)presentViewController:(UIViewController *)aVC animated:(BOOL)animated completion:(GRBlankBlock)completion {
    UIViewController *hostVC = [self sharedRouter].hostViewController;
    if (hostVC) {
        if ([hostVC isKindOfClass:[UIViewController class]]) {
            [hostVC presentViewController:aVC animated:animated completion:completion];
        } else {
            [NSException raise:@"GRRouterHostVCError" format:@"hostViewController of Router is not a UIViewController but (%@)", NSStringFromClass([hostVC class])];
        }
    } else {
        [NSException raise:@"GRRouterHostVCError" format:@"hostViewController of Router is nil"];
    }
}



//@"push->GRMenuViewController?NO"
//@"push->GRMenuViewController"
//@"present->GRLoginViewController?NO"
+ (void)open:(NSString *)url params:(NSDictionary *)params completed:(GRBlankBlock)block {
    if (url.length) {
        NSRange preRange = [url rangeOfString:@"->"];
        NSRange sufRange = [url rangeOfString:@"?"];
        NSString *openType = [url substringWithRange:NSMakeRange(0, preRange.location)];
        NSString *className = [url substringWithRange:NSMakeRange(preRange.location + preRange.length, (sufRange.length ? sufRange.location : url.length) - (preRange.location + preRange.length))];
        NSString *animatedType = sufRange.length ? [url substringWithRange:NSMakeRange(sufRange.location + sufRange.length , url.length - (sufRange.location + sufRange.length))] : nil;
        Class class = NSClassFromString(className);
        if (class && [class isSubclassOfClass:[UIViewController class]]) {
            UIViewController *vc = [[class alloc] init];
            if (vc) {
                unsigned int count;
                objc_property_t* props = class_copyPropertyList(class, &count);
                for (NSString *key in params.allKeys) {
                    if (params[key]) {
                        BOOL isMatched = NO;
                        for (int i = 0; i < count; i++) {
                            objc_property_t property = props[i];
                            const char * name = property_getName(property);
                            NSString *propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
                            if ([propertyName isEqualToString:key]) {
                                isMatched = YES;
                                const char * attributesChar = property_getAttributes(property);
                                NSString *attributesString = [NSString stringWithCString:attributesChar encoding:NSUTF8StringEncoding];
                                NSArray * attributesArray = [attributesString componentsSeparatedByString:@","];
                                NSString *classAttribute = [attributesArray objectAtIndex:0];
                                NSString * propertyClassString = [classAttribute substringWithRange:NSMakeRange(3, classAttribute.length - 1 - 3)] ;
                                Class propertyClass = NSClassFromString(propertyClassString);
                                if (propertyClass && [params[key] isKindOfClass:propertyClass]) {
                                    [vc setValue:params[key] forKey:key];
                                } else {
                                    [NSException raise:@"GRRouterParamsError" format:@"param:value of (%@) isn't kind of class (%@) but (%@)", key, propertyClassString, NSStringFromClass([params[key] class])];
                                }
                                break;
                            }
                      }
                        if (!isMatched) {
                             [NSException raise:@"GRRouterParamsError" format:@"param:key named (%@) doesn't exist in class (%@)", key, className];
                            return;
                        }
                  }
              }
                free(props);
                if ([openType isEqualToString:@"push"]) {
                    [self pushViewController:vc animated:([animatedType isEqualToString:@"YES"] || [animatedType isEqualToString:@"NO"]) ? animatedType.boolValue : YES];
                } else if ([openType isEqualToString:@"present"]) {
                    [self presentViewController:vc animated:[animatedType isEqualToString:@"NO"] ? NO : YES  completion:block];
                } else {
                    [NSException raise:@"GRRouterOpenTypeError" format:@"openType:(%@) doesn't exist", openType];
                }
            } else {
                [NSException raise:@"GRRouterClassError" format:@"class:(%@) can't init", className];
            }
        } else {
            [NSException raise:@"GRRouterClassError" format:@"class:(%@) doesn't exist or isn't subclass of UIViewController", className];
        }
    }
}

+ (void)open:(NSString *)url params:(NSDictionary *)params {
    [self open:url params:params completed:nil];
}


@end
