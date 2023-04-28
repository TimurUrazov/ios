//
//  TreeSet.swift
//  TreeSet
//
//  Created by Wenbin Zhang on 12/12/15.
//  Copyright © 2015 Wenbin Zhang. All rights reserved.
//

// This code was modified for project purposes.

import Foundation

public protocol Sizeable {
    func getNodeSize() -> Int
}

public struct TreeSet<E: Comparable & Sizeable> {
    internal var tree: AVLTree<E>
    public var size: Int {
        get {
            return tree.size
        }
    }
    
    init() {
        tree = AVLTree()
    }
    
    init<C: Collection>(elements: C) throws where C.Iterator.Element == E {
        self.init()
        do {
            try addAll(elements: elements)
        }
        
    }
    
    func getFirst() -> E? {
        guard let root = tree.root else {
            return nil
        }
        return tree.minNode(node: root).element
    }
    
    func getKth(kth: Int) -> TreeNode<E>? {
        guard let root = tree.root else {
            return nil
        }
        return getKthImpl(kth: kth, node: root)
    }
    
    private func getKthImpl(kth: Int, node: TreeNode<E>) -> TreeNode<E>? {
        guard kth >= 0 && kth < size else {
            return nil
        }
        guard let left = node.left else {
            if (kth == 0) {
                return node
            }
            guard let right = node.right else {
                return nil
            }
            return getKthImpl(kth: kth - 1, node: right)
        }
        if (left.size <= kth) {
            if (kth == left.size) {
                return node
            }
            guard let right = node.right else {
                return nil
            }
            return getKthImpl(kth: kth - left.size - 1, node: right)
        }
        return getKthImpl(kth: kth, node: left)
    }
    
    func getLast() -> E? {
        guard let root = tree.root else {
            return nil
        }
        return tree.maxNode(node: root).element
    }
    
    func k(element: E) -> Int {
        return tree.k(element: element)
    }
    
    func contains(element: E) -> Bool {
        return tree.search(element: element)
    }
    
    private mutating func makeTreeCopyIfNeed() {
        if !isKnownUniquelyReferenced(&tree) {
            tree = tree.copy()
        }
    }
    
    mutating func addAll<C: Collection>(elements: C) throws where C.Iterator.Element == E {
        makeTreeCopyIfNeed()
        for element in elements {
            try tree.insert(newElement: element)
        }
    }
    
    mutating func add(element: E) throws {
        makeTreeCopyIfNeed()
        try tree.insert(newElement: element)
    }
    
    mutating func remove(element: E) throws {
        makeTreeCopyIfNeed()
        try tree.remove(element: element)
    }
}

// MARK: - SequenceType
extension TreeSet : Sequence {
    public typealias Iterator = TreeSetGenerator<E>

    public func makeIterator() -> TreeSetGenerator<E> {
        return Iterator(self)
    }
}

// MARK: - GeneratroType
public struct TreeSetGenerator<E: Comparable & Sizeable>: IteratorProtocol {
    public typealias Element = E
    private let treeSet: TreeSet<E>
    private var currentNode: TreeNode<E>?
    
    init(_ treeSet: TreeSet<E>) {
        self.treeSet = treeSet
    }
    
    public mutating func next() -> Element? {
        guard let rootNode = treeSet.tree.root else {
            return nil
        }
        
        guard let node = currentNode else {
            currentNode = treeSet.tree.minNode(node: rootNode)
            return currentNode?.element
        }
        currentNode = treeSet.tree.successor(element: node)
        return currentNode?.element
    }
}

enum TreeAccessError: Error {
    case InvalidNode
}

// MARK: - Node for AVLTree to hold element.
public class TreeNode<E: Comparable & Sizeable> {
    var element: E
    var size: Int = 1
    var height: Int = 1
    var left: TreeNode?
    var right: TreeNode?
    weak var parent: TreeNode?
    
    init(element: E!) {
        self.element = element;
    }
}

extension TreeNode {
    func copy() -> TreeNode {
        let node = TreeNode(element: self.element)
        node.left = self.left?.copy()
        node.left?.parent = node
        node.right = self.right?.copy()
        node.right?.parent = node
        return node
    }
}

