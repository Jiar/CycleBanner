Pod::Spec.new do |s|
  s.name = 'CycleBanner'
  s.version = '1.0'
  s.summary = 'Infinite horizontal scrolling control.'
  s.homepage = 'https://github.com/Jiar/CycleBanner'
  s.license = { :type => "Apache-2.0", :file => "LICENSE" }
  s.author = { "Jiar" => "jiar.world@gmail.com" }
  s.ios.deployment_target = '9.0'
  s.source = { :git => "https://github.com/Jiar/CycleBanner.git", :tag => "#{s.version}" }
  s.source_files = 'CycleBanner/*.swift'
  s.module_name = 'CycleBanner'
end
