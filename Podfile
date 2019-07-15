source 'https://github.com/CocoaPods/Specs.git'

project 'CellularNetworking'
use_frameworks!

abstract_target 'Networking' do
    
    # Development related pods
    pod 'SwiftLint', :configuration => 'Debug'
    
    # Subspec related pods
    pod 'Unbox', '~> 4.0.0'
    pod 'Alamofire', '~> 4.8.2'

    # Dependencies
    pod 'CELLULAR/Locking', '~> 5.1'

    # Targets & Tests
    target 'Networking iOS' do
        platform :ios, '10.0'
        target 'Networking iOSTests' do
            inherit! :search_paths
        end
    end

    target 'Networking tvOS' do
        platform :tvos, '10.0'
        target 'Networking tvOSTests' do
            inherit! :search_paths
        end
    end

    target 'Networking watchOS' do
        platform :watchos, '3.0'
    end
end
