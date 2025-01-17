import UIKit
import SwiftUI

class SavedRulesViewController: UIViewController {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
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
    
    private var savedRules: [Int] = [] {
        didSet {
            saveRulesToUserDefaults()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updateBackgroundImage()
        loadSavedRules()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: NSNotification.Name("RulesUpdated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBackgroundImage),
            name: NSNotification.Name("ThemeChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func saveRule(_ ruleIndex: Int) {
        if !savedRules.contains(ruleIndex) {
            savedRules.append(ruleIndex)
            tableView.reloadData()
        }
    }
    
    private func saveRulesToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedRules) {
            UserDefaults.standard.set(encoded, forKey: "savedRules")
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc private func reloadData() {
        loadSavedRules()
        tableView.reloadData()
    }
    
    private func loadSavedRules() {
        if let data = UserDefaults.standard.data(forKey: "savedRules"),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            savedRules = decoded
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
    
    private func setupNavigationBar() {
        title = "Saved Rules"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension SavedRulesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedRules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RuleCell.identifier, for: indexPath) as? RuleCell else {
            return UITableViewCell()
        }
        
        let ruleIndex = savedRules[indexPath.row]
        if let ruleText = getLocalizedRules()[safe: ruleIndex] {
            cell.configure(with: Rule(name: ruleText, description: ""), index: ruleIndex, isSaved: true) { [weak self] in
                self?.savedRules.removeAll(where: { $0 == ruleIndex })
                self?.tableView.reloadData()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            savedRules.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ruleIndex = savedRules[indexPath.row]
        if let ruleText = getLocalizedRules()[safe: ruleIndex] {
            let alert = UIAlertController(title: "Rule", message: ruleText, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
