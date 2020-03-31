//
//  SearchResultsCardList.swift
//  AviasalesSDKTemplate
//
//  Created by Dim on 19.01.2018.
//  Copyright © 2018 Go Travel Un Limited. All rights reserved.
//

import UIKit

@objc protocol SearchResultsCardListActionHandler {
    func showPriceCalendarActionDidTrigger()
    func findHotelsActionDidTrigger(atIndex index: Int)
}

@objcMembers
class SearchResultsCardList: NSObject, JRTableManager {

    fileprivate let aviasalesAdIndex = 0
    fileprivate let priceCalendarIndex = 3
    fileprivate let hotellookCardIndex = 6

    fileprivate var searchInfo: JRSDKSearchInfo
    fileprivate weak var delegate: SearchResultsCardListActionHandler?

    fileprivate var items = [SearchResultsCardItem]()

    var indexes: IndexSet {
        return IndexSet(items.map { $0.index })
    }

    init(searchInfo: JRSDKSearchInfo, delegate: SearchResultsCardListActionHandler?) {
        self.searchInfo = searchInfo
        self.delegate = delegate
        super.init()
        buildItems()
    }

    func removeHotellookCardItem() {
        if let item = items.first(where: { $0.index == hotellookCardIndex }) {
            items.removeObject(item)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = items[indexPath.section].view
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraints(JRConstraintsMakeScaleToFill(view, cell.contentView))
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section]
        return item.height
    }
}

private extension SearchResultsCardList {

    func buildItems() {

        if let priceCalendarItem = buildPriceCalendarItem() {
            items.append(priceCalendarItem)
        }

        if let hotellookCardItem = buildHotellookCardItem() {
            items.append(hotellookCardItem)
        }
    }

    func buildPriceCalendarItem() -> SearchResultsCardItem? {

        let departureDate = (searchInfo.travelSegments.firstObject as? JRSDKTravelSegment)?.departureDate
        let hasMinimumPricesAroundTheDepartureDate = PriceCalendarManager.shared.loader?.hasPricesAroundDate(departureDate, radius: 4) ?? false
        let searchInfoIsValidForPriceCalendar = JRSDKPriceCalendarLoader.searchInfoIsValid(forPriceCalendar: searchInfo)
        let hasAirlinesFilter = ConfigManager.shared.availableAirlines.count > 0

        guard let priceCalendarView = SearchResultsPriceCalendarView.loadFromNib(), hasMinimumPricesAroundTheDepartureDate && searchInfoIsValidForPriceCalendar && !hasAirlinesFilter else {
            return nil
        }

        priceCalendarView.tapAction = { [weak self] in
            self?.delegate?.showPriceCalendarActionDidTrigger()
        }

        return SearchResultsCardItem(index: priceCalendarIndex, view: priceCalendarView, height: 150)
    }

    func buildHotellookCardItem() -> SearchResultsCardItem? {

        let allowToShowCard = InteractionManager.shared.isCityReadyForSearchHotels && ConfigManager.shared.hotelsEnabled && JRSDKModelUtils.isSimpleSearch(searchInfo) && !isRTLDirectionByLocale() && ConfigManager.shared.hotelsCitySelectable

        guard allowToShowCard, let hotelCardView = JRHotelCardView.loadFromNib() else {
            return nil
        }

        hotelCardView.buttonAction = { [unowned self] in
            self.delegate?.findHotelsActionDidTrigger(atIndex: self.hotellookCardIndex)
        }

        return SearchResultsCardItem(index: hotellookCardIndex, view: hotelCardView, height: 155)
    }
}
