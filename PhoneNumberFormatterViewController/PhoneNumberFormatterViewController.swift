//
//  ViewController.swift
//  PhoneNumberFormatterViewController
//
//  Created by Nurkanat Klimov on 22.10.2022.
//

import UIKit

class PhoneNumberFormatterViewController: UIViewController {
    
    private lazy var cardTextField: JNumberMaskTextField = {
        let field = JNumberMaskTextField(type: .card)
        field.textColor = .lightGray
        field.font = .systemFont(ofSize: 27)
        field.keyboardType = .numberPad
        field.layer.borderColor = UIColor.orange.cgColor
        field.layer.borderWidth = 2
        field.placeholder = "Enter card number"
        return field
    }()
    private lazy var phoneTextField: JNumberMaskTextField = {
        let field = JNumberMaskTextField(type: .phone)
        field.textColor = .lightGray
        field.maskString = "XXX XXX XX XX"
        field.font = .systemFont(ofSize: 27)
        field.keyboardType = .numberPad
        field.layer.borderColor = UIColor.orange.cgColor
        field.layer.borderWidth = 2
        field.placeholder = "Enter phone"
        return field
    }()
    private lazy var codeField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 27)
        field.text = "+7"
        field.textColor = .lightGray
        field.delegate = self
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
        phoneTextField.code = "31"
        NSLayoutConstraint.activate([
            phoneTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            phoneTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            phoneTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
    }
}


extension PhoneNumberFormatterViewController: UITextFieldDelegate {
    
    
}
