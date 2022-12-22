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
        case phoneNumber(mask: String, countryCode: String, hasCountryParenthesis: Bool = false)
        
        var mask: String {
            switch self {
            case let .cardNumber(mask):                           return mask
            case let .phoneNumber(mask, _, _):                    return mask
            }
        }
        
        var countryCode: String? {
            switch self {
            case .cardNumber:                                     return nil
            case let .phoneNumber(_, code, _):                    return code
            }
        }
        
        var hasCountryParenthesis: Bool {
            switch self {
            case .cardNumber:                                     return false
            case let .phoneNumber(_, _, hasCountryParenthesis):   return hasCountryParenthesis
            }
        }
    }

    private let formattingType: NumberFormatterType
    private var initialMask: String
    private var countryCode: String?
    private var hasCountryParenthesis: Bool

    private var whitespacePositions: [Int] = []
    private var bracketPositions: [Int] = []

    private var currentCursorPosition = 0
    private var separatorCharacters: [Character] = ["-", " "]
    private var copiedDigitsCount = 0

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
    
    private var minPastedDigits: Int {
        print("❎; ", initialMask.filter { $0 == "X" }.count)
        return initialMask.filter { $0 == "X" }.count
    }
    private var newMask: String {
        setNewMask()
    }
    private var maxDigitLimit: Int {
        switch formattingType {
        case .cardNumber:
            return minPastedDigits + 1
        case .phoneNumber:
            return (countryCode?.digits.count ?? 0) + minPastedDigits + 1
        }
    }
    
    init(type: NumberFormatterType) {
        formattingType = type
        initialMask = type.mask
        countryCode = type.countryCode
        hasCountryParenthesis = type.hasCountryParenthesis
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

        if pastedDigitsCount > 1 {
            switch formattingType {
            case .cardNumber:
                guard oldString.digits.count + pastedDigitsCount < maxDigitLimit else {
                    copiedDigitsCount = 0
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: string)
                
            case .phoneNumber:
                
                print("pastedDigits:", pastedDigitsCount)
                print("Old string:", oldString.digits)
                print("Old stringCount:", oldString.digits.count)
                
                
                guard (oldString.digits.count + pastedDigitsCount < maxDigitLimit) else {
                    copiedDigitsCount = 0
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: getValidatedString(with: formattingType.countryCode!, pasted: string))
            }
            
            copiedDigitsCount = pastedDigitsCount

        } else {
            if range.location < oldString.count,
               !configureCursorLocation(updatedText: newString, currentText: oldString, with: range) {
                return false
            }
        }
        
        textField.text = newString.formatPhoneWithMask(mask: newMask)
        
        setRemainingCursorMoveLeft(pastedString: string, currentLocation: currentCursorPosition)
        
        setCursorToEndIfNeeded(using: textField.text ?? "", pasted: string)
        
        return false
    }
    
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        
        if textField.text?.isEmpty == true {
            textField.resignFirstResponder()
        }
        
        getCurrentPosition(textField: textField)
    }
}


extension JNumberMaskTextField {

    private func getValidatedString(with countryCode: String, pasted string: String) -> String {
        let stringDigits = string.digits
        
        if stringDigits.count <= minPastedDigits {
            return stringDigits
            
        } else if stringDigits.count < maxDigitLimit && String(stringDigits.suffix(minPastedDigits)).hasPrefix(countryCode) {
            return String(stringDigits.suffix(minPastedDigits))
        }
        
        return ""
    }

    private func configureCursorLocation(updatedText: String, currentText: String, with range: NSRange) -> Bool {
        var offset = 0
        
        if updatedText.digits.count == maxDigitLimit {
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
    
    private func setRemainingCursorMoveLeft(pastedString: String, currentLocation: Int) {
        guard pastedString.digits.count > 1 else { return }
        
        let now = currentLocation
        let next = currentLocation + pastedString.digits.count

        var additionalOffset = 0
        for pos in now...next  {
            if whitespacePositions.contains(pos) {
                additionalOffset += 1
            }
        }

        let offset = next + additionalOffset
        setCursorLocation(withOffset: offset)
        copiedDigitsCount = 0
    }
    
    
    
    private func getCurrentPosition(textField: UITextField) {
        DispatchQueue.main.async {
            if let selectedRange = textField.selectedTextRange {
                self.currentCursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.end)
            }
        }
    }

    private func setInitialValue() -> String {
        guard let countryCode = formattingType.countryCode else { return "" }
        let updatedCountryCode = formattingType.hasCountryParenthesis ? "(\(countryCode)) " : "\(countryCode) "
        return "+" + updatedCountryCode
    }

    private func setNewMask() -> String {
        let maskedCountryCode = setInitialValue().replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
        return maskedCountryCode + initialMask
    }

    private func isSpaceIncluded(within range: NSRange) -> Bool {
        whitespacePositions.contains(range.location) || bracketPositions.contains(range.location)
    }
    
    private func getSpacePositions() {
        newMask.enumerated().forEach { index, char in
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
            self.selectedTextRange = self.textRange(from: startPosition, to: endPosition)
        }
    }
    
    private func setCursorToEndIfNeeded(using phoneNumber: String, pasted: String) {
        var selectedMask = newMask

        switch formattingType {
        case .cardNumber:   selectedMask = initialMask
        default:            break
        }
        
        if phoneNumber.count == selectedMask.count && !pasted.isEmpty {
            setCursorLocation(withOffset: phoneNumber.endIndex.utf16Offset(in: phoneNumber))
        }
    }
}