// MARK: - Equatable
extension TreeNode: Equatable {}

public func ==<E: Comparable>(lhs: TreeNode<E>, rhs: TreeNode<E>) -> Bool
{
    return lhs.element == rhs.element
}

func <<E: Comparable>(lhs: TreeNode<E>, rhs: TreeNode<E>) -> Bool
{
    return lhs.element < rhs.element
}

func <=<E: Comparable>(lhs: TreeNode<E>, rhs: TreeNode<E>) -> Bool {
    return lhs.element <= rhs.element
}

func ><E: Comparable>(lhs: TreeNode<E>, rhs: TreeNode<E>) -> Bool {
    return lhs.element > rhs.element
}

func >=<E: Comparable>(lhs: TreeNode<E>, rhs: TreeNode<E>) -> Bool {
    return lhs.element >= rhs.element
}

// MARK: - AVLTree Implementation
internal class AVLTree <E: Comparable & Sizeable> {
    
    var root: TreeNode<E>?
    public private(set) var size: Int = 0
    
    internal func insert(newElement: E) throws {
        do {
            if (search(element: newElement)) {
                return
            }
            root = try insertToNode(node: root, newElement: newElement)
            size = root?.size ?? 0
        }
        
    }
    
    internal func remove(element: E) throws {
        do {
            if (!search(element: element)) {
                return
            }
            root = try delete(node: root, element: element)
            size = root?.size ?? 0
        }
        
    }
    
    internal func successor(element: TreeNode<E>?) -> TreeNode<E>? {
        guard let node = element else {
            return nil
        }
        if let rightBranch = node.right {
            return minNode(node: rightBranch)
        } else {
            var p = node.parent
            var child = node
            while (p != nil && child == p!.right) {
                child = p!
                p = p!.parent
            }
            return p
        }
    }
    
    internal func k(element: E) -> Int {
        var node = root;
        var k = 0;
        
        while (node != nil) {
            if (node!.element > element) {
                node = node!.left
            } else if (node!.element < element) {
                k += (node?.left?.size ?? 0) + node!.element.getNodeSize()
                node = node!.right
            } else {
                return (node?.left?.size ?? 0) + k
            }
        }
        return -1
    }
    
    internal func search(element: E) -> Bool {
        var node = root;
        
        while (node != nil) {
            if (node!.element > element) {
                node = node!.left
            } else if (node!.element < element) {
                node = node!.right
            } else {
                return true
            }
        }
        return false
    }
    
    private func insertToNode(node: TreeNode<E>?, newElement: E) throws -> TreeNode<E> {
        guard let notNilNode = node else {
            let el = TreeNode(element: newElement)
            updateNodeSize(node: el)
            return el
        }
        if (newElement > notNilNode.element) {
            notNilNode.right = try insertToNode(node: notNilNode.right, newElement: newElement)
            notNilNode.right?.parent = notNilNode
        } else if (newElement < notNilNode.element) {
            notNilNode.left = try insertToNode(node: notNilNode.left, newElement: newElement)
            notNilNode.left?.parent = notNilNode
        } else {
            updateNodeSize(node: notNilNode)
            return notNilNode
        }
        updateNodeHeight(node: notNilNode)
        updateNodeSize(node: notNilNode)
        return try rebalanceTree(node: notNilNode)
    }
    
    private func delete(node: TreeNode<E>?, element: E) throws -> TreeNode<E>? {
        guard var newNode = node else {
            return nil
        }
        if (element > newNode.element) {
            newNode.right = try delete(node: newNode.right, element: element)
        } else if (element < newNode.element){
            newNode.left = try delete(node: newNode.left, element: element)
        } else {
            if (newNode.left == nil || newNode.right == nil) {
                if let child = newNode.left == nil ? newNode.right : newNode.left {
                    newNode = child
                } else {
                    return nil
                }
            } else {
                let min = minNode(node: newNode.right!)
                newNode.element = min.element
                newNode.right = try delete(node: newNode.right, element: min.element)
            }
        }
        updateNodeHeight(node: newNode)
        updateNodeSize(node: newNode)
        return try rebalanceTree(node: newNode)
    }
    
