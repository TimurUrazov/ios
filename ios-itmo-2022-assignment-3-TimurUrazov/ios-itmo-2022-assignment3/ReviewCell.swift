//
//  ReviewCell.swift
//  ios-itmo-2022-assignment3
//
//  Created by Timur Urazov on 16.11.2022.
//

import UIKit

class ReviewCell: UITableViewCell {
    private lazy var dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()
    
    weak var delegate: ReviewCellDelegate?
    
    @IBOutlet private var name: UILabel!
    
    @IBOutlet private var date: UILabel!
    
    @IBOutlet private var director: UILabel!
    
    @IBOutlet var assesmentStars: [UIButton]!
    
    override func layoutSubviews() {
        for (index, button) in assesmentStars.enumerated() {
            button.tag = index + 1
        }
    }
    
    public func setup(with review: Review, date: Date) {
        name.text = review.name
        self.date.text = "Дата выхода: " + dateFormatter.string(from: date)
        director.text = "Режиссёр: " + review.director
        for (index, button) in assesmentStars.enumerated() {
            button.isSelected = index < review.assessment
        }
    }
    
    override func prepareForReuse() {
        assesmentStars.forEach({ (view: UIButton) in
            view.isSelected = false
        })
    }
    
    @IBAction
    func onButtonPress(_ sender: UIButton) {
        for (index, button) in assesmentStars.enumerated() {
            button.isSelected = index < sender.tag
        }
        delegate?.onCellButtonPress(assessment: sender.tag, cell: self)
    }
}
