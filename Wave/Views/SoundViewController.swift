//
//  SoundViewController.swift
//  Wave
//
//  Created by Tian Tong on 11/5/21.
//

import UIKit

class SoundViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.secondarySystemBackground
    }
    
}
