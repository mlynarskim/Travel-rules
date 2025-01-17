import UIKit
import SwiftUI

class RulesListViewController: UIViewController {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Saved Rules", "My Rules"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = UIColor(Color(hex: "#29606D")).withAlphaComponent(0.7)
        control.selectedSegmentTintColor = UIColor(Color(hex: "#29606D"))
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var savedRulesVC: SavedRulesViewController = {
        let vc = SavedRulesViewController()
        self.add(childViewController: vc)
        return vc
    }()
    
    private lazy var myRulesVC: MyRulesViewController = {
        let vc = MyRulesViewController()
        self.add(childViewController: vc)
        vc.view.isHidden = true
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updateBackgroundImage()
        setupChildViewControllers()
        
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
    
    private func setupChildViewControllers() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        view.backgroundColor = .clear
        savedRulesVC.view.backgroundColor = .clear
        myRulesVC.view.backgroundColor = .clear
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }
    
    private func setupNavigationBar() {
        title = "Rules"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
    
    @objc public func updateBackgroundImage() {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        let imageName: String
        
        switch theme {
        case .classic: imageName = isDarkMode ? "classic-bg-dark" : "classic-bg"
        case .mountain: imageName = isDarkMode ? "mountain-bg-dark" : "mountain-bg"
        case .beach: imageName = isDarkMode ? "beach-bg-dark" : "beach-bg"
        case .desert: imageName = isDarkMode ? "desert-bg-dark" : "desert-bg"
        case .forest: imageName = isDarkMode ? "forest-bg-dark" : "forest-bg"
        }
        
        backgroundImageView.image = UIImage(named: imageName)
        savedRulesVC.updateBackgroundImage()
        myRulesVC.updateBackgroundImage()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        containerView.backgroundColor = .clear
        
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        view.addSubview(containerView)
        view.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupChildViewsConstraints()
    }
    
    private func setupChildViewsConstraints() {
        containerView.addSubview(savedRulesVC.view)
        containerView.addSubview(myRulesVC.view)
        
        savedRulesVC.view.translatesAutoresizingMaskIntoConstraints = false
        myRulesVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            savedRulesVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            savedRulesVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            savedRulesVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            savedRulesVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            myRulesVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            myRulesVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            myRulesVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            myRulesVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        savedRulesVC.view.isHidden = sender.selectedSegmentIndex != 0
        myRulesVC.view.isHidden = sender.selectedSegmentIndex != 1
    }
    
    private func add(childViewController: UIViewController) {
        addChild(childViewController)
        childViewController.didMove(toParent: self)
    }
}
