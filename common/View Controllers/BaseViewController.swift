//
//  BaseViewController.swift
//  Worktime
//
//  Created by junha on 2017. 11. 18..
//  Copyright © 2017년 heek.kr. All rights reserved.
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {
    // MARK: Properties

    var disposeBag = DisposeBag()


    // MARK: Initialize

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }


    // MARK: Layout Constraints

    private var didSetupConstraints = false

    override func viewDidLoad() {
        self.view.setNeedsUpdateConstraints()
        super.viewDidLoad()
    }

    override func updateViewConstraints() {
        if !self.didSetupConstraints {
            self.setupConstraints()
            self.didSetupConstraints = true
        }
        super.updateViewConstraints()
    }

    func setupConstraints() {
        // Override point
    }
}
