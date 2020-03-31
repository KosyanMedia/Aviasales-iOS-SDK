//
//  ASTWaitingScreenPresenter.swift
//
//  Copyright 2016 Go Travel Un Limited
//  This code is distributed under the terms and conditions of the MIT license.
//

import Foundation

protocol ASTWaitingScreenViewProtocol: NSObjectProtocol {

    func startAnimating()
    func animateProgress(duration: TimeInterval)
    func update(title: String)
    func updateInfo(text: String, range: NSRange)
    func showAdvertisement()
    func showSearchResults(searchResult: JRSDKSearchResult, searchInfo: JRSDKSearchInfo)
    func showError(title: String, message: String, cancel: String)
    func pop()
}

class ASTWaitingScreenPresenter: NSObject {

    private enum SearchState {
        case started
        case succeed
        case failed(Int)
    }

    weak var view: ASTWaitingScreenViewProtocol?

    private let searchInfo: JRSDKSearchInfo
    private let searchPerformer = AviasalesSDK.sharedInstance().createSearchPerformer()

    private var showErrorAction: (() -> Void)?
    private var canShowError = true {
        didSet {
            if canShowError {
                showErrorAction?()
                showErrorAction = nil
            }
        }
    }

    private var searchState: SearchState = .started

    init(searchInfo: JRSDKSearchInfo) {
        self.searchInfo = searchInfo
        super.init()
    }

    func handleLoad(view: ASTWaitingScreenViewProtocol) {
        self.view = view
        view.showAdvertisement()
        view.update(title: JRSearchInfoUtils.formattedIatasAndDatesExcludeYearComponent(for: searchInfo))
        view.animateProgress(duration: kJRSDKSearchPerformerAverageSearchTime)
        view.startAnimating()
        view.updateInfo(text: NSLS("JR_WAITING_TITLE"), range: NSRange())
        performSearch()
        PriceCalendarManager.shared.prepareLoader(with: searchInfo)
    }

    func handleShowAdvertisement() {
        canShowError = false
    }

    func handleHideAdvertisement() {
        canShowError = true
    }

    func handleError() {
        view?.pop()
    }

    func handleUnload() {
        trackFlightsSearchEvent()
        searchPerformer.terminateSearch()
    }
}

private extension ASTWaitingScreenPresenter {

    func performSearch() {
        AviasalesSDK.sharedInstance().updateCurrencyCode(CurrencyManager.shared.currency.code.lowercased())
        searchPerformer.delegate = self
        searchPerformer.performSearch(with: searchInfo)
    }

    func handle(_ temporaryResult: JRSDKSearchResult) {

        guard let bestPrice = temporaryResult.bestPrice else {
            return
        }

        let count = temporaryResult.tickets.count
        let format = NSLSP("JR_FILTER_FLIGHTS_FOUND_MIN_PRICE", Float(count))
        let price = bestPrice.formattedPriceinUserCurrency()
        let string = String(format: format, count, price)
        let range = (string as NSString).localizedStandardRange(of: price)

        view?.updateInfo(text: string, range: range)
    }

    func filter(searchResult: JRSDKSearchResult, by avialableAirlines: [String]) -> JRSDKSearchResult? {

        if avialableAirlines.count == 0 {
            return searchResult
        }

       let tickets = NSOrderedSetSequence<JRSDKTicket>(orderedSet: searchResult.tickets).filter { (ticket) -> Bool in
            let segments = NSOrderedSetSequence<JRSDKFlightSegment>(orderedSet: ticket.flightSegments)
            return segments.count == segments.filter({ (segment) -> Bool in
                let flights = NSOrderedSetSequence<JRSDKFlight>(orderedSet: segment.flights)
                return flights.count == flights.filter({ (flight) -> Bool in
                    return avialableAirlines.contains(flight.airline.iata)
                }).count
            }).count
        }

        let searchResultBuilder = JRSDKSearchResultBuilder()
        searchResultBuilder.searchResultInfo = searchResult.searchResultInfo
        searchResultBuilder.tickets = NSOrderedSet(array: tickets)
        searchResultBuilder.bestPrice = searchResult.bestPrice

        return searchResultBuilder.build()
    }

    func description(from error: NSError) -> String {

        let result: String

        switch error.code {
        case JRSDKServerAPIError.searchNoTickets.rawValue:
            result = NSLS("JR_WAITING_ERROR_NOT_FOUND_MESSAGE")
        case JRSDKServerAPIError.connectionFailed.rawValue:
            result = NSLS("JR_WAITING_ERROR_CONNECTION_ERROR")
        default:
            result = NSLS("JR_WAITING_ERROR_NOT_AVALIBLE_MESSAGE")
        }

        return result
    }

    func show(error: NSError) {

        searchState = .failed(error.code)

        let message = description(from: error)

        let showErrorAction: (() -> Void)? = { [weak self] in
            self?.view?.showError(title: NSLS("JR_ERROR_TITLE"), message: message, cancel: NSLS("JR_OK_BUTTON"))
        }

        if canShowError {
            showErrorAction?()
        } else {
            self.showErrorAction = showErrorAction
        }
    }

    func trackFlightsSearchEvent() {
        
        let event: FlightsSearchEvent
        
        switch searchState {
        case .started:
            event = FlightsSearchEvent(searchInfo: searchInfo, result: .cancelled)
        case .succeed:
            event = FlightsSearchEvent(searchInfo: searchInfo, result: .succeed)
        case .failed(let code):
            event = FlightsSearchEvent(searchInfo: searchInfo, result: .failed(code))
        }
        
        AnalyticsManager.log(event: event)
    }
}

extension ASTWaitingScreenPresenter: JRSDKSearchPerformerDelegate {

    func searchPerformer(_ searchPerformer: JRSDKSearchPerformer!, didFindSomeTickets newTickets: JRSDKSearchResultsChunk!, in searchInfo: JRSDKSearchInfo!, temporaryResult: JRSDKSearchResult!, temporaryMetropolitanResult: JRSDKSearchResult!) {
        if ConfigManager.shared.availableAirlines.count == 0 {
            handle(temporaryResult)
        }
    }

    func searchPerformer(_ searchPerformer: JRSDKSearchPerformer!, didFinishSearch searchInfo: JRSDKSearchInfo!, with result: JRSDKSearchResult!, andMetropolitanResult metropolitanResult: JRSDKSearchResult!) {

        guard  let result = result, let metropolitanResult = metropolitanResult else {
            return
        }

        let searchResult = result.tickets.count == 0 ? metropolitanResult : result

        if let filteredSearchResult = filter(searchResult: searchResult, by: ConfigManager.shared.availableAirlines), filteredSearchResult.tickets.count > 0 {
            searchState = .succeed
            view?.showSearchResults(searchResult: filteredSearchResult, searchInfo: searchInfo)
        } else {
            show(error: NSError.error(code: JRSDKServerAPIError.searchNoTickets))
        }
    }

    func searchPerformer(_ searchPerformer: JRSDKSearchPerformer!, didFinalizeSearchWith searchInfo: JRSDKSearchInfo!, error: Error!) {
        // required in protocol
    }

    func searchPerformer(_ searchPerformer: JRSDKSearchPerformer!, didFailSearchWithError error: Error!) {
        show(error: error as NSError)
    }
}
