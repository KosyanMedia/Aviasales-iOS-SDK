//
//  UINavigationItem+IOS7Fix.m
//  Aviasales iOS Apps
//
//  Created by Ruslan Shevchuk on 06/11/13.
//
//

#import "UINavigationItem+CustomBarItems.h"
#import "UIImage+ASUIImage.h"
#import "UIButton+States.h"


@implementation UINavigationItem (CustomBarItems)

+ (UIBarButtonItem *)barItemWithImageName:(NSString *)imageName target:(id)target action:(SEL)action {
    return [self barItemWithImageName:imageName selectedImageName:nil buttonClass:[UIButton class] target:target action:action];
}

+ (UIBarButtonItem *)barItemWithImageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName target:(id)target action:(SEL)action
{
    return [self barItemWithImageName:imageName selectedImageName:selectedImageName buttonClass:[UIButton class] target:target action:action];
}

+ (UIBarButtonItem *)barItemWithImageName:(NSString *)imageName
                        selectedImageName:(NSString *)selectedImageName
                              buttonClass:(Class)buttonClass
                                   target:(id)target action:(SEL)action {
    
    id btn = [buttonClass new];
    UIButton *button =  (UIButton *)btn;
    [button setAdjustsImageWhenHighlighted:NO];
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *selectedImage = selectedImageName ? [UIImage imageNamed:selectedImageName] : nil;
    [button setImage:image forState:UIControlStateNormal];
    if (selectedImage) {
        [button setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    }
    
    [button setSetupButtonStates:YES];
    
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    [button setFrame:CGRectMake(0, 0, MAX(image.size.width, selectedImage.size.width),
                                MAX(image.size.height, selectedImage.size.height))];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    return barButton;
}

+ (UIBarButtonItem *)barItemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    return barButton;
}

@end
