platform :ios, '15.0'

install! 'cocoapods',
  :deterministic_uuids => false,
  :integrate_targets => true,
  :generate_multiple_pod_projects => false

source 'https://cdn.cocoapods.org/'

target 'Rules' do
  use_frameworks!

  # --- Firebase ---
 # pod 'Firebase/Auth'
  #pod 'Firebase/Analytics'
  #pod 'Firebase/Database'
  #pod 'Firebase/Storage'
  #pod 'Firebase/Messaging'
  #pod 'Firebase/Firestore'
  #pod 'FirebaseFirestoreSwift'

  # --- Google ---
  pod 'Google-Mobile-Ads-SDK'
 # pod 'GoogleSignIn'

  post_install do |installer|
    installer.pods_project.targets.each do |target|

      # 1) Usuń '-GCC_WARN_INHIBIT_ALL_WARNINGS' z BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC'
        target.source_build_phase.files.each do |file|
          if file.settings && file.settings['COMPILER_FLAGS']
            flags = file.settings['COMPILER_FLAGS'].split
            flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
            file.settings['COMPILER_FLAGS'] = flags.join(' ')
          end
        end
      end

      # 2) Poprawka dla leveldb-library (usuwa błąd double-quoted include
      #    i zapewnia dostęp do <cstdint> z C++17 / libc++)
      if target.name == 'leveldb-library'
        target.build_configurations.each do |config|
          # Wyłącz ostrzeżenie/błąd "double-quoted include"
          config.build_settings['OTHER_CFLAGS'] ||= ['$(inherited)']
          config.build_settings['OTHER_CFLAGS'] << '-Wno-quoted-include-in-framework-header'

          # Wymuś użycie C++17 i libc++
          config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
          config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++17'
        end
      end

      # (Jeśli masz podobny problem z RecaptchaInterop, możesz dopisać:
      # if target.name == 'RecaptchaInterop' ... )
      
    end
  end
end
