//
//  UIView+Add.h
//  XYCamera
//
//  Created by 肖扬 on 2018/10/26.
//  Copyright © 2018 Vickate. All rights reserved.
//

#import <UIKit/UIKit.h>

#define Width [UIScreen mainScreen].bounds.size.width
#define Height [UIScreen mainScreen].bounds.size.height

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Add)

@property (nonatomic) CGFloat left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  size;        ///< Shortcut for frame.size.

@end

NS_ASSUME_NONNULL_END
