//
//  ViewController.swift
//  CryptoChecker
//
//  Created by yukatou on 2018/01/07.
//  Copyright © 2018年 yukatou. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let disposeBag = DisposeBag()
    let refreshControl = UIRefreshControl()

    var viewModel: ViewModel!
    var service: CoinMarketCapService!

    override func viewDidLoad() {
        super.viewDidLoad()

        service = CoinMarketCapService()
        viewModel = ViewModel(service: service)

        configureBind()
        configureTableView()
    }

    private func configureBind() {
        rx.sentMessage(#selector(viewWillAppear))
            .map { _ in }
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)

        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx.reachedBottom
            .bind(to: viewModel.loadNextPageTrigger)
            .disposed(by: disposeBag)

        viewModel.loading.asObservable()
            .filter { !$0 }
            .subscribe(onNext: { _ in
                self.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)


        viewModel.loading.asObservable().subscribe(onNext: { a in
            print("loading: \(a)")
        }).disposed(by: disposeBag)
    }


    private func configureTableView() {
        tableView.refreshControl = refreshControl

        viewModel.tickers.asDriver()
            .drive(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { row, ticker, cell in
                self.configureCell(cell, ticker: ticker)
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(Ticker.self)
            .subscribe(onNext: { [unowned self] ticker in
                let vc = UIAlertController(title: ticker.name,
                                           message: String(ticker.priceUSD),
                                           preferredStyle: .alert)
                vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(vc, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func configureCell(_ cell: UITableViewCell, ticker: Ticker) {
        let coinNameLabel = cell.viewWithTag(1) as! UILabel
        let priceLabel = cell.viewWithTag(2) as! UILabel
        let coinImageView = cell.viewWithTag(3) as! UIImageView
        coinNameLabel.text = ticker.name
        priceLabel.text = String(ticker.priceUSD)
        coinImageView.kf.setImage(with: URL(string: "https://files.coinmarketcap.com/static/img/coins/32x32/\(ticker.id).png"))
    }

}

