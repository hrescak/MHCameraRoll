Pod::Spec.new do |s|
  s.name     = 'MHCameraRoll'
  s.version  = '0.1.0'
  s.summary  = 'A wrapper somewhat simplifying work with camera roll on iOS, with the option of only loading screenshots, photos or both.'
  s.homepage = 'https://github.com/ijameelkhan/MHCameraRoll.git'

  s.license  = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author   = { 'Christopher Bess' => 'cbess@quantumquinn.com' }
  s.source   = { :git => 'https://github.com/cbess/AutoScrollLabel.git', :tag => 'v0.4.1' }

  s.platform = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'MHCameraRoll/*.{h,m}'
  s.frameworks   = 'QuartzCore', 'CoreGraphics'
  s.screenshots = ''
end
