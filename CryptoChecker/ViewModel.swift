//
//  ViewModel.swift
//  CryptoChecker
//
//  Created by yukatou on 2018/01/07.
//  Copyright © 2018年 yukatou. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ViewModel {

    var tickers = Variable<[Ticker]>([])
    var start: Int = 0

    let refreshTrigger = PublishSubject<Void>()
    let loadNextPageTrigger = PublishSubject<Void>()
    let loading = Variable<Bool>(false)
    let error = PublishSubject<Swift.Error>()


    let disposeBag = DisposeBag()

    init(service: CoinMarketCapService) {

        let refreshRequest = refreshTrigger
            .filter { !self.loading.value }
            .flatMap { _ -> Observable<[Ticker]> in
                self.start = 0
                return service.fetch(start: self.start)
            }

        let nextPageRequest = loadNextPageTrigger
            .filter { !self.loading.value }
            .flatMap { _ -> Observable<[Ticker]> in
                self.start += 50
                return service.fetch(start: self.start)
            }

        let response = Observable
            .of(refreshRequest, nextPageRequest)
            .merge()
            .share(replay: 1)

        Observable.combineLatest(response, tickers.asObservable()) {
            response, tickers in
                return self.start == 0 ? response : tickers + response
            }
            .sample(response)
            .bind(to: tickers)
            .disposed(by: disposeBag)

        Observable
            .of(
                refreshTrigger.map { _ in true },
                loadNextPageTrigger.map { _ in true },
                response.map { _ in false },
                error.map { _ in false }
            )
            .merge()
            .bind(to: loading)
            .disposed(by: disposeBag)

    }
}
