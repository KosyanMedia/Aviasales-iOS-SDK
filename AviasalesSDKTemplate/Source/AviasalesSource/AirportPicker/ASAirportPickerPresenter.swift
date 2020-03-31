//
//  ASAirportPickerPresenter.swift
//  AviasalesSDKTemplate
//
//  Created by Dim on 07.07.17.
//  Copyright © 2017 Go Travel Un Limited. All rights reserved.
//

protocol ASAirportPickerViewProtocol: class {
    func set(title: String)
    func set(placeholder: String)
    func set(sectionModels: [ASAirportPickerSectionViewModel])
    func popOrDismiss()
}

class ASAirportPickerPresenter: NSObject {

    fileprivate let type: ASAirportPickerType
    fileprivate let selection: (JRSDKAirport) -> Void

    fileprivate weak var view: ASAirportPickerViewProtocol?

    fileprivate let searchedAirports = JRSearchedAirportsManager.searchedAirports()

    fileprivate var searchText = String()
    fileprivate var searching = false

    fileprivate lazy var searchPerformer: AviasalesAirportsSearchPerformer = {
        return AviasalesAirportsSearchPerformer.init(searchLocationType: [.airport, .city], delegate: self)
    }()

    init(type: ASAirportPickerType, selection: @escaping (JRSDKAirport) -> Void) {
        self.type = type
        self.selection = selection
        super.init()
    }

    deinit {
        stopObservingNotifications()
    }

    func attach(_ view: ASAirportPickerViewProtocol) {
        self.view = view
        view.set(title: type == .origin ? NSLS("JR_AIRPORT_PICKER_ORIGIN_MODE_TITLE") : NSLS("JR_AIRPORT_PICKER_DESTINATION_MODE_TITLE"))
        view.set(placeholder: NSLS("JR_AIRPORT_PICKER_PLACEHOLDER_TEXT"))
        view.set(sectionModels: buildDefaultSectionModels())
        startObservingNotifications()
    }

    func set(searchText: String) {

        searchPerformer.cancelSearch()

        self.searchText = searchText

        if searchText.isEmpty {
            searching = false
            view?.set(sectionModels: buildDefaultSectionModels())
        } else {
            searching = true
            searchPerformer.searchAirports(with: searchText)
        }
    }

    func select(cellModel: ASAirportPickerCellModelProtocol) {

        if cellModel.type == .data {
            let cellModel = cellModel as! ASAirportPickerDataCellModel
            JRSearchedAirportsManager.markSearchedAirport(cellModel.model)
            selection(cellModel.model)
            view?.popOrDismiss()
        }
    }
}

private extension ASAirportPickerPresenter {

    func startObservingNotifications() {
        if type == .origin {
            let name =  Notification.Name(rawValue: kAviasalesNearestAirportsManagerDidUpdateNotificationName)
            NotificationCenter.default.addObserver(self, selector: #selector(updateNearestAirports), name: name, object: nil)
        }
    }

    func stopObservingNotifications() {
        if type == .origin {
            NotificationCenter.default.removeObserver(self)
        }
    }

    @objc func updateNearestAirports() {
        if self.searchText.isEmpty {
            view?.set(sectionModels: buildDefaultSectionModels())
        }
    }
}

private extension ASAirportPickerPresenter {

    func buildDefaultSectionModels() -> [ASAirportPickerSectionViewModel] {

        var sectionModels = [ASAirportPickerSectionViewModel]()

        if type == .origin {
            sectionModels.append(buildNearestAirportsSectionModel())
        }

        if let searchedAirports = searchedAirports, searchedAirports.count > 0 {
            sectionModels.append(buildSearchedAirportsSectionModel())
        }

        return sectionModels
    }

    func buildNearestAirportsSectionModel() -> ASAirportPickerSectionViewModel {
        return ASAirportPickerSectionViewModel(name: NSLS("JR_AIRPORT_PICKER_NEAREST_AIRPORTS"), cellModels: buildNearestAirportsCellModels())
    }

