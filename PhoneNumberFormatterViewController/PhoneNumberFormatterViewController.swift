//
//  ViewController.swift
//  PhoneNumberFormatterViewController
//
//  Created by Nurkanat Klimov on 22.10.2022.
//

import UIKit

class PhoneNumberFormatterViewController: UIViewController {
    
    private lazy var phoneTextField: JNumberMaskTextField = {
        let field = JNumberMaskTextField(type: .cardNumber(mask: "XXXX XXXX XXXX XXXX"))
        field.textColor = .lightGray
        field.font = .systemFont(ofSize: 27)
        field.keyboardType = .numberPad
        field.layer.borderColor = UIColor.orange.cgColor
        field.layer.borderWidth = 2
        field.placeholder = "Enter"
        return field
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        view.addSubview(phoneTextField)
        phoneTextField.delegate = self
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            phoneTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            phoneTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            phoneTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
    }
}


extension PhoneNumberFormatterViewController: UITextFieldDelegate { }
