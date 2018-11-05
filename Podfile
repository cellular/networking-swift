source 'https://github.com/CocoaPods/Specs.git'

# Project Settings & Options
project 'CellularNetworking'
use_frameworks!

# Dependencies
def shared_pods
    # Development related pods
    pod 'SwiftLint'
    
    # Subspec related pods
    pod 'Unbox'
    pod 'Alamofire'
    pod 'CELLULAR/Locking', '4.1.0'
    pod 'CELLULAR/Result', '4.1.0'
end

# Targets & Tests
target 'Networking iOS' do
    platform :ios, '9.0'
    shared_pods
    target 'Networking iOSTests' do
        inherit! :search_paths
    end
end

target 'Networking tvOS' do
    platform :tvos, '9.0'
    shared_pods
    target 'Networking tvOSTests' do
        inherit! :search_paths
    end
end

target 'Networking watchOS' do
    platform :watchos, '2.0'
    shared_pods
end
