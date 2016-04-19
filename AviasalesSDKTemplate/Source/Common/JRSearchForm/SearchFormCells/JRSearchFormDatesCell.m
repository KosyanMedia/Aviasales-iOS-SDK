//
//  JRSearchFormDatesCell.m
//  Aviasales iOS Apps
//
//  Created by Ruslan Shevchuk on 20/01/14.
//
//

#import "JRSearchFormDatesCell.h"
#import "JRSearchFormSimpleSearchTableView.h"
#import "JRSearchFormDateCell.h"
#import "JRC.h"
#import "UIImage+ASUIImage.h"
#import "JRLineViewWithPattern.h"

@interface JRSearchFormDatesCell ()

@property (weak, nonatomic) IBOutlet JRLineViewWithPattern *verticalLine;
@property (weak, nonatomic) IBOutlet JRSearchFormSimpleSearchTableView *tableView;

@end

@implementation JRSearchFormDatesCell

- (void)setupPatternedLine
{
	UIImage *verticalLinePattern = [UIImage imageNamed:@"JRVerticalLinePattern"];
	verticalLinePattern = [verticalLinePattern imageTintedWithColor:[JRC WHITE_COLOR]];
	[_verticalLine setPatternImage:verticalLinePattern];
}

- (void)updateCell
{
	[_tableView reloadData];
}

- (void)initialSetup
{
	JRSearchFormItem *directDateItem = [[JRSearchFormItem alloc] initWithType:JRSearchFormTableViewDirectDateItem itemDelegate:self.item.itemDelegate];
	JRSearchFormItem *returnDateItem = [[JRSearchFormItem alloc] initWithType:JRSearchFormTableViewReturnDateItem itemDelegate:self.item.itemDelegate];
	[_tableView setItems:@[directDateItem, returnDateItem]];
	[_tableView reloadData];
}


- (void)awakeFromNib
{
	[super awakeFromNib];
	[self setupPatternedLine];
}

- (void)setItem:(JRSearchFormItem *)item
{
	[super setItem:item];
	[self initialSetup];
}

@end
