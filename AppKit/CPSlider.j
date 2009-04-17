/*
 * CPSlider.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPControl.j"

#include "CoreGraphics/CGGeometry.h"

/*! SLIDER STATES */

CPLinearSlider = 0;
CPCircularSlider = 1;

@implementation CPSlider : CPControl
{
    double          _minValue;
    double          _maxValue;
    double          _altIncrementValue;
    int             _sliderType;
}

+ (id)themedAttributes
{
    return [CPDictionary dictionaryWithObjects:[nil, _CGSizeMakeZero(), 0.0, nil]
                                       forKeys:[@"knob-color", @"knob-size", @"track-width", @"track-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _minValue = 0.0;
        _maxValue = 100.0;

        _sliderType = CPLinearSlider;
        
        [self setObjectValue:50.0];
        
        [self setContinuous:YES];
    }
    
    return self;
}

- (void)setMinValue:(float)aMinimumValue
{
    if (_minValue === aMinimumValue)
        return;
    
    _minValue = aMinimumValue;

    var doubleValue = [self doubleValue];
    
    if (doubleValue < _minValue)
        [self setDoubleValue:_minValue];
}

- (float)minValue
{
    return _minValue;
}

- (void)setMaxValue:(float)aMaximumValue
{
    if (_maxValue === aMaximumValue)
        return;
    
    _maxValue = aMaximumValue;
    
    var doubleValue = [self doubleValue];
    
    if (doubleValue > _maxValue)
        [self setDoubleValue:_maxValue];
}

- (float)maxValue
{
    return _maxValue;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:MIN(MAX(aValue, _minValue), _maxValue)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setSliderType:(CPSliderType)sliderType
{
    if (sliderType === _sliderType)
        return;

    _sliderType = sliderType;

    if (_sliderType === CPCircularSlider)
        _controlState |= CPControlStateCircular;
    else
        _controlState &= ~CPControlStateCircular;
    
    [self setNeedsLayout];
}

- (CPSliderType)sliderType
{
    return _sliderType;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    var trackWidth = [self currentValueForThemedAttributeName:@"track-width"];
    
    if (trackWidth <= 0)
        return _CGRectMakeZero();
    
    if ([self sliderType] === CPLinearSlider)
    {
        if ([self isVertical])
        {
            bounds.origin.x = (_CGRectGetWidth(bounds) - trackWidth) / 2.0;
            bounds.size.width = trackWidth;
        }
        else
        {
            bounds.origin.y = (_CGRectGetHeight(bounds) - trackWidth) / 2.0;
            bounds.size.height = trackWidth;
        }
    }
    else
    {
        var originalBounds = CGRectCreateCopy(bounds);

        bounds.size.width = MIN(bounds.size.width, bounds.size.height);
        bounds.size.height = bounds.size.width;

        if (bounds.size.width < originalBounds.size.width)
            bounds.origin.x += (originalBounds.size.width - bounds.size.width) / 2.0;
        else
            bounds.origin.y += (originalBounds.size.height - bounds.size.height) / 2.0;
    }
    
    return bounds;
}

- (CGRect)knobRectForBounds:(CGRect)bounds
{
    var knobSize = [self currentValueForThemedAttributeName:@"knob-size"];
    
    if (knobSize.width <= 0 || knobSize.height <= 0)
        return _CGRectMakeZero();
    
    var knobRect = _CGRectMake(0.0, 0.0, knobSize.width, knobSize.height),
        trackRect = [self trackRectForBounds:bounds];
    
    // No track, do our best to approximate a place for this thing.
    if (!trackRect || _CGRectIsEmpty(trackRect))
        trackRect = bounds;

    if ([self sliderType] === CPLinearSlider)
    {
        if ([self isVertical])
        {
            knobRect.origin.x = _CGRectGetMidX(trackRect) - knobSize.width / 2.0;
            knobRect.origin.y = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetHeight(trackRect) - knobSize.height);
        }
        else
        {
            knobRect.origin.x = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetWidth(trackRect) - knobSize.width);
            knobRect.origin.y = _CGRectGetMidY(trackRect) - knobSize.height / 2.0;
        }
    }
    else
    {
        var angle = 3*PI_2 - ([self doubleValue] - _minValue) / (_maxValue - _minValue) * PI2,
            radius = CGRectGetWidth(trackRect) / 2.0 - 6.0;

        knobRect.origin.x = radius * COS(angle) + CGRectGetMidX(trackRect) - 3.0;
        knobRect.origin.y = radius * SIN(angle) + CGRectGetMidY(trackRect) - 2.0;
    }

    return knobRect;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "track-view")
        return [self trackRectForBounds:[self bounds]];
    
    else if (aName === "knob-view")
        return [self knobRectForBounds:[self bounds]];
    
    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "track-view" || aName === "knob-view")
    {
        var view = [[CPView alloc] init];
        
        [view setHitTests:NO];
        
        return view;
    }
    
    return [super createEphemeralSubviewNamed:aName];
}

