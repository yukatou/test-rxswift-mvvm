//
//  CoinMarketCapService.swift
//  CryptoChecker
//
//  Created by yukatou on 2018/01/07.
//  Copyright © 2018年 yukatou. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class CoinMarketCapService {
    let provider = MoyaProvider<CoinMarketCapAPI>()
    var tickers: [Ticker] = []
    let disposeBag = DisposeBag()

    func fetch(start: Int) -> Observable<[Ticker]> {
        return provider.rx.request(.tickers(start: start))
            .filterSuccessfulStatusCodes()
            .map { response -> [Ticker] in
                return try! JSONDecoder().decode([Ticker].self, from: response.data)
            }
            .asObservable()
    }
}
