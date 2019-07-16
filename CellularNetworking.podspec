Pod::Spec.new do |spec|
    spec.version       = '5.1'
    spec.swift_version = '5.0'
    spec.module_name   = 'Networking'
    spec.name          = 'CellularNetworking'
    spec.summary       = 'HTTP Networking Framework in Swift by CELLULAR.'
    spec.homepage      = 'http://www.cellular.de'
    spec.authors       = { 'CELLULAR GmbH' => 'office@cellular.de' }
    spec.license       = { :type => 'MIT', :file => 'LICENSE' }
    spec.source        = { :git => 'https://github.com/cellular/networking-swift.git', :tag => spec.version.to_s }

    # Deployment Targets
    spec.ios.deployment_target     = '10.0'
    spec.tvos.deployment_target    = '10.0'
    spec.watchos.deployment_target = '3.0'

    # Core Subspec

    spec.subspec 'Core' do |sub|
        sub.dependency 'CELLULAR/Locking', '~> 5.1'
        sub.source_files = 'Sources/Networking/Core/**/*.swift'
    end

    # Provider Subspecs

    spec.subspec 'Alamofire' do |sub|
        sub.dependency 'Alamofire', '~> 4.8.2'
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Sources/Networking/Provider/Alamofire.swift'
    end

    spec.subspec 'LocalFile' do |sub|
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Sources/Networking/Provider/Local/*.swift'
    end

    # Serializable Subspecs

    spec.subspec 'Codable' do |sub|
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Sources/Networking/Serializer/Codable.swift'
    end

    spec.subspec 'Unbox' do |sub|
        sub.dependency 'Unbox', '~> 4.0'
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Sources/Networking/Serializer/Unbox.swift'
    end

    # Default Subspecs

    spec.default_subspecs = 'Alamofire', 'Codable'
end