    func minNode(node: TreeNode<E>) -> TreeNode<E> {
        guard let leftNotNil = node.left else {
            return node
        }
        return minNode(node: leftNotNil)
    }
    
    func maxNode(node: TreeNode<E>) -> TreeNode<E> {
        guard let rightNode = node.right else {
            return node
        }
        return maxNode(node: rightNode)
    }
    
    // MARK: - Private helpers
    private func rebalanceTree(node: TreeNode<E>) throws -> TreeNode<E> {
        let balance = getBalance(node: node)
        if (balance > 1 && getHeight(node: node.left?.left) >= getHeight(node: node.left?.right)) {
            return try leftLeft(node: node)
        } else if (balance > 1 && getHeight(node: node.left?.right) > getHeight(node: node.left?.left)) {
            return try leftRight(node: node)
        } else if (balance < -1 && getHeight(node: node.right?.left) >= getHeight(node: node.right?.right)) {
            return try rightLeft(node: node)
        } else if (balance < -1 && getHeight(node: node.right?.right) > getHeight(node: node.right?.left)) {
            return try rightRight(node: node)
        }
        
        return node
    }
    
    private func updateNodeHeight(node: TreeNode<E>) {
        let leftHeight = node.left == nil ? 0 : node.left!.height
        let rightHeight = node.right == nil ? 0 : node.right!.height
        node.height = max(leftHeight, rightHeight) + 1
    }
    
    private func updateNodeSize(node: TreeNode<E>) {
        let leftSize = node.left == nil ? 0 : node.left!.size
        let rightSize = node.right == nil ? 0 : node.right!.size
        node.size = leftSize + rightSize + node.element.getNodeSize()
    }
    
    private func getHeight(node: TreeNode<E>?) -> Int {
        guard let notNilNode = node else {
            return 0;
        }
        return notNilNode.height
    }
    
    private func getBalance(node: TreeNode<E>) -> Int {
        return getHeight(node: node.left) - getHeight(node: node.right)
    }
    
    private func leftLeft(node: TreeNode<E>) throws -> TreeNode<E> {
        return try rightRotate(node: node)
    }
    
    private func leftRight(node: TreeNode<E>) throws -> TreeNode<E> {
        node.left = try leftRotate(node: node.left!)
        return try rightRotate(node: node)
    }
    
    private func rightRight(node: TreeNode<E>) throws -> TreeNode<E> {
        return try leftRotate(node: node)
    }
    
    private func rightLeft(node: TreeNode<E>) throws -> TreeNode<E> {
        node.right = try rightRotate(node: node.right!)
        return try leftRotate(node: node)
    }
    
    private func rightRotate(node: TreeNode<E>) throws -> TreeNode<E> {
        guard let notNilLeft = node.left else {
            throw TreeAccessError.InvalidNode
        }
        let newNode = notNilLeft
        newNode.parent = node.parent
        let rightNode = newNode.right
        newNode.right = node
        node.parent = newNode
        node.left = rightNode
        rightNode?.parent = node
        updateNodeSize(node: node)
        updateNodeSize(node: newNode)
        updateNodeHeight(node: node)
        updateNodeHeight(node: newNode)
        return newNode
    }
    
    private func leftRotate(node: TreeNode<E>) throws -> TreeNode<E> {
        guard let notNilRight = node.right else {
            throw TreeAccessError.InvalidNode
        }
        let newNode = notNilRight
        newNode.parent = node.parent
        let leftNode = newNode.left
        newNode.left = node
        node.parent = newNode
        node.right = leftNode
        leftNode?.parent = node
        updateNodeSize(node: node)
        updateNodeSize(node: newNode)
        updateNodeHeight(node: node)
        updateNodeHeight(node: newNode)
        return newNode
    }
}

// MARK: - AVLTree copy
extension AVLTree {
    func copy() -> AVLTree<E> {
        let clone = AVLTree()
        clone.root = self.root?.copy()
        return clone
    }
}
