//
//  DYFMaterialDesignSpinner.m
//
//  Created by dyf on 15/7/4.
//  Copyright © 2015 dyf. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "DYFMaterialDesignSpinner.h"

static NSString *kRingStrokeAnimationKey   = @"spinner.stroke";
static NSString *kRingRotationAnimationKey = @"spinner.rotation";

@interface DYFMaterialDesignSpinner ()
@property (nonatomic, readonly ) CAShapeLayer *progressLayer;
@property (nonatomic, readwrite) BOOL isAnimating;
@end

@implementation DYFMaterialDesignSpinner

@synthesize progressLayer = _progressLayer;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.layer addSublayer:self.progressLayer];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resetAnimations) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressLayer.frame = CGRectMake(0, 0,
                                          CGRectGetWidth(self.bounds),
                                          CGRectGetHeight(self.bounds)
                                          );
    [self updatePath];
}

- (void)setLineColor:(UIColor *)lineColor {
    self.progressLayer.strokeColor = lineColor.CGColor;
}

- (void)resetAnimations {
    if (self.isAnimating) {
        [self  stopAnimating];
        [self startAnimating];
    }
}

- (void)startAnimating {
    if (self.isAnimating)
        return;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath     = @"transform.rotation";
    animation.duration    = 4.f;
    animation.fromValue   = @(0.f);
    animation.toValue     = @(2 * M_PI);
    animation.repeatCount = INFINITY;
    [self.progressLayer addAnimation:animation forKey:kRingRotationAnimationKey];
    
    CABasicAnimation *headAnimation = [CABasicAnimation animation];
    headAnimation.keyPath        = @"strokeStart";
    headAnimation.duration       = 1.f;
    headAnimation.fromValue      = @(0.f);
    headAnimation.toValue        = @(0.25f);
    headAnimation.timingFunction = self.timingFunction;
    
    CABasicAnimation *tailAnimation = [CABasicAnimation animation];
    tailAnimation.keyPath        = @"strokeEnd";
    tailAnimation.duration       = 1.f;
    tailAnimation.fromValue      = @(0.f);
    tailAnimation.toValue        = @(1.f);
    tailAnimation.timingFunction = self.timingFunction;
    
    CABasicAnimation *endHeadAnimation = [CABasicAnimation animation];
    endHeadAnimation.keyPath        = @"strokeStart";
    endHeadAnimation.beginTime      = 1.f;
    endHeadAnimation.duration       = 0.5f;
    endHeadAnimation.fromValue      = @(0.25f);
    endHeadAnimation.toValue        = @(1.f);
    endHeadAnimation.timingFunction = self.timingFunction;
    
    CABasicAnimation *endTailAnimation = [CABasicAnimation animation];
    endTailAnimation.keyPath        = @"strokeEnd";
    endTailAnimation.beginTime      = 1.f;
    endTailAnimation.duration       = 0.5f;
    endTailAnimation.fromValue      = @(1.f);
    endTailAnimation.toValue        = @(1.f);
    endTailAnimation.timingFunction = self.timingFunction;
    
    CAAnimationGroup *animations = [CAAnimationGroup animation];
    animations.repeatCount       = INFINITY;
    animations.duration          = 1.5f;
    animations.animations        = @[headAnimation, tailAnimation, endHeadAnimation, endTailAnimation];
    [self.progressLayer addAnimation:animations forKey:kRingStrokeAnimationKey];
    
    self.isAnimating = YES;
    
    if (self.hidesWhenStopped) {
        self.hidden  = NO;
    }
}

- (void)stopAnimating {
    if (!self.isAnimating)
        return;
    
    [self.progressLayer removeAnimationForKey:kRingRotationAnimationKey];
    [self.progressLayer removeAnimationForKey:kRingStrokeAnimationKey];
    
    self.isAnimating = NO;
    
    if (self.hidesWhenStopped) {
        self.hidden  = YES;
    }
}

#pragma mark - Private

- (void)updatePath {
    CGPoint center     = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius     = MIN(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2) - self.progressLayer.lineWidth/2;
    CGFloat startAngle = (CGFloat)(0);
    CGFloat endAngle   = (CGFloat)(2*M_PI);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:startAngle
                                                      endAngle:endAngle
                                                     clockwise:YES];
    self.progressLayer.path = path.CGPath;
    
    self.progressLayer.strokeStart = 0.f;
    self.progressLayer.strokeEnd   = 0.f;
}

#pragma mark - Properties

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.strokeColor = nil;
        _progressLayer.fillColor   = nil;
        _progressLayer.lineWidth   = 1.5f;
    }
    return _progressLayer;
}

- (BOOL)isAnimating {
    return _isAnimating;
}

- (CGFloat)lineWidth {
    return self.progressLayer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    self.progressLayer.lineWidth = lineWidth;
    [self updatePath];
}

- (void)setHidesWhenStopped:(BOOL)hidesWhenStopped {
    _hidesWhenStopped = hidesWhenStopped;
    self.hidden = (!self.isAnimating && hidesWhenStopped);
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
