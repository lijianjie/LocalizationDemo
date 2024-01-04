source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'LocalizationDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for LocalizationDemo
  pod 'JKSwiftExtension'
  pod 'SnapKit'
  
  # 第三方登录
  pod 'GoogleSignIn', '7.0.0'
  pod 'FBSDKLoginKit' '16.2.1'
  
  # DEBUG工具
  pod 'LookinServer', :configurations => ['Debug']

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
