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
                copiedDigitsCount = pastedDigitsCount
                newString = (oldString as NSString).replacingCharacters(in: range, with: string)
                
            case .phoneNumber:
                newString = (oldString as NSString).replacingCharacters(in: range, with: getValidatedString(with: formattingType.countryCode!, pasted: string))
            }

        } else {
            if range.location < oldString.count,
               !configureCursorLocation(updatedText: newString, currentText: oldString, with: range) {
                return false
            }
        }
        
        textField.text = newString.formatPhoneWithMask(mask: newPhoneMask)
        
        setRemainingCursorMoveLeft(pastedString: string, currentLocation: currentCursorPosition)
        
        setCursorToEndIfNeeded(using: textField.text ?? "", pasted: string)
        
        return false
    }
    
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        getCurrentPosition(textField: textField)
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

        let newOffset = next + additionalOffset
        setCursorLocation(withOffset: newOffset)
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
            self.selectedTextRange = self.textRange(from: startPosition, to: endPosition)
        }
    }
    
    private func setCursorToEndIfNeeded(using phoneNumber: String, pasted: String) {
        var selectedMask = newPhoneMask

        switch formattingType {
        case .cardNumber:   selectedMask = maskString
        default:            break
        }
        
        getCurrentPosition(textField: self)

        print("🔵final position:", currentCursorPosition)
        

        print("✋🏻phoneNumber", phoneNumber.count)
        print("✋🏻selectedMask", selectedMask.count)
//
//        if currentCursorPosition + 1 >= selectedMask.count {
//            setCursorLocation(withOffset: phoneNumber.endIndex.utf16Offset(in: phoneNumber))
//        }
        
        if phoneNumber.count == selectedMask.count && !pasted.isEmpty {
            
            setCursorLocation(withOffset: phoneNumber.endIndex.utf16Offset(in: phoneNumber))
        }
    }
}
