//MyRulesViewController.swift
//lista dodanych wlasnych zasad 
import UIKit
import SwiftUI
import Foundation

class MyRulesViewController: UIViewController {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(RuleCell.self, forCellReuseIdentifier: RuleCell.identifier)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        return table
    }()
    
    private let addButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Custom Rule", for: .normal)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()
    
    private var customRules: [Rule] = [] {
        didSet {
            saveCustomRules()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updateBackgroundImage()
        loadCustomRules()
        applyTheme()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: NSNotification.Name("LanguageChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: NSNotification.Name("CustomRulesUpdated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBackgroundImage),
            name: NSNotification.Name("ThemeChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyTheme),
            name: NSNotification.Name("ThemeChanged"),
            object: nil
        )
        
        addButton.addTarget(self, action: #selector(addCustomRuleTapped), for: .touchUpInside)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applyTheme() {
        let theme = ThemeManager.colors
        addButton.backgroundColor = UIColor(theme.primary)
        addButton.setTitleColor(UIColor(theme.lightText), for: .normal)
    }
    
    @objc private func reloadData() {
        loadCustomRules()
        tableView.reloadData()
    }
    
    private func loadCustomRules() {
        if let data = UserDefaults.standard.data(forKey: "customRules"),
           let decoded = try? JSONDecoder().decode([Rule].self, from: data) {
            customRules = decoded
        }
    }
    
    private func saveCustomRules() {
        do {
            let encoded = try JSONEncoder().encode(customRules)
            UserDefaults.standard.set(encoded, forKey: "customRules")
        } catch {
            print("Error saving rules: \(error.localizedDescription)")
        }
    }
    
    @objc public func updateBackgroundImage() {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        let imageName: String
        
        switch theme {
        case .classic: imageName = isDarkMode ? "imageDark" : "Image"
        case .mountain: imageName = isDarkMode ? "mountain-bg-dark" : "mountain-bg"
        case .beach: imageName = isDarkMode ? "beach-bg-dark" : "beach-bg"
        case .desert: imageName = isDarkMode ? "desert-bg-dark" : "desert-bg"
        case .forest: imageName = isDarkMode ? "forest-bg-dark" : "forest-bg"
        }
        
        backgroundImageView.image = UIImage(named: imageName)
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -20),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupNavigationBar() {
        title = "My Rules"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
    
    @objc private func addCustomRuleTapped() {
        let addRuleView = AddRuleView(onSave: { [weak self] rule in
            self?.customRules.append(rule)
            self?.tableView.reloadData()
            NotificationCenter.default.post(name: NSNotification.Name("CustomRulesUpdated"), object: nil)
        })
        
        let hostingController = UIHostingController(rootView: addRuleView)
        present(hostingController, animated: true)
    }
}

extension MyRulesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customRules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RuleCell.identifier, for: indexPath) as? RuleCell else {
            return UITableViewCell()
        }
        
        let rule = customRules[indexPath.row]
        cell.configure(with: rule, index: indexPath.row) { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(
                title: "Delete Rule",
                message: "Are you sure you want to delete this rule?",
                preferredStyle: .alert
            )
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                
                self.customRules.remove(at: indexPath.row)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }, completion: { _ in
                    self.tableView.reloadData()
                })
                
                NotificationCenter.default.post(name: NSNotification.Name("CustomRulesUpdated"), object: nil)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rule = customRules[indexPath.row]
        let alert = UIAlertController(title: rule.name, message: rule.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
