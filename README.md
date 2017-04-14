# GRRouter

[![CI Status](http://img.shields.io/travis/Assuner-Lee/GRRouter.svg?style=flat)](https://travis-ci.org/Assuner-Lee/GRRouter)
[![Version](https://img.shields.io/cocoapods/v/GRRouter.svg?style=flat)](http://cocoapods.org/pods/GRRouter)
[![License](https://img.shields.io/cocoapods/l/GRRouter.svg?style=flat)](http://cocoapods.org/pods/GRRouter)
[![Platform](https://img.shields.io/cocoapods/p/GRRouter.svg?style=flat)](http://cocoapods.org/pods/GRRouter)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

GRRouter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "GRRouter"
```
[git地址：https://github.com/Assuner-Lee/GRRouter.git](https://github.com/Assuner-Lee/GRRouter.git)

# 前言
界面间的跳转，如果某个对象不能拿到导航控制器，需通过代理，block等方式 委托某个控制器去push或present，比较麻烦。因此，我们写了一个简单的Router去简化这些操作。
# 用法


##### push

```
 [GRRouter open:@"push->GRMenuViewController" params:@{@"shop": _cellDataArray[indexPath.row]}];
```
```
 [GRRouter open:@"push->GRMenuViewController?NO" params:@{@"shop":_shop]}];

 如上，假设_shop变量的所属对象为一个cell，router初始化了一个类为GRMenuViewController的控制器 vc，并将cell的_shop变量 赋予了vc的shop属性上，最后router的hostViewController push了vc (?NO为没有动画)。
```
```
 [GRRouter open:@"push->GRTestViewControllerBeta" params:@{@"color": [UIColor blueColor], @"text": @"push1"}];
```

##### present
```
 [GRRouter open:@"present->GRLoginViewController" params:nil completed:^{[MBProgressHUD gr_showFailure:@"请先登录"];}];
```
```
 [GRRouter open:@"present->GRTestViewControllerBeta" params:@{@"color": [UIColor blueColor], @"text": @"present1"}];
```
```
 [GRRouter open:@"present->GRTestViewControllerBeta?NO" params:@{@"color": [UIColor redColor], @"text": @"present2"}];
```
#### 在此之前，我们需要设置GRRouter的hostViewController
######简而言之，当需要push，present其他控制器的时候，我们需要总能找到合适的发起者。
在某些情况下，您可以直接指定GRRouter的主控制器，比如主window的rootViewController为UINavigationController类型：
```
 [GRRouter sharedRouter].hostViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
```
如果控制器层次比较复杂，比如主window的rootViewController为UITabBarController类型，这个UITabBarController对象的控制器数组里又放着若干个UINavigationController
![图片1](http://upload-images.jianshu.io/upload_images/4133010-553ec02a376a49bb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
若想push下一个控制器，且不造成各个导航控制器栈的混乱，我们需要拿到UITabBarController当前选中的控制器。
这时，我们可以动态设置Router的主控制器，如：
```
[GRRouter getDynamicHostViewController:^UIViewController *{
    return ((UITabBarController *)self.window.rootViewController).selectedViewController;
}];
发生了:
+ (void)getDynamicHostViewController:(GRHostBlock)block {
    [self sharedRouter].hostBlock = block;
}

```
简而言之，在push present发生前，router执行block，将block返回的控制器赋给hostViewController。在此block里，你可以描述router在某些时机如何得到合适的跳转发起者，如下。
```
- (UIViewController *)hostViewController {
    if (self.hostBlock) {
        _hostViewController = self.hostBlock();
    }
    return _hostViewController;
}
```
# 代码实现
### GRRouter.h
```
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
```
### GRRouter.m
```
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

```
### 原理
 ```
+ (void)open:(NSString *)url params:(NSDictionary *)params {
    [self open:url params:params completed:nil];
}
例如:  [GRRouter open:@"push->GRMenuViewController?NO" params:@{@"shop":_shop]}];
```
首先把字符串url @"push->GRMenuViewController?NO"根据 '->'   '?' (?可以省略) 解析分隔成 `openType:@"push"`，`className:@"GRMenuViewController"`和`animatedType:@"NO"`, 然后利用runtime方法中的`NSClassFromString()`得到类`Class:GRMenuViewController` 并实例化一个`对象`，接着通过runtime拿到`类对象GRMenuViewController`里的`属性列表`，当`params字典`里的某个`key的值`匹配上了属性列表里的`一个属性名字`，接着通过runrime获取该`属性的描述`，解析出`属性的类型`，`如果属性类型与params key对应的值(对象)的类型相同，就通过KVC将这个key的值赋予到GRMenuViewControlle 实例对象的对应属性上`。
最后我们拿到了合适的跳转发起者，并把`GRMenuViewControlle `实例对象push了出去
```
- (UIViewController *)hostViewController {
    if (self.hostBlock) {
        _hostViewController = self.hostBlock();
    }
    return _hostViewController;
}
```

# 谢谢观看
##### 水平有限，若有错误，请多指正
[git地址：https://github.com/Assuner-Lee/GRRouter.git](https://github.com/Assuner-Lee/GRRouter.git)
## Author

Assuner-Lee, yongguang.li@ele.me

## License

GRRouter is available under the MIT license. See the LICENSE file for more info.
