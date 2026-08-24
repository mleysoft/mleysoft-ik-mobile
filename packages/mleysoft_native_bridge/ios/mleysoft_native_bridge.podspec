Pod::Spec.new do |s|
  s.name             = 'mleysoft_native_bridge'
  s.version          = '1.0.0'
  s.summary          = 'MleySoft IK native iOS bridge.'
  s.description      = 'Foreground location, notification permission and app badge bridge for MleySoft IK.'
  s.homepage         = 'https://mleysoft.com'
  s.license          = { :type => 'Proprietary', :text => 'Copyright MleySoft' }
  s.author           = { 'MleySoft' => 'info@mleysoft.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
