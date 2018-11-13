source 'https://github.com/CocoaPods/Specs.git'

project 'CellularNetworking'
use_frameworks!

abstract_target 'Networking' do
    
    # Development related pods
    pod 'SwiftLint', :configuration => 'Debug'
    
    # Subspec related pods
    pod 'Unbox', '~> 3.0.0'
    pod 'Alamofire', '~> 4.7.3'

    # Dependencies
    pod 'CELLULAR/Locking', '4.1.0'
    pod 'CELLULAR/Result', '4.1.0'

    # Targets & Tests
    target 'Networking iOS' do
        platform :ios, '9.0'
        target 'Networking iOSTests' do
            inherit! :search_paths
        end
    end

    target 'Networking tvOS' do
        platform :tvos, '9.0'
        target 'Networking tvOSTests' do
            inherit! :search_paths
        end
    end

    target 'Networking watchOS' do
        platform :watchos, '2.0'
    end
end
