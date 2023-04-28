//
//  LabelFieldView.swift
//  ios-itmo-2022-assignment3
//
//  Created by Timur Urazov on 13.10.2022.
//

import Foundation
import UIKit

class IndexedTextField: UITextField {
    var index = 0
}

class LabelFieldView: UIView, UITextFieldDelegate {
    weak var controller: AddFilmController?
    
    private lazy var label = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(rgb: 0x666666)
        return label
    }()
    
    public lazy var textField = {
        let textField = IndexedTextField()
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
    }
    
    public func configureLabelAndPlaceholder(label: String, placeHolder: String) {
        adjustTextChange()
        self.label.text = label
        self.textField.placeholder = label + " " + placeHolder
    }
    
    public func configureIndex(index: Int) {
        textField.index = index
    }
    
    private func adjustTextChange() {
        guard let controller = controller else { return }
        textField.addTarget(controller, action: #selector(controller.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
