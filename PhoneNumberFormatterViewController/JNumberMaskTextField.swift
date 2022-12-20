//
//  JNumberMaskTextField.swift
//  PhoneNumberFormatterViewController
//
//  Created by Nurkanat Klimov on 22.10.2022.
//

import UIKit

open class JNumberMaskTextField: UITextField {

    public enum NumberFormatterType {
        case cardNumber(mask: String)
        case phoneNumber(mask: String, countryCode: String, hasCodeBrackets: Bool = false)

        var mask: String {
            switch self {
            case let .cardNumber(mask):                 return mask
            case let .phoneNumber(mask, _, _):          return mask
            }
        }

        var countryCode: String? {
            switch self {
            case .cardNumber:                           return nil
            case let .phoneNumber(_, code, _):          return code
            }
        }

        var hasCountryCodeBrackets: Bool {
            switch self {
            case .cardNumber:                           return false
            case let .phoneNumber(_, _, hasBrackets):   return hasBrackets
            }
        }
    }

    private let formattingType: NumberFormatterType
    private var maskString: String
    private var countryCode: String?
    private var hasCountryCodeBrackets: Bool
    private var whitespacePositions = [Int]()
    private var bracketPositions = [Int]()
    private var currentCursorPosition = 0
    private var separatorCharacters: [Character] = ["-", " "]

    private var copiedDigitsCount = 0
    private var areManyDigists = false

    fileprivate weak var maskDelegate: UITextFieldDelegate?
    override weak public var delegate: UITextFieldDelegate? {
        get {
            return self.maskDelegate
        }
        
        set {
            self.maskDelegate = newValue
            super.delegate = self
        }
    }

    private var minNumberOfPastedDigits: Int {
        maskString.filter { $0 == "X" }.count
    }
    private var newPhoneMask: String {
        setNewPhoneMask()
    }
    private var maxNumberLimit: Int {
        switch formattingType {
        case .cardNumber:
            return minNumberOfPastedDigits + 1
        default:
            return (countryCode?.digits.count ?? 0) + minNumberOfPastedDigits + 1
        }
    }

    init(type: NumberFormatterType) {
        formattingType = type
        maskString = type.mask
        countryCode = type.countryCode
        hasCountryCodeBrackets = type.hasCountryCodeBrackets
        super.init(frame: .zero)
        getSpacePositions()
    }

    required public init?(coder: NSCoder) {
        fatalError()
    }
}


extension JNumberMaskTextField: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text?.isEmpty == true {
            textField.text = setInitialValue()
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.text = ""
        return true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldString = textField.text ?? ""
        var newString = (oldString as NSString).replacingCharacters(in: range, with: string)
        let pastedDigitsCount = string.digits.count

        if textField.text?.isEmpty == true {
            switch formattingType {
            case .phoneNumber:
                textField.text = setInitialValue()
            default:
                textField.text = newString
            }
            return false
        }

        if pastedDigitsCount > 1 {
            switch formattingType {
            case .cardNumber:
                guard oldString.digits.count + pastedDigitsCount < maxNumberLimit else { return false }
                newString = (oldString as NSString).replacingCharacters(in: range, with: string)

            case .phoneNumber:
                newString = (oldString as NSString).replacingCharacters(in: range, with: getValidatedString(with: formattingType.countryCode!, pasted: string))
            }
//            configureCursorLocation(currentLocation: currentCursorPosition, pastedDigits: pastedDigitsCount)

        } else {
            if range.location < oldString.count,
                      !configureCursorLocation(updatedText: newString, currentText: oldString, with: range) {
                return false
            }
        }

        textField.text = newString.formatPhoneWithMask(mask: newPhoneMask)
        setCursorToEndIfNeeded(using: textField.text ?? "")
        
        return false
    }
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let selectedRange = self.selectedTextRange else { return }
        currentCursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.end)
    }
}


extension JNumberMaskTextField {

    private func getValidatedString(with countryCode: String, pasted string: String) -> String {
        let stringDigits = string.digits

        if stringDigits.count <= minNumberOfPastedDigits {
            return stringDigits

        } else if stringDigits.count < maxNumberLimit && String(stringDigits.suffix(minNumberOfPastedDigits)).hasPrefix(countryCode) {
            return String(stringDigits.suffix(minNumberOfPastedDigits))
        }

        return ""
    }

    private func configureCursorLocation(updatedText: String, currentText: String, with range: NSRange) -> Bool {
        var offset = 0

        if updatedText.digits.count == maxNumberLimit {
            return false

        } else if currentText.count > updatedText.count {
            offset = range.location

        } else if updatedText.count > currentText.count && isSpaceIncluded(within: range) {
            offset = range.location + 2

        } else {
            offset = range.location + 1
        }

        setCursorLocation(withOffset: offset)
        return true
    }
    
//    private func configureCursorLocation(currentLocation: Int, pastedDigits: Int) {
//        var additionalOffset = 0
//        let next = currentLocation + pastedDigits
//
//        print("Next:", next)
//        print("🔴currentNowPosition", currentLocation)
//
//
//
//        for pos in currentLocation...next {
//            if whitespacePositions.contains(pos - 1) {
//                additionalOffset += 1
//            }
//        }
//        print("🔴additionalOffset", additionalOffset)
//        print("✅Next:", next)
//
//        setCursorLocation(withOffset: next)
//    }
//
    

    private func setInitialValue() -> String {
        guard let countryCode = formattingType.countryCode else { return "" }
        let updatedCountryCode = formattingType.hasCountryCodeBrackets ? "(\(countryCode)) " : "\(countryCode) "
        return "+" + updatedCountryCode
    }

    private func setNewPhoneMask() -> String {
        let maskedCountryCode = setInitialValue().replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
        return maskedCountryCode + maskString
    }

    private func isSpaceIncluded(within range: NSRange) -> Bool {
        whitespacePositions.contains(range.location) || bracketPositions.contains(range.location)
    }

    private func getSpacePositions() {
        newPhoneMask.enumerated().forEach { index, char in
            if separatorCharacters.contains(char) {
                whitespacePositions.append(index)
    
            } else if char == "(" || char == ")" {
                bracketPositions.append(index)
            }
        }
    }

    private func setCursorLocation(withOffset offset: Int) {
        guard let startPosition = self.position(from: self.beginningOfDocument, offset: offset),
              let endPosition = self.position(from: startPosition, offset: 0) else { return }
        
        DispatchQueue.main.async {
            self.self.selectedTextRange = self.textRange(from: startPosition, to: endPosition)
        }
    }

    private func setCursorToEndIfNeeded(using phoneNumber: String) {
        var selectedMask = newPhoneMask

        switch formattingType {
        case .cardNumber:   selectedMask = maskString
        default:            break
        }

        if currentCursorPosition == selectedMask.count {
            setCursorLocation(withOffset: phoneNumber.endIndex.utf16Offset(in: phoneNumber))
        }
    }
}
