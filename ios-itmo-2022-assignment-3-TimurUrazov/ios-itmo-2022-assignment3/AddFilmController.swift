//
//  AddFilmController.swift
//  ios-itmo-2022-assignment3
//
//  Created by Timur Urazov on 29.09.2022.
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

class AddFilmController: UIViewController {
    
    weak var delegate: AddFilmControllerDelegate?
    
    private let buttonAlpha = 0.4
    private let inputLabelsAndPlaceHolders = [("Название", "фильма"), ("Режиссёр", "фильма"), ("Год", "выпуска"), ("Номер телефона", "режиссёра") ]
    private let reactions = ["Ужасно", "Плохо", "Нормально", "Хорошо", "AMAZING!"]
    private var inputHasText = Array(repeating: false, count: 5)
    private var countToEnableSaveButton = 5
    
    var countHasTextAndAssesment = 0
    
    var dateField: UITextField?
    
    private lazy var datePicker = {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        return datePicker
    }()
    
    private lazy var toolBar = {
        let toolBar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: 44.0)))
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(handleDatePicker))
        toolBar.setItems([button], animated: true)
        return toolBar
    }()
    
    private lazy var dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
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
        let subviews = inputLabelsAndPlaceHolders.map( { (label, placeHolder) in
            createLabelFieldView(label: label, placeHolder: placeHolder)
        })
        for (index, subview) in subviews.enumerated() {
            subview.configureIndex(index: index)
            if (subview.textField.placeholder == "Год выпуска") {
                inputHasText[index] = true
                countHasTextAndAssesment += 1
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
            assesmentStarButton.index = index
            assesmentStarButton.addTarget(self, action: #selector(didTapAssesmentStarButton(sender:)), for: .touchUpInside)
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
    
    private func createLabelFieldView(label: String, placeHolder: String) -> LabelFieldView {
        let labelFieldView = LabelFieldView()
        labelFieldView.translatesAutoresizingMaskIntoConstraints = false
        labelFieldView.controller = self
        labelFieldView.configureLabelAndPlaceholder(label: label, placeHolder: placeHolder)
        if (label == "Номер телефона") {
            labelFieldView.textField.addTarget(self, action: #selector(self.numberFieldDidChange(_:)), for: .editingDidEnd)
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
        if (inputHasText[countToEnableSaveButton - 1] == false) {
            inputHasText[countToEnableSaveButton - 1] = true
            countHasTextAndAssesment += 1
        }
        adjustcountHasTextAndAssesmentChange()
    }
                             
    @objc
    private func didTapSaveButton() {
        guard let subviews = textArea.subviews as? [LabelFieldView] else { return }
        guard let fields = subviews.map({ $0.textField.text }) as? [String] else { return }
        let stars = assesmentStarButtons.first(where: { !$0.isSelected })?.index ?? 5
        let date = dateFormatter.date(from: fields[2]) ?? .now
        let review = Review(name: fields[0], director: fields[1], assessment: stars)
        self.navigationController?.popViewController(animated: true)
        delegate?.onAddButtonPress(date: date, review: review)
    }
    
    @objc
    public func textFieldDidChange(_ textField: IndexedTextField) {
        if (textField.hasText) {
            guard !inputHasText[textField.index] else {
                return
            }
            inputHasText[textField.index] = true
            countHasTextAndAssesment += 1
            adjustcountHasTextAndAssesmentChange()
        } else if (inputHasText[textField.index]) {
            inputHasText[textField.index] = false
            countHasTextAndAssesment -= 1
            saveButton.alpha = buttonAlpha
            saveButton.isEnabled = false
        }
    }
    
    @objc
    public func numberFieldDidChange(_ textField: IndexedTextField) {
        guard let text = textField.text else {
            return
        }
        if (!text.hasPrefix("+") && inputHasText[textField.index]) {
            inputHasText[textField.index] = false
            countHasTextAndAssesment -= 1
            saveButton.alpha = buttonAlpha
            saveButton.isEnabled = false
        }
    }
    
    private func adjustcountHasTextAndAssesmentChange() {
        if (countHasTextAndAssesment == countToEnableSaveButton) {
            saveButton.alpha = 1.0
            saveButton.isEnabled = true
        }
    }
}
