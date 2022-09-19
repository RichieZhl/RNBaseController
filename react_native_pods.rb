
require 'json'
require 'open3'
require 'pathname'

def use_react_native!(react_version: "0.70.0", flipperkit_version: '0.125.0')

  pod 'React', react_version
  
  pod 'Yoga', :modular_headers => true
  pod 'FlipperKit', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitLayoutComponentKitSupport', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/SKIOSNetworkPlugin', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitUserDefaultsPlugin', '~>' + flipperkit_version, :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitReactPlugin', '~>' + flipperkit_version, :configuration => 'Debug'
  
  pod 'Flipper-DoubleConversion', :configuration => 'Debug'
  pod 'Flipper-Folly', :configuration => 'Debug'
  pod 'Flipper-Glog', :configuration => 'Debug'
  pod 'Flipper-PeerTalk', :configuration => 'Debug'
  pod 'CocoaLibEvent', :configuration => 'Debug'
  pod 'boost-for-react-native', :configuration => 'Debug'
  pod 'OpenSSL-Universal', :configuration => 'Debug'
  pod 'CocoaAsyncSocket', :configuration => 'Debug'
end

def find_and_replace(dir, findstr, replacestr)
  Dir[dir].each do |name|
      text = File.read(name)
      replace = text.gsub(findstr, replacestr)
      if text != replace
          puts "Fix: " + name
          File.open(name, "w") { |file| file.puts replace }
          STDOUT.flush
      end
  end
  Dir[dir + '*/'].each(&method(:find_and_replace))
end

def react_native_post_install(installer)
  if defined? installer.pods_project
    installer.pods_project.targets.each do |target|
        if target.name == 'React'
          target.build_configurations.each do |config|
              config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
              if config.name == "Debug"
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = "$(inherited) COCOAPODS=1 HERMES_ENABLE_DEBUGGER=1 RCT_METRO_PORT=${RCT_METRO_PORT} FB_SONARKIT_ENABLED=1"
              end
          end
        end
        
        if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
          target.build_configurations.each do |config|
              config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
          end
        end
    end

    find_and_replace("Pods/FlipperKit/iOS/FlipperKit/SKMacros.h",
      "#import <FBDefines/FBDefines.h>", "#import \"FBDefines.h\"")
    `cp -f Pods/RCT-Folly/folly/SharedMutex.* Pods/Flipper-Folly/folly/`
  end
end
