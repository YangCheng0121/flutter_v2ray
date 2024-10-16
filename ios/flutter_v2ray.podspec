Pod::Spec.new do |s|
  s.name             = 'flutter_v2ray'
  s.version          = '0.0.1'
  s.summary          = '一个用于 V2Ray 集成的 Flutter 插件项目。'
  s.description      = <<-DESC
一个通过静态 .a 库集成 V2Ray 功能的 Flutter 插件。
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  # 依赖 Flutter 框架
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # 指定 Swift 版本
  s.swift_version = '5.0'

  # 添加 .xcframework 支持
  s.vendored_frameworks = 'libs/libv2ray.xcframework'

end
