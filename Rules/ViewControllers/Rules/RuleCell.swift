//RuleCell.swift
import UIKit
import SwiftUI

class RuleCell: UITableViewCell {
    static let identifier = "RuleCell"
    private var index: Int = 0
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(ThemeManager.colors.primary).withAlphaComponent(0.9)
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(ThemeManager.colors.lightText)
        label.font = UIFont(name: "Lato-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = UIColor(ThemeManager.colors.lightText)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var deleteAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        applyTheme()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyTheme),
            name: NSNotification.Name("ThemeChanged"),
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    @objc private func applyTheme() {
        containerView.backgroundColor = UIColor(ThemeManager.colors.primary).withAlphaComponent(0.9)
        titleLabel.textColor = UIColor(ThemeManager.colors.lightText)
        deleteButton.tintColor = UIColor(ThemeManager.colors.accent)
    }
    
    @objc private func deleteButtonTapped() {
        deleteAction?()
    }
    
    func configure(with rule: Rule, index: Int, deleteAction: @escaping () -> Void) {
        titleLabel.text = rule.name
        self.index = index
        self.deleteAction = deleteAction
    }
}
