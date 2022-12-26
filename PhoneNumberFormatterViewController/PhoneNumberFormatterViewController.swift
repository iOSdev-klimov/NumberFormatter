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
        field.maskString = "XXXX XXXX XXXX XXXX"
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
        field.placeholder = "Enter phone number"
        return field
    }()
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 27)
        label.text = "Please switch on to set domestic country code"
        label.textColor = .lightGray
        return label
    }()
    private lazy var customSegmentedControl: UISegmentedControl = {
        let items: [String] = ["byPhone", "byCard"]
        let segmented = UISegmentedControl(items: items)
        segmented.selectedSegmentTintColor = .orange
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentedTapped), for: .valueChanged)
        return segmented
    }()
    
    private lazy var phoneSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.onTintColor = .orange
        switcher.isEnabled = true
        switcher.isOn = false
        switcher.addTarget(self, action: #selector(phoneTypeTapped), for: .valueChanged)
        return switcher
    }()
    
    private var isActive: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(customSegmentedControl)
        customSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customSegmentedControl.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            customSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customSegmentedControl.widthAnchor.constraint(equalToConstant: 180)
        ])
        
        setupField(using: phoneTextField, isSwitchHidden: false)
        
        
    }
    
    private func setupField(using field: UITextField, isSwitchHidden: Bool) {
        
        view.addSubview(phoneSwitch)
        phoneSwitch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phoneSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            phoneSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            phoneSwitch.widthAnchor.constraint(equalToConstant: 40)
        ])
        phoneSwitch.isHidden = isSwitchHidden
        
        view.addSubview(field)
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: isSwitchHidden ? 15 : 60),
            field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
        
        
        
    }
    
    @objc private func segmentedTapped() {
        switch customSegmentedControl.selectedSegmentIndex {
        case 0:
            cardTextField.removeFromSuperview()
            setupField(using: phoneTextField, isSwitchHidden: false)
            break
        case 1:
            phoneTextField.removeFromSuperview()
            setupField(using: cardTextField, isSwitchHidden: true)
            break
        default:
            break
        }
    }
    
    @objc private func phoneTypeTapped() {
        isActive.toggle()
        phoneSwitch.setOn(isActive, animated: true)
        
        phoneTextField.resignFirstResponder()
        phoneTextField.text = nil
        phoneTextField.code = nil
        

        phoneTextField.code = phoneSwitch.isOn ? "7" : nil
        
        
    }
}


extension PhoneNumberFormatterViewController: UITextFieldDelegate {
    
    
}
