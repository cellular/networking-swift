Pod::Spec.new do |spec|
    spec.version     = '5.0'
    spec.module_name = 'Networking'
    spec.name        = 'CellularNetworking'
    spec.summary     = 'HTTP Networking Framework in Swift by CELLULAR.'
    spec.homepage    = 'http://www.cellular.de'
    spec.authors     = { 'CELLULAR GmbH' => 'office@cellular.de' }
    spec.license     = { :type => 'MIT', :file => 'LICENSE' }
    spec.source      = { :git => 'https://github.com/cellular/networking-swift.git', :tag => spec.version.to_s }

    # Deployment Targets
    spec.ios.deployment_target     = '9.0'
    spec.tvos.deployment_target    = '9.0'
    spec.watchos.deployment_target = '2.0'

    # Core Subspec

    spec.subspec 'Core' do |sub|
        sub.dependency 'CELLULAR/Result', '~> 4.1.0'
        sub.dependency 'CELLULAR/Locking', '~> 4.1.0'
        sub.source_files = 'Source/Core/**/*.swift'
    end

    # Provider Subspecs

    spec.subspec 'Alamofire' do |sub|
        sub.dependency 'Alamofire', '~> 4.7'
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Source/Provider/Alamofire.swift'
    end

    spec.subspec 'LocalFile' do |sub|
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Source/Provider/Local/*.swift'
    end

    # Serializable Subspecs

    spec.subspec 'Codable' do |sub|
        sub.source_files = 'Source/Serializer/Codable.swift'
    end

    spec.subspec 'Unbox' do |sub|
        sub.dependency 'Unbox', '~> 3.0'
        sub.dependency 'CellularNetworking/Core'
        sub.source_files = 'Source/Serializer/Unbox.swift'
    end

    # Default Subspecs

    spec.default_subspecs = 'Alamofire', 'Codable'
end