- (void)setAltIncrementValue:(float)anAltIncrementValue
{
    _altIncrementValue = anAltIncrementValue;
}

- (float)altIncrementValue
{
    return _altIncrementValue;
}

- (int)isVertical
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);
    
    return width < height ? 1 : (width > height ? 0 : -1);
}

- (void)layoutSubviews
{
    var trackView = [self layoutEphemeralSubviewNamed:@"track-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"knob-view"];
      
    if (trackView)
        if ([self isVertical])
            [trackView setBackgroundColor:[self currentValueForThemedAttributeName:@"track-color"]];
        else
            [trackView setBackgroundColor:[self currentValueForThemedAttributeName:@"track-color"]];

    var knobView = [self layoutEphemeralSubviewNamed:@"knob-view"
                                          positioned:CPWindowAbove
                     relativeToEphemeralSubviewNamed:@"track-view"];
      
    if (knobView)
        [knobView setBackgroundColor:[self currentValueForThemedAttributeName:"knob-color"]];
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (float)_valueAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:bounds],
        trackRect = [self trackRectForBounds:bounds];

    if ([self sliderType] === CPLinearSlider)
    {
        if ([self isVertical])
        {
            var knobHeight = _CGRectGetHeight(knobRect);

            trackRect.origin.y += knobHeight / 2;
            trackRect.size.height -= knobHeight;

            var minValue = [self minValue];

            return MAX(0.0, MIN(1.0, (aPoint.y - _CGRectGetMinY(trackRect)) / _CGRectGetHeight(trackRect))) * ([self maxValue] - minValue) + minValue;
        }
        else
        {
            var knobWidth = _CGRectGetWidth(knobRect);

            trackRect.origin.x += knobWidth / 2;
            trackRect.size.width -= knobWidth;

            var minValue = [self minValue];

            return MAX(0.0, MIN(1.0, (aPoint.x - _CGRectGetMinX(trackRect)) / _CGRectGetWidth(trackRect))) * ([self maxValue] - minValue) + minValue;
        }
    }
    else
    {
        var knobWidth = _CGRectGetWidth(knobRect);

        trackRect.origin.x += knobWidth / 2;
        trackRect.size.width -= knobWidth;

        var minValue = [self minValue],
            dx = aPoint.x - _CGRectGetMidX(trackRect),
            dy = aPoint.y - _CGRectGetMidY(trackRect);

        return MAX(0.0, MIN(1.0, (3*PI_2 - ATAN2(dy, dx))%PI2 / PI2)) * ([self maxValue] - minValue) + minValue;
    }
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:_CGRectMakeCopy(bounds)];
    
    if (_CGRectContainsPoint(knobRect, aPoint))
        _dragOffset = _CGSizeMake(_CGRectGetMidX(knobRect) - aPoint.x, _CGRectGetMidY(knobRect) - aPoint.y);
    
    else 
    {
        var trackRect = [self trackRectForBounds:bounds];
        
        if (trackRect && _CGRectContainsPoint(trackRect, aPoint))
        {
            _dragOffset = _CGSizeMakeZero();
            
            [self setObjectValue:[self _valueAtPoint:aPoint]];
        }
    
        else
            return NO;
    }
    
    [self setHighlighted:YES];
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
    
    return YES;   
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self setObjectValue:[self _valueAtPoint:_CGPointMake(aPoint.x + _dragOffset.width, aPoint.y + _dragOffset.height)]];
    
    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self setHighlighted:NO];
    
    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
    shoudl we have _continuous?
*/
- (void)setContinuous:(BOOL)flag
{
    if (flag)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else 
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

@end

var CPSliderMinValueKey             = "CPSliderMinValueKey",
    CPSliderMaxValueKey             = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey         = "CPSliderAltIncrValueKey",
    CPSliderTypeKey                 = "CPSliderTypeKey";

@implementation CPSlider (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
    _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];

    self = [super initWithCoder:aCoder];

    if (self)
    {
        _altIncrementValue = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];

        [self setSliderType:[aCoder decodeIntForkey:CPSliderTypeKey]];
        [self setContinuous:YES];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue forKey:CPSliderAltIncrValueKey];
    [aCoder encodeInt:_sliderType forKey:CPSliderTypeKey];
}

@end

@implementation CPSlider (Deprecated)

- (id)value
{
    CPLog.warn("[CPSlider value] is deprecated, use doubleValue or objectValue instead.");
    
    return [self doubleValue];    
}

- (void)setValue:(id)aValue
{
    CPLog.warn("[CPSlider setValue:] is deprecated, use setDoubleValue: or setObjectValue: instead.");
    
    [self setObjectValue:aValue];
}

@end
