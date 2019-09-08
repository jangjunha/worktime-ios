//
//  GoogleLoginService.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import UIKit

protocol GoogleLoginServiceType: class {
    var presentingViewController: UIViewController? { get set }

    func signIn()
    func signOut()
}
