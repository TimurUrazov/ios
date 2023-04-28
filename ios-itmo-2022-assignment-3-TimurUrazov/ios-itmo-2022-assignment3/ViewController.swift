//
//  ViewController.swift
//  ios-itmo-2022-assignment3
//
//  Created by Timur Urazov on 29.09.2022.
//

import UIKit
import OrderedCollections

class ViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    
    @IBOutlet private var addButton: RoundedButton!
    
    private let setStub: TreeSet<ReviewWithDate> = TreeSet()
    
    private var reviewBase = ReviewBase()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ReviewCell", bundle: nil), forCellReuseIdentifier: "ReviewCell")
    }
    
    @IBAction
    func onButtonPress(_ sender: UIButton) {
        let addFilmController = AddFilmController()
        addFilmController.delegate = self
        self.navigationController?.pushViewController(addFilmController, animated: true)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return reviewBase.sections.size
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewBase.sections.getKth(kth: section)?.element.section.size ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = reviewBase.sections.getKth(kth: section) else { return nil }
        return String(section.element.year)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell") as? ReviewCell else { return UITableViewCell() }
        guard let review = findKth(tree: reviewBase.sections.getKth(kth: indexPath.section)?.element.section, kth: indexPath.row) else { return UITableViewCell() }
        cell.delegate = self
        cell.setup(with: review.0, date: review.1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Удалить") {
            action, view, completion in
            guard let year = self.reviewBase.sections.getKth(kth: indexPath.section)?.element else { return }
            var section = year.section
            guard let reviewAndDate = self.findKth(tree: section, kth: indexPath.row) else { return }
            let date = reviewAndDate.1
            guard let reviewWithDate = section.first(where: { $0.date == date }) else { return }
            var removeSection = false
            if (reviewWithDate.reviews.count == 1) {
                removeSection = true
            }
            do {
                try self.reviewBase.sections.remove(element: year)
                try section.remove(element: reviewWithDate)
                reviewWithDate.reviews.remove(at: reviewAndDate.2)
                try section.add(element: reviewWithDate)
                if (!removeSection) {
                    try self.reviewBase.sections.add(element: TreeElement(year: year.year, section: section))
                }
            } catch TreeAccessError.InvalidNode {
                print("Invalid node.")
            } catch {
                print("Unexpected error: \(error).")
            }
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: .none)
                if (removeSection) {
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .none)
                }
            })
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return reviewBase.sections.map({ String($0.year) })
    }
    
    private func findKth(tree: TreeSet<ReviewWithDate>?, kth: Int) -> (Review, Date, Int)? {
        guard let tree = tree else { return nil }
        return getKth(kth: kth, tree: tree)
    }
    
    private func getKth(kth: Int, tree: TreeSet<ReviewWithDate>) -> (Review, Date, Int)? {
        guard let root = tree.tree.root else {
            return nil
        }
        return getKthImpl(kth: kth, node: root)
    }
    
    private func getKthImpl(kth: Int, node: TreeNode<ReviewWithDate>) ->(Review, Date, Int)? {
        guard kth >= 0 && kth < node.size else {
            return nil
        }
        guard let left = node.left else {
            if (kth < node.element.getNodeSize()) {
                return (node.element.reviews[kth], node.element.date, kth)
            }
            guard let right = node.right else {
                return nil
            }
            return getKthImpl(kth: kth - node.element.getNodeSize(), node: right)
        }
        if (left.size <= kth) {
            if (kth - left.size < node.element.getNodeSize()) {
                return (node.element.reviews[kth - left.size], node.element.date, kth - left.size)
            }
            guard let right = node.right else {
                return nil
            }
            return getKthImpl(kth: kth - left.size - node.element.getNodeSize(), node: right)
        }
        return getKthImpl(kth: kth, node: left)
    }
}

public struct Review {
    let name: String
    let director: String
    var assessment: Int
}

class ReviewWithDate: Comparable & Sizeable {
    let date: Date
    var reviews: [Review]
    
    init(date: Date, review: Review) {
        self.date = date
        self.reviews = [review]
    }

    static func < (lhs: ReviewWithDate, rhs: ReviewWithDate) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func == (lhs: ReviewWithDate, rhs: ReviewWithDate) -> Bool {
        return lhs.date == rhs.date
    }
    
