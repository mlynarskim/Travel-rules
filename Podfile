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
    pod 'Firebase/Database'
    pod 'Firebase/Storage', '10.18.0'
    pod 'Firebase/Messaging'
    pod 'Firebase/Firestore', '10.18.0'  # Change to match FirebaseFirestoreSwift
    pod 'FirebaseFirestoreSwift', '10.18.0'  # Latest 10.x version
    
    # Google
    pod 'Google-Mobile-Ads-SDK'
    pod 'GoogleSignIn'
    
    post_install do |installer|
        installer.pods_project.targets.each do |target|
            if target.name == 'BoringSSL-GRPC'
                target.source_build_phase.files.each do |file|
                    if file.settings && file.settings['COMPILER_FLAGS']
                        flags = file.settings['COMPILER_FLAGS'].split
                        flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
                        file.settings['COMPILER_FLAGS'] = flags.join(' ')
                    end
                end
        end
    end
end
end
