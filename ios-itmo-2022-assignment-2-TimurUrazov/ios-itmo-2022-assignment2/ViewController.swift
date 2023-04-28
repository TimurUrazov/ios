//
//  ViewController.swift
//  ios-itmo-2022-assignment2
//
//  Created by rv.aleksandrov on 29.09.2022.
//

import UIKit

extension UIColor {
    convenience init(rgb: Int) {
        let convertToCGFloat = { (color: Int) -> CGFloat in
            CGFloat(color & 0xFF) / 255.0
        }
        
        self.init(red: convertToCGFloat(rgb >> 16),
                  green: convertToCGFloat(rgb >> 8),
                  blue: convertToCGFloat(rgb),
                  alpha: 1.0)
    }
}

class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}

class IndexedButton: UIButton {
    var index = 0
}

class ViewController: UIViewController, LabelFieldViewDelegate {
    private let buttonAlpha = 0.4
    
    private let inputLabelsAndPlaceHolders = [("Название", "фильма", { (text: String) in
        return text.count > 300 || text.count < 1
    }), ("Режиссёр", "фильма", { (text: String) in
        let regex = "^[A-ZА-Я]+[a-zа-я]*(\\s+[A-ZА-Я]+[a-zа-я]*)*\\s*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return !predicate.evaluate(with: text) || text.count > 300 || text.count < 3
    }), ("Год", "выпуска", { (text: String) in
        let regex = "^[0-9]{1,2}.[0-9]{1,2}.[0-9]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return !predicate.evaluate(with: text)
    }), ("Номер телефона", "режиссёра", { (text: String) in
        let regex = "^[\\+]?[(]?[0-9]{3}[)]?[-\\s\\.]?[0-9]{3}[-\\s\\.]?[0-9]{4,6}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return !predicate.evaluate(with: text)
    })]
    
    private let reactions = ["Ужасно", "Плохо", "Нормально", "Хорошо", "AMAZING!"]
    var assessmentDidSet = false
    var validated = false
    
    var dateField: UITextField?
    
    private lazy var datePicker = {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        return datePicker
    }()
    
