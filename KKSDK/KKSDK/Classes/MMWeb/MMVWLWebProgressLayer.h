

#import <QuartzCore/QuartzCore.h>

@interface MMVWLWebProgressLayer : CAShapeLayer

+ (instancetype)layerWithFrame:(CGRect)frame;

- (void)finishedLoad;
- (void)startLoad;

- (void)closeTimer;

@end
