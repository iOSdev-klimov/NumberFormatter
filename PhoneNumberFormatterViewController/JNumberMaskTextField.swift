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
            reset()
        }
    }
    
    public var countryCode: String? {
        didSet {
            guard formattingType == .phone, let _ = countryCode else { return }
            reset()
        }
    }
    
    private let formattingType: NumberFormatterType
    private var whitespacePositions: [Int] = []
    private var bracketPositions: [Int] = []
    private var currentCursorPosition = 0
    private var separatorCharacters: [Character] = ["-", " "]
    
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
            return ((countryCode ?? "").digits.count) + minPastedDigits + 1
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
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: string)

            case .phone:
                guard ((oldString.digits.count + pastedDigitsCount < maxDigitLimit) || pastedDigitsCount == maxDigitLimit - 1) else {
                    setCursorLocation(withOffset: currentCursorPosition)
                    return false
                }
                newString = (oldString as NSString).replacingCharacters(in: range, with: getValidString(with: countryCode ?? "", pasted: string))
            }

        }
        else {
            if range.location < oldString.count,
               !configureCursorLocation(updatedText: newString, currentText: oldString, with: range) {
                return false
            }
        }

        textField.text = newString.formatPhoneWithMask(mask: getNewMask())
        
        if string.digits.count > 1 {
            setRemainingPositions(pastedDigts: string.digits, and: currentCursorPosition)
        }

        

        return false
    }

    public func textFieldDidChangeSelection(_ textField: UITextField) {
        
        if textField.text?.isEmpty == true {
            textField.text = getInitialValue()
        }
        
        getCurrentPosition(textField: textField)
    }
}


extension JNumberMaskTextField {
    
    private func reset() {
        whitespacePositions.removeAll()
        bracketPositions.removeAll()
        setSpacePositions()
    }
    
    private func getValidString(with code: String, pasted string: String) -> String {
        let stringDigits = string.digits
        var validatedResult = ""

        if stringDigits.count <= minPastedDigits {
            validatedResult = stringDigits
            
        } else if stringDigits.count < maxDigitLimit && (stringDigits.hasPrefix(code) || stringDigits.hasPrefix("8")) {
            validatedResult = String(stringDigits.suffix(minPastedDigits))
        }
        return validatedResult
    }
    
    private func configureCursorLocation(updatedText: String, currentText: String, with range: NSRange) -> Bool {
        var offset = 0

        if updatedText.digits.count == maxDigitLimit || checkCursorLeftBoundary(using: range) {
            offset = range.location
            return false
            
        } else if currentText.count > updatedText.count {
            offset = range.location
            
        } else if updatedText.count > currentText.count && isSpaceIncluded(within: range) {
            let additionalOffset = getOffsetForSpaces(within: range)
            offset = range.location + additionalOffset
            
        } else {
            offset = range.location + 1
        }
        
        setCursorLocation(withOffset: offset)

        return true
    }
    
    private func setRemainingPositions(pastedDigts: String, and currentPosition: Int) {
        
        guard pastedDigts.count > 1 else { return }
        
        let currentText = self.text ?? ""
        
    
        
        var i = currentPosition
        var j = 0

        while j < pastedDigts.count && i < currentText.count {
            let index = pastedDigts.index(pastedDigts.startIndex, offsetBy: j)
            let index2 = currentText.index(currentText.startIndex, offsetBy: i)
            if pastedDigts[index] == currentText[index2] {
                j += 1
                i += 1
            } else {
                i += 1
            }
        }
        
        let offset = i

        setCursorLocation(withOffset: offset)
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
        
        guard let countryCode = countryCode else {
            return initialValue
        }
        
        switch formattingType {
        case .phone:
            return "+\(countryCode) "
        case .card:
            return initialValue
        }
    }
    
    private func getNewMask() -> String {
        var updatedCode = ""
        if formattingType == .phone {
            updatedCode = getInitialValue().replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
        }
        
        return updatedCode + (maskString ?? "")
    }
    
    private func isSpaceIncluded(within range: NSRange) -> Bool {
        whitespacePositions.contains(range.location) || bracketPositions.contains(range.location)
    }
    
    private func getOffsetForSpaces(within range: NSRange) -> Int {
        var offset = 0
        if bracketPositions.isEmpty {
            if whitespacePositions.contains(range.location) {
                offset = 2
            }

        } else {
            offset = !whitespacePositions.isEmpty ? 2 : offset
            if let lastOne = bracketPositions.last,
               lastOne == range.location {
                offset += 1
            }

            if let firstOne = bracketPositions.first,
               firstOne == range.location {
                offset = 2
    
            } else {
                offset = whitespacePositions.contains(range.location) ? 2 : offset
            }
        }
        return offset
    }
    
    private func setSpacePositions() {
        getNewMask().enumerated().forEach { index, char in
            if separatorCharacters.contains(char) {
                whitespacePositions.append(index)
            }
            if char == "(" || char == ")" {
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
    
    
    private func checkCursorLeftBoundary(using range: NSRange) -> Bool {
        let countryCode = countryCode ?? ""
        
        return formattingType == .phone && !countryCode.isEmpty && range.upperBound <= getInitialValue().count && range.lowerBound < getInitialValue().count
    }
}
