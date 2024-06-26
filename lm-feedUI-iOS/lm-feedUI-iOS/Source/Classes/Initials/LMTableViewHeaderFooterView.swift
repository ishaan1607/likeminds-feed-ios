//
//  LMTableViewHeaderFooterView.swift
//  LMFramework
//
//  Created by Devansh Mohata on 15/12/23.
//

import UIKit

open class LMTableViewHeaderFooterView: UITableViewHeaderFooterView { 
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        setupViews()
        setupLayouts()
        setupActions()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setupAppearance()
    }
}

@objc
extension LMTableViewHeaderFooterView: LMViewLifeCycle {
    open func setupViews() { }
    
    open func setupLayouts() { }
    
    open func setupActions() { }
    
    open func setupAppearance() { }
    
    open func setupObservers() { }
}