    private lazy var dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private lazy var toolBar = {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: 44.0)))
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(handleDatePicker))
        toolBar.setItems([button], animated: true)
        return toolBar
    }()
    
    private lazy var saveButton = {
        let saveButton = RoundedButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.isEnabled = false
        saveButton.backgroundColor = UIColor(rgb: 0x5DB075)
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.tintColor = UIColor(rgb: 0xFFFFFF)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        saveButton.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        saveButton.alpha = buttonAlpha
        return saveButton
    }()
    
    private lazy var capture = {
        let capture = UILabel()
        capture.translatesAutoresizingMaskIntoConstraints = false
        capture.textAlignment = .center
        capture.font = .systemFont(ofSize: 30, weight: .bold)
        capture.text = "Фильм"
        capture.textColor = .black
        return capture
    }()

    private lazy var textArea = {
        let subviews = inputLabelsAndPlaceHolders.map( { (label, placeHolder, validationPredicate) in
            createLabelFieldView(label: label, placeHolder: placeHolder, validationPredicate: validationPredicate)
        })
        for subview in subviews {
            if (subview.textField.placeholder == "Год выпуска") {
                dateField = subview.textField
                subview.textField.inputAccessoryView = toolBar
                subview.textField.inputView = datePicker
                subview.textField.text = dateFormatter.string(from: .now)
            }
        }
        let textArea = UIStackView(arrangedSubviews: subviews)
        textArea.translatesAutoresizingMaskIntoConstraints = false
        textArea.isLayoutMarginsRelativeArrangement = true
        textArea.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textArea.axis = .vertical
        textArea.distribution = .fillEqually
        textArea.spacing = 16
        return textArea
    }()
    
    private lazy var inputArea = {
        let inputArea = UIView()
        inputArea.translatesAutoresizingMaskIntoConstraints = false
        return inputArea
    }()
    
    private lazy var assesmentArea = {
        let assesmentArea = UIView()
        assesmentArea.translatesAutoresizingMaskIntoConstraints = false
        return assesmentArea
    }()
    
    private lazy var assesmentStarButtons = {
        var buttons: Array<IndexedButton> = []
        for index in 0..<reactions.count {
            let assesmentStarButton = IndexedButton()
            assesmentStarButton.translatesAutoresizingMaskIntoConstraints = false
            assesmentStarButton.setImage(UIImage(named: "GreyStar.png"), for: .normal)
            assesmentStarButton.setImage(UIImage(named: "YellowStar.png"), for: .selected)
            assesmentStarButton.addTarget(self, action: #selector(didTapAssesmentStarButton(sender:)), for: .touchUpInside)
            assesmentStarButton.index = index
            buttons.append(assesmentStarButton)
        }
        return buttons
    }()
    
    private lazy var assesmentText = {
        let assesmentText = UILabel()
        assesmentText.translatesAutoresizingMaskIntoConstraints = false
        assesmentText.text = "Ваша оценка"
        assesmentText.textAlignment = .center
        assesmentText.font = .systemFont(ofSize: 16, weight: .bold)
        assesmentText.textColor = UIColor(rgb: 0xBDBDBD)
        return assesmentText
    }()
    
    private lazy var assesmentStars = {
        let assesmentStars = UIStackView(arrangedSubviews: assesmentStarButtons)
        assesmentStars.translatesAutoresizingMaskIntoConstraints = false
        assesmentStars.axis = .horizontal
        assesmentStars.spacing = 20
        assesmentStars.distribution = .fillEqually
        return assesmentStars
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0xFFFFFF)
        view.addSubview(saveButton)
        view.addSubview(capture)
        view.addSubview(inputArea)
        
        inputArea.addSubview(textArea)
        inputArea.addSubview(assesmentArea)
        
        assesmentArea.addSubview(assesmentText)
        assesmentArea.addSubview(assesmentStars)
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            saveButton.heightAnchor.constraint(equalToConstant: 51),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            capture.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            capture.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            capture.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            inputArea.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 98),
            inputArea.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            inputArea.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            inputArea.heightAnchor.constraint(equalToConstant: 461.18),
            
            textArea.topAnchor.constraint(equalTo: inputArea.topAnchor),
            textArea.leadingAnchor.constraint(equalTo: inputArea.leadingAnchor),
            textArea.trailingAnchor.constraint(equalTo: inputArea.trailingAnchor),
            textArea.heightAnchor.constraint(equalToConstant: 356),
            
            assesmentArea.bottomAnchor.constraint(equalTo: inputArea.bottomAnchor),
            assesmentArea.leadingAnchor.constraint(equalTo: inputArea.leadingAnchor, constant: 51.5),
            assesmentArea.trailingAnchor.constraint(equalTo: inputArea.trailingAnchor, constant: -51.5),
            assesmentArea.heightAnchor.constraint(equalToConstant: 81.18),
            
            assesmentStars.topAnchor.constraint(equalTo: assesmentArea.topAnchor),
            assesmentStars.leadingAnchor.constraint(equalTo: assesmentArea.leadingAnchor),
            assesmentStars.trailingAnchor.constraint(equalTo: assesmentArea.trailingAnchor),
            assesmentStars.heightAnchor.constraint(equalToConstant: 38.18),
            
            assesmentText.bottomAnchor.constraint(equalTo: assesmentArea.bottomAnchor),
            assesmentText.leadingAnchor.constraint(equalTo: assesmentArea.leadingAnchor),
            assesmentText.trailingAnchor.constraint(equalTo: assesmentArea.trailingAnchor),
        ])
    }
    
    private func createLabelFieldView(label: String, placeHolder: String, validationPredicate: @escaping (String) -> Bool) -> LabelFieldView {
        let labelFieldView = LabelFieldView()
        labelFieldView.translatesAutoresizingMaskIntoConstraints = false
        labelFieldView.delegate = self
        labelFieldView.validationPredicate = validationPredicate
        labelFieldView.configureLabelAndPlaceholder(label: label, placeHolder: placeHolder)
        if (label == "Год") {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .dateAndTime
            labelFieldView.textField.inputView = datePicker
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            labelFieldView.textField.text = formatter.string(from: datePicker.date)
        }
        return labelFieldView
    }
    
    @objc
    private func handleDatePicker() {
        setDate()
        self.view.endEditing(true)
    }
    
    private func setDate() {
        guard let dateField = dateField else {
            return
        }
        dateField.text = dateFormatter.string(from: datePicker.date)
    }
    
    @objc
    private func didTapAssesmentStarButton(sender: IndexedButton) {
        assesmentText.text = reactions[sender.index]
        for (index, button) in assesmentStarButtons.enumerated() {
            button.isSelected = index <= sender.index
        }
        assessmentDidSet = true
        onValidation(validated: validated)
    }
                             
    @objc
    private func didTapSaveButton() {
        // something
    }
    
    func onValidation(validated: Bool) {
        self.validated = validated
        if (validated && assessmentDidSet) {
            saveButton.alpha = 1.0
            saveButton.isEnabled = true
        } else {
            saveButton.alpha = buttonAlpha
            saveButton.isEnabled = false
        }
    }
}

protocol LabelFieldViewDelegate: AnyObject {
    func onValidation(validated: Bool)
}
