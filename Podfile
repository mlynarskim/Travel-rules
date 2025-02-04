platform :ios, '13.0'

install! 'cocoapods',
         :deterministic_uuids => false,
         :integrate_targets => true,
         :generate_multiple_pod_projects => false

source 'https://cdn.cocoapods.org/'
#source 'https://github.com/CocoaPods/Specs.git'

target 'Rules' do
  use_frameworks!

  # Firebase
  pod 'Firebase/Auth'
  pod 'Firebase/Analytics'
  pod 'Firebase/Firestore'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  
  # Google
  pod 'Google-Mobile-Ads-SDK'
  pod 'GoogleSignIn'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        # Usuń tę linię, może powodować problemy:
        # config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end
