# Uncomment the next line to define a global platform for your project
platform :ios, '12.1'

use_frameworks!

def common_pods
  pod 'ReactorKit'
  pod 'SnapKit', '~> 5.0'
  pod 'Then'
  pod 'Pure'

  pod 'RxSwift', '~> 5.0'
  pod 'RxSwiftExt', '~> 5.0'
  pod 'RxCocoa', '~> 5.0'

  pod 'RxViewController'
  pod 'RxDataSources', '~> 4.0'

  pod 'Alamofire', '~> 5.0.0-beta.7'
  pod 'Moya/RxSwift', '~> 14.0.0-alpha.2'

  pod 'KeychainAccess', '~> 3.2.0'

  pod 'SwiftLint', :configurations => ['Debug']
end

target 'worktime' do
  common_pods

  pod 'Carte'
  pod 'GoogleSignIn'

  pod 'RxKeyboard'
end

target 'worktime-noti-content' do
  common_pods
end