    func buildNearestAirportsCellModels() -> [ASAirportPickerCellModelProtocol] {

        let state = AviasalesSDK.sharedInstance().nearestAirportsManager.state
        let airports = AviasalesSDK.sharedInstance().nearestAirportsManager.airports

        let cellModels: [ASAirportPickerCellModelProtocol]

        switch state {
        case .readingAirportData:
            cellModels = [ASAirportPickerInfoCellModel(loading: true, info: NSLS("JR_AIRPORT_PICKER_UPDATING_NEAREST_AIRPORTS"))]
        case .readingError:
            cellModels = [ASAirportPickerInfoCellModel(loading: false, info: NSLS("JR_AIRPORT_PICKER_NEAREST_AIRPORTS_READING_ERROR"))]
        case .idle where airports?.count == 0:
            cellModels = [ASAirportPickerInfoCellModel(loading: false, info: NSLS("JR_AIRPORT_PICKER_NO_NEAREST_AIRPORTS"))]
        case .idle:
            cellModels = buildCellModels(from: airports)
        }

        return cellModels
    }

    func buildSearchedAirportsSectionModel() -> ASAirportPickerSectionViewModel {
        return ASAirportPickerSectionViewModel(name: NSLS("JR_AIRPORT_PICKER_SEARCHED_AIRPORTS"), cellModels: buildSearchedAirportsCellModels())
    }

    func buildSearchedAirportsCellModels() -> [ASAirportPickerDataCellModel] {
        return buildCellModels(from: searchedAirports)
    }

    func buildCellModels(from airports: [JRSDKAirport]?) -> [ASAirportPickerDataCellModel] {

        guard let airports = airports else {
            return [ASAirportPickerDataCellModel]()
        }

        return airports.map {
            ASAirportPickerDataCellModel(city: $0.city, airport: airportAndCountryString(for: $0), iata: $0.iata, model: $0)
        }
    }

    func airportAndCountryString(for airport: JRSDKAirport) -> String {
        return [airportString(for: airport), airport.countryName].compactMap({ $0 }).joined(separator: NSLS("COMMA_AND_WHITESPACE"))
    }

    func airportString(for airport: JRSDKAirport) -> String? {

        var name: String?

        if airport.isCity {

            let airport = AviasalesSDK.sharedInstance().airportsStorage.findAirport(byIATA: airport.iata, city: false)

            if let airport = airport, JRSDKModelUtils.isAirportSingle(inItsCity: airport) {
                name = airport.airportName
            } else {
                name = NSLS("JR_ANY_AIRPORT")
            }

        } else {
            name = airport.airportName
        }

        return name
    }
}

private extension ASAirportPickerPresenter {

    func buildSearchSectionModels(from locations: [JRSDKLocation]) -> [ASAirportPickerSectionViewModel] {
        return [ASAirportPickerSectionViewModel(name: nil, cellModels: buildCellModels(from: locations))]
    }

    func buildCellModels(from locations: [JRSDKLocation]) -> [ASAirportPickerCellModelProtocol] {

        var cellModels = [ASAirportPickerCellModelProtocol]()

        for location in locations {
            if let airport = location as? JRSDKAirport, airport.searchable == true {
                cellModels.append(ASAirportPickerDataCellModel(city: airport.city, airport: airportAndCountryString(for: airport), iata: airport.iata, model: airport))
            }
        }

        if cellModels.count == 0 && !searching {
            cellModels.append(ASAirportPickerInfoCellModel(loading: false, info: NSLS("JR_AIRPORT_PICKER_NOT_FOUND")))
        }

        if searching {
            cellModels.append(ASAirportPickerInfoCellModel(loading: true, info: NSLS("JR_AIRPORT_PICKER_SEARCHING_ON_SERVER_TEXT")))
        }

        return cellModels
    }
}

extension ASAirportPickerPresenter: AviasalesSearchPerformerDelegate {

    func airportsSearchPerformer(_ airportsSearchPerformer: AviasalesAirportsSearchPerformer!, didFound locations: [JRSDKLocation]!, final: Bool) {
        searching = !final
        view?.set(sectionModels: buildSearchSectionModels(from: locations))
    }

    func airportsSearchPerformer(_ airportsSearchPerformer: AviasalesAirportsSearchPerformer!, didFailSearchingWithError error: Error!) {
    }
}
