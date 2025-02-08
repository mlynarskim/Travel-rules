//RulesListViewController.swift
//głowny widok z zakładkami
import UIKit
import SwiftUI
import Foundation

class RulesListViewController: UIViewController {
    
    // MARK: - AppStorage
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    
    // MARK: - Motyw
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:   return .classicTheme
        case .mountain:  return .mountainTheme
        case .beach:     return .beachTheme
        case .desert:    return .desertTheme
        case .forest:    return .forestTheme
        }
    }
    
    // MARK: - UI elementy
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            "saved_rules".appLocalized,
            "my_rules".appLocalized
        ])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        
        // Kolory z motywu
        let uiColorPrimary = UIColor(themeColors.primary)
        control.backgroundColor = uiColorPrimary.withAlphaComponent(0.7)
        control.selectedSegmentTintColor = uiColorPrimary
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
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .all
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
    
    // MARK: - Inicjalizacja kontrolerów
    private func setupChildViewControllers() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        view.backgroundColor = .clear
        savedRulesVC.view.backgroundColor = .clear
        myRulesVC.view.backgroundColor = .clear
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
    }
    
    // MARK: - Ustawienia nav bara
    private func setupNavigationBar() {
        // Tytuł "Rules" -> używamy tłumaczenia
        title = "rules".appLocalized
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
    
    // MARK: - Update tła
    @objc public func updateBackgroundImage() {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        let imageName: String
        
        switch theme {
        case .classic:   imageName = isDarkMode ? "classic-bg-dark" : "classic-bg"
        case .mountain:  imageName = isDarkMode ? "mountain-bg-dark" : "mountain-bg"
        case .beach:     imageName = isDarkMode ? "beach-bg-dark" : "beach-bg"
        case .desert:    imageName = isDarkMode ? "desert-bg-dark" : "desert-bg"
        case .forest:    imageName = isDarkMode ? "forest-bg-dark" : "forest-bg"
        }
        
        backgroundImageView.image = UIImage(named: imageName)
        
        // Aktualizacja w child VC, jeśli również muszą mieć zaktualizowane tło
        savedRulesVC.updateBackgroundImage()
        myRulesVC.updateBackgroundImage()
    }
    
    // MARK: - UI Layout
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
    
    // MARK: - Segment zmiana
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        savedRulesVC.view.isHidden = (sender.selectedSegmentIndex != 0)
        myRulesVC.view.isHidden    = (sender.selectedSegmentIndex != 1)
    }
    
    // MARK: - Dodawanie childViewController
    private func add(childViewController: UIViewController) {
        addChild(childViewController)
        childViewController.didMove(toParent: self)
    }
}
