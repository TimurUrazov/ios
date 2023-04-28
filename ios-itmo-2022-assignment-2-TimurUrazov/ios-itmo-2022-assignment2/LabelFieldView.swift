//
//  LabelFieldView.swift
//  ios-itmo-2022-assignment2
//
//  Created by Timur Urazov on 13.10.2022.
//

import Foundation
import UIKit

class LabelFieldView: UIView, UITextFieldDelegate  {
    private static var labelFieldViewCounter = 0
    private static var validatedFiels: [Bool] = []
    private static var editingStarted: [Bool] = []
    private static var countHasText = 0
    private static var editingStartedCounter = 0
    private var index = 0
    
    weak var delegate: LabelFieldViewDelegate?
    var validationPredicate: ((String) -> Bool)?
    
    private lazy var label = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(rgb: 0x666666)
        return label
    }()

    public private(set) lazy var textField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor(rgb: 0xF6F6F6)
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(rgb: 0xE8E8E8).cgColor
        let paddingView = UIView(frame: CGRectMake(0, 0, 16, textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupView() {
        textField.delegate = self
        
        addSubview(label)
        addSubview(textField)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        index = LabelFieldView.labelFieldViewCounter
        LabelFieldView.validatedFiels.append(false)
        LabelFieldView.editingStarted.append(false)
        LabelFieldView.labelFieldViewCounter += 1
        textField.addTarget(self, action: #selector(validation(_:)), for: .editingChanged)
    }
    
    public func configureLabelAndPlaceholder(label: String, placeHolder: String) {
        self.label.text = label
        self.textField.placeholder = label + " " + placeHolder
        if (self.textField.placeholder == "Год выпуска") {
            LabelFieldView.editingStartedCounter += 1
            LabelFieldView.editingStarted[index] = true
            LabelFieldView.validatedFiels[index] = true
            LabelFieldView.countHasText += 1
        }
    }
    
    @objc
    private func validation(_ textField: UITextField) {
        if (!LabelFieldView.editingStarted[index]) {
            LabelFieldView.editingStartedCounter += 1
            LabelFieldView.editingStarted[index] = true
            LabelFieldView.validatedFiels[index] = true
            LabelFieldView.countHasText += 1
        }
        guard let text = textField.text else {
            return
        }
        guard let validationPredicate = validationPredicate else {
            return
        }
        if (validationPredicate(text)) {
            if (LabelFieldView.validatedFiels[index]) {
                LabelFieldView.validatedFiels[index] = false
                LabelFieldView.countHasText -= 1
                textField.layer.borderColor = UIColor.systemRed.cgColor
                label.textColor = .systemRed
                textField.layer.borderColor = UIColor.systemRed.cgColor
            }
        } else if (!LabelFieldView.validatedFiels[index]) {
            LabelFieldView.validatedFiels[index] = true
            LabelFieldView.countHasText += 1
            label.textColor = UIColor(rgb: 0x666666)
            textField.layer.borderColor = UIColor(rgb: 0xE8E8E8).cgColor
        }
        delegate?.onValidation(validated: LabelFieldView.countHasText == LabelFieldView.labelFieldViewCounter
                               && LabelFieldView.labelFieldViewCounter == LabelFieldView.editingStartedCounter)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
