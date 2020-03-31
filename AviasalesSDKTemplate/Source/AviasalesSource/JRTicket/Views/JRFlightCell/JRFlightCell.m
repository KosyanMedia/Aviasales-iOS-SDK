//
//  JRFlightCell.m
//
//  Copyright 2016 Go Travel Un Limited
//  This code is distributed under the terms and conditions of the MIT license.
//

#import "JRFlightCell.h"
#import "UIImageView+WebCache.h"
#import "DateUtil.h"

@interface JRFlightCell()

@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation JRFlightCell

- (void)layoutSubviews {
    [super layoutSubviews];

    self.separatorInset = UIEdgeInsetsMake(0.0, self.bounds.size.width, 0.0, 0.0);
}

- (void)downloadAndSetupImageForImageView:(__weak UIImageView *)logo forAirline:(JRSDKAirline *)airline {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeApplyAffineTransform(self.logoIcon.bounds.size, CGAffineTransformMakeScale(scale, scale));
    NSString *const urlString = [JRSDKModelUtils airlineLogoUrlWithIATA:airline.iata size:size isDark:NO gravity:JRAirlineLogoGravityNoGravity];
    NSURL *const url = [NSURL URLWithString:urlString];
    
    logo.image = nil;
    logo.highlightedImage = nil;
    logo.hidden = YES;
    [logo sd_setImageWithURL:url placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            logo.hidden = (error != nil);
    }];
}

#pragma mark JRTicketCellProtocol methods

- (void)applyFlight:(JRSDKFlight *)flight {

    self.durationLabel.text = [NSString stringWithFormat:@"%@: %@", AVIASALES_(@"JR_TICKET_DURATION"),
                               [DateUtil duration:flight.duration.integerValue durationStyle:JRDateUtilDurationShortStyle]];
    
    self.departureTimeLabel.text = [[DateUtil dateToTimeString:flight.departureDate] arabicDigits];
    self.arrivalTimeLabel.text = [[DateUtil dateToTimeString:flight.arrivalDate] arabicDigits];
    self.departureDateLabel.text = [[DateUtil dayMonthWeekdayStringFromDate:flight.departureDate] arabicDigits];
    self.arrivalDateLabel.text = [[DateUtil dayMonthWeekdayStringFromDate:flight.arrivalDate] arabicDigits];
    
    self.originLabel.attributedText = [self attributedStringWithCity:flight.originAirport.city andIATA:flight.originAirport.iata];
    self.destinationLabel.attributedText = [self attributedStringWithCity:flight.destinationAirport.city andIATA:flight.destinationAirport.iata];

    NSString *flightString = [NSString stringWithFormat:@"%@-%@", flight.airline.iata, flight.number];

    self.flightNumberLabel.text = [NSString localizedStringWithFormat:[@"%@ %@" formatAccordingToTextDirection], AVIASALES_(@"JR_TICKET_FLIGHT"), flightString];

    [self downloadAndSetupImageForImageView:self.logoIcon forAirline:flight.airline];
}

- (NSAttributedString *)attributedStringWithCity:(NSString *)city andIATA:(NSString *)IATA {
    NSString *string = [NSString stringWithFormat:@"%@ %@", city, IATA];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:string];
    [result addAttribute:NSFontAttributeName
                   value:[UIFont systemFontOfSize:12 weight:UIFontWeightBold]
                   range:[string rangeOfString:IATA]];
    return [result copy];
}

@end
