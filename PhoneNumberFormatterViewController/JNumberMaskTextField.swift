//
//  JNumberMaskTextField.swift
//  PhoneNumberFormatterViewController
//
//  Created by Nurkanat Klimov on 22.10.2022.
//

import UIKit


open class JNumberMaskTextField: UITextField {
    
    public enum NumberFormatterType {
        case card
        case phone
    }
    
    public var maskString: String? {
        didSet {
            whitespacePositions.removeAll()
            bracketPositions.removeAll()
            setSpacePositions()
        }
    }
    
    public var code: String? {
        didSet {
            guard formattingType == .phone,
                  let _ = code else {
                return
            }
            whitespacePositions.removeAll()
            bracketPositions.removeAll()
            setSpacePositions()
        }
    }
    
    private let formattingType: NumberFormatterType
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
        return (maskString ?? "").filter { $0 == "X" }.count
    }
    
    private var maxDigitLimit: Int {
        switch formattingType {
        case .card:
            return minPastedDigits + 1
        case .phone:
            return ((code ?? "").digits.count) + minPastedDigits + 1
        }
    }
    
    init(type: NumberFormatterType) {
        formattingType = type
        super.init(frame: .zero)
    }
    
    required public init?(coder: NSCoder) {
        fatalError()
    }
}


extension JNumberMaskTextField: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text?.isEmpty == true {
            textField.text = getInitialValue()
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
            case .card:
                guard oldString.digits.count + pastedDigitsCount < maxDigitLimit else {
                    copiedDigitsCount = 0
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: string)
                copiedDigitsCount = pastedDigitsCount
                
            case .phone:
                guard ((oldString.digits.count + pastedDigitsCount < maxDigitLimit) || pastedDigitsCount == maxDigitLimit - 1) else {
                    copiedDigitsCount = 0
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: getValidatedString(with: code ?? "", pasted: string))
                copiedDigitsCount = pastedDigitsCount
            }

        } else {
            if range.location < oldString.count,
               !configureCursorLocation(updatedText: newString, currentText: oldString, with: range) {
                return false
            }
        }

        textField.text = newString.formatPhoneWithMask(mask: setNewMask())
        setRemainingCursorMoveLeft(pastedString: string, currentPosition: currentCursorPosition)
        
        return false
    }
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        
        getCurrentPosition(textField: textField)
        
        if textField.text?.isEmpty == true {
            textField.text = getInitialValue()
        }
    }
}


extension JNumberMaskTextField {
    
    private func getValidatedString(with countryCode: String, pasted string: String) -> String {
        let stringDigits = string.digits
        
        if stringDigits.count <= minPastedDigits {
            return stringDigits
            
        } else if stringDigits.count < maxDigitLimit && stringDigits.hasPrefix(code ?? "") {
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
    
    private func setRemainingCursorMoveLeft(pastedString: String, currentPosition: Int) {
        guard copiedDigitsCount > 0 else { return }
        
        let current = currentPosition
        let next = currentPosition + pastedString.digits.count

        var additionalOffset = 0
        for pos in current...next  {
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
    
    private func getInitialValue() -> String {
        let initialValue = ""
        
        guard let countryCode = code else {
            return initialValue
        }
        
        switch formattingType {
        case .phone:
            return "+\(countryCode) "
        case .card:
            return initialValue
        }
    }
    
    private func setNewMask() -> String {
        var updatedCode = ""
        if formattingType == .phone {
            updatedCode = getInitialValue().replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
        }
        
        return updatedCode + (maskString ?? "")
    }
    
    private func isSpaceIncluded(within range: NSRange) -> Bool {
        whitespacePositions.contains(range.location) || bracketPositions.contains(range.location)
    }
    
    private func setSpacePositions() {
        setNewMask().enumerated().forEach { index, char in
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
}
