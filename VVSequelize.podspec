
Pod::Spec.new do |s|
  s.name             = 'VVSequelize'
  s.version          = '0.4.7'
  s.summary          = 'ORM model based on SQLite3.'
  s.description      = <<-DESC
                       ORM model based on SQLite3.
                       DESC

  s.homepage         = 'https://github.com/pozi119/VVSequelize'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Valo Lee' => 'pozi119@163.com' }
  s.source           = { :git => 'https://github.com/pozi119/VVSequelize.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.default_subspec = 'cipher'

  s.subspec 'system' do |ss|
      ss.dependency 'VVSequelize/core'
      ss.dependency 'VVSequelize/fts'
      ss.dependency 'VVSequelize/util'
      ss.libraries = 'sqlite3'
  end
  
  s.subspec 'cipher' do |ss|
      ss.dependency 'VVSequelize/core'
      ss.dependency 'VVSequelize/fts'
      ss.dependency 'VVSequelize/util'
      ss.dependency 'SQLCipher'
      ss.xcconfig = {
          'OTHER_CFLAGS' => '-DSQLITE_HAS_CODEC',
          'HEADER_SEARCH_PATHS' => "{PODS_ROOT}/SQLCipher"
      }
  end

# child specs
  s.subspec 'core' do |ss|
      ss.source_files = 'VVSequelize/Core/**/*'
      ss.public_header_files = 'VVSequelize/Core/**/*.h'
      ss.dependency 'VVSequelize/header'
      ss.xcconfig = { 'OTHER_CFLAGS' => '-DVVSEQUELIZE_CORE' }
  end

  s.subspec 'fts' do |ss|
      ss.source_files = 'VVSequelize/FTS/**/*'
      ss.public_header_files = 'VVSequelize/FTS/**/*.h'
      ss.resource = ['VVSequelize/Assets/VVPinYin.bundle']
      ss.dependency 'VVSequelize/core'
      ss.dependency 'VVSequelize/header'
      ss.xcconfig = { 'OTHER_CFLAGS' => '-DVVSEQUELIZE_FTS' }
  end

  s.subspec 'util' do |ss|
      ss.source_files = 'VVSequelize/Util/**/*'
      ss.public_header_files = 'VVSequelize/Util/**/*.h'
      ss.dependency 'VVSequelize/header'
      ss.xcconfig = { 'OTHER_CFLAGS' => '-DVVSEQUELIZE_UTIL' }
  end

  s.subspec 'header' do |ss|
      ss.source_files = 'VVSequelize/VVSequelize.h'
  end

end
