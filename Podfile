source 'https://github.com/CocoaPods/Specs.git'

project 'CellularNetworking'
use_frameworks!

# Pod Definitions
def shared_pods
  # Development related pods
  pod 'SwiftLint', :configuration => 'Debug'

  # Subspec related pods
  pod 'Unbox', '~> 4.0.0'
  pod 'Alamofire', '~> 4.8.2'

  # Dependencies
  pod 'CELLULAR/Locking', '~> 5.1'
end

# iOS Target & Tests
target 'Networking iOS' do
  platform :ios, '10.0'
  shared_pods
  target 'Networking iOSTests' do
    inherit! :search_paths
    shared_pods
  end
end
# tvOS Target & Tests
target 'Networking tvOS' do
  platform :tvos, '10.0'
  shared_pods
  target 'Networking tvOSTests' do
    inherit! :search_paths
    shared_pods
  end
end
# watchOS Target & Tests
target 'Networking watchOS' do
  platform :watchos, '3.0'
  shared_pods
end