    func getNodeSize() -> Int {
        return reviews.count
    }
}

final class TreeElement: Comparable & Sizeable {
    let year: Int
    var section: TreeSet<ReviewWithDate>
    
    init(year: Int, section: TreeSet<ReviewWithDate>) {
        self.year = year
        self.section = section
    }
    
    static func < (lhs: TreeElement, rhs: TreeElement) -> Bool {
        return lhs.year < rhs.year
    }
    
    static func == (lhs: TreeElement, rhs: TreeElement) -> Bool {
        return lhs.year == rhs.year
    }
    
    func getNodeSize() -> Int {
        return 1
    }
}

final class ReviewBase {
    public var sections: TreeSet<TreeElement> = TreeSet()
    private let calendar = Calendar.current

    init() {
        // Just an example. Remove it, if you want.
        
        var dateComponents = DateComponents()
        dateComponents.year = 1980
        dateComponents.month = 7
        dateComponents.day = 11
        var year = 1980
        for _ in 0..<3 {
            year += 1
            dateComponents.year = year
            add(review: Review(name: "Зеленая миля", director: "Фрэнк Делапорт", assessment: 1), date: calendar.date(from: dateComponents) ?? .now)
        }
    }
    
    func add(review: Review, date: Date) {
        let year = calendar.component(.year, from: date)
        
        do {
            if let treeElement = sections.first(where: { $0.year == year }) {
                if let reviewWithDate = treeElement.section.first(where: { $0.date == date }) {
                    try treeElement.section.remove(element: reviewWithDate)
                    reviewWithDate.reviews.append(review)
                    try treeElement.section.add(element: reviewWithDate)
                } else {
                    let reviewWithDate = ReviewWithDate(date: date, review: review)
                    try treeElement.section.add(element: reviewWithDate)
                }
            } else {
                var newSet: TreeSet<ReviewWithDate> = TreeSet()
                let reviewWithDate = ReviewWithDate(date: date, review: review)
                try newSet.add(element: reviewWithDate)
                try self.sections.add(element: TreeElement(year: year, section: newSet))
            }
        } catch TreeAccessError.InvalidNode {
            print("Invalid node.")
        } catch {
            print("Unexpected error: \(error).")
        }
    }
}

protocol ReviewCellDelegate: AnyObject {
    func onCellButtonPress(assessment: Int, cell: ReviewCell)
}

extension ViewController: ReviewCellDelegate {
    func onCellButtonPress(assessment: Int, cell: ReviewCell) {
        guard let path = tableView.indexPath(for: cell) else { return }
        guard var section = reviewBase.sections.getKth(kth: path.section)?.element.section else { return }
        guard var cell = findKth(tree: section, kth: path.row) else { return }
        cell.0.assessment = assessment
        guard let reviews = section.first(where: { $0.date == cell.1 }) else { return }
        reviews.reviews[cell.2] = cell.0
        do {
            try section.add(element: reviews)
        } catch TreeAccessError.InvalidNode {
            print("Invalid node.")
        } catch {
            print("Unexpected error: \(error).")
        }
    }
}

protocol AddFilmControllerDelegate: AnyObject {
    func onAddButtonPress(date: Date, review: Review)
}

extension ViewController: AddFilmControllerDelegate {
    func onAddButtonPress(date: Date, review: Review) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let element = TreeElement(year: year, section: setStub)
        let containsSection = reviewBase.sections.contains(element)
        reviewBase.add(review: review, date: date)
        let sectionNumber = reviewBase.sections.k(element: element)
        let reviewWithDate = ReviewWithDate(date: date, review: review)
        let section = reviewBase.sections.getKth(kth: sectionNumber)
        var rowNumber = section?.element.section.k(element: reviewWithDate) ?? 0
        let array = section?.element.section.getKth(kth: rowNumber)
        rowNumber += array?.element.getNodeSize() ?? 0
        rowNumber -= 1
        tableView.performBatchUpdates({
            if (!containsSection) {
                tableView.insertSections(IndexSet(integer: sectionNumber), with: .none)
            }
            tableView.insertRows(at: [IndexPath(row: rowNumber, section: sectionNumber)], with: .none)
        }, completion: nil)
    }
}
