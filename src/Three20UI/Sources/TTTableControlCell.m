//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20UI/TTTableControlCell.h"

// UI
#import "Three20UI/TTTableControlItem.h"
#import "Three20UI/TTTextEditor.h"
#import "Three20UI/UIViewAdditions.h"
#import "Three20Style/UIFontAdditions.h"

// UICommon
#import "Three20UICommon/TTGlobalUICommon.h"

// Core
#import "Three20Core/TTCorePreprocessorMacros.h"

// Style
#import "Three20Style/Three20Style.h"

static const CGFloat kDefaultTextViewLines = 5.0f;
static const CGFloat kControlPadding = 8.0f;


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTTableControlCell

@synthesize item    = _item;
@synthesize control = _control;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
	self = [super initWithStyle:style reuseIdentifier:identifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  TT_RELEASE_SAFELY(_item);
  TT_RELEASE_SAFELY(_control);

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Class private


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)shouldConsiderControlIntrinsicSize:(UIView*)view {
  return [view isKindOfClass:[UISwitch class]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)shouldSizeControlToFit:(UIView*)view {
  return [view isKindOfClass:[UITextView class]]
  || [view isKindOfClass:[TTTextEditor class]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)shouldRespectControlPadding:(UIView*)view {
  return [view isKindOfClass:[UITextField class]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTTableViewCell class public


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
  UIView* view = nil;

  NSString *caption = @"";
  if ([object isKindOfClass:[UIView class]]) {
    view = object;

  } else {
    TTTableControlItem* controlItem = object;
    view = controlItem.control;
    caption = controlItem.caption;
  }

  CGFloat height = view.height;
  if (!height) {
    if ([view isKindOfClass:[UITextView class]]) {
      UITextView* textView = (UITextView*)view;
      CGFloat ttLineHeight = textView.font.ttLineHeight;
      height = ttLineHeight * kDefaultTextViewLines;

    } else if ([view isKindOfClass:[TTTextEditor class]]) {
      TTTextEditor* textEditor = (TTTextEditor*)view;
      CGFloat ttLineHeight = textEditor.font.ttLineHeight;
      height = ttLineHeight * kDefaultTextViewLines;

    } else if ([view isKindOfClass:[UITextField class]]) {
      UITextField* textField = (UITextField*)view;
      CGFloat ttLineHeight = textField.font.ttLineHeight;
      height = ttLineHeight + kTableCellSmallMargin*2;

    } else {
      [view sizeToFit];
      height = view.height;
    }
  }

  if ([view isKindOfClass:[UISegmentedControl class]]) {
    UISegmentedControl *seg = (UISegmentedControl *)view;
    if ([seg numberOfSegments] == 3) {
      CGFloat width = tableView.frame.size.width - (kTableCellHPadding*2 + 10*2)
            - view.frame.size.width - 225;
      CGSize size = [caption sizeWithFont:TTSTYLEVAR(tableFont)
                                constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                    lineBreakMode:UILineBreakModeWordWrap];
        if (size.height > 2000) {
          return 2000;
        }
        return size.height + kTableCellVPadding*2;
      }

    } else if ([view isKindOfClass:[UISwitch class]]) {
      CGFloat width = tableView.frame.size.width - (kTableCellHPadding*2 + 10*2)
        - view.frame.size.width - 225;
      CGSize size = [caption sizeWithFont:TTSTYLEVAR(tableFont)
                    constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                        lineBreakMode:UILineBreakModeWordWrap];
      if (size.height > 2000) {
        return 2000;
      }
    return size.height + kTableCellVPadding*2;
  }

  if (height < TT_ROW_HEIGHT) {
    return TT_ROW_HEIGHT;

  } else {
    return height;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];

  self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  self.textLabel.numberOfLines = 0;

  CGRect f = self.textLabel.frame;
  f.size.width -= 220;
  self.textLabel.frame = f;

  if ([TTTableControlCell shouldSizeControlToFit:_control]) {
    _control.frame = CGRectInset(self.contentView.bounds, 2, kTableCellSpacing / 2);

  } else {
    CGFloat minX = kControlPadding;
    CGFloat contentWidth = self.contentView.width - kControlPadding;
    if (![TTTableControlCell shouldRespectControlPadding:_control]) {
      contentWidth -= kControlPadding;
    }
    if (self.textLabel.text.length) {
      CGSize textSize = [self.textLabel sizeThatFits:self.contentView.bounds.size];
      contentWidth -= textSize.width + kTableCellSpacing;
      minX += textSize.width + kTableCellSpacing;
    }

    if (!_control.height) {
      [_control sizeToFit];
    }

    if ([TTTableControlCell shouldConsiderControlIntrinsicSize:_control]) {
      minX += contentWidth - _control.width;
      contentWidth = _control.width;
    }

    // XXXjoe For some reason I need to re-add the control as a subview or else
    // the re-use of the cell will cause the control to fail to paint itself on occasion
    [self.contentView addSubview:_control];
    _control.frame = CGRectMake(minX, floor(self.contentView.height/2 - _control.height/2),
                                contentWidth, _control.height);

    if ([_control isKindOfClass:[UISegmentedControl class]]) {
      UISegmentedControl *seg = (UISegmentedControl *)_control;
      if ([seg numberOfSegments] == 3) {
        _control.frame = CGRectMake(self.contentView.frame.size.width - 210,
                                    floor(self.contentView.height/2 - _control.height/2),
                                    200, _control.height);
      }

    } else if ([_control isKindOfClass:[UITextField class]]) {
      if (_control.frame.size.width < 200) {
        _control.frame = CGRectMake(self.contentView.frame.size.width - 210,
                                    floor(self.contentView.height/2 - _control.height/2),
                                    200, _control.height);
      }
    }

  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTTableViewCell


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)object {
  return _item ? _item : (id)_control;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setObject:(id)object {
  if (object != _control && object != _item) {
    if (_control.superview == self.contentView) {
      //on cell reuse it is possible that another
      //cell is already the owner of _control, so
      //check if we're its superview first
      [_control removeFromSuperview];
    }

    TT_RELEASE_SAFELY(_control);
    TT_RELEASE_SAFELY(_item);

    if ([object isKindOfClass:[UIView class]]) {
      _control = [object retain];

    } else if ([object isKindOfClass:[TTTableControlItem class]]) {
      _item = [object retain];
      _control = [_item.control retain];
    }

    _control.backgroundColor = [UIColor clearColor];
    self.textLabel.text = _item.caption;

    if (_control) {
      [self.contentView addSubview:_control];
    }
  }
}


@end
