require 'xcodeproj'
require 'pathname'
root=Pathname.new(ARGV.fetch(0)).expand_path
root.mkpath
native=Pathname.new(__dir__).join('../..').realpath
info=Xcodeproj::Plist.read_from_path(native.join('Info.plist').to_s)
info['OrionServerURL']='http://127.0.0.1:18087'
info['CFBundleSupportedPlatforms']=['AppleTVSimulator']
Xcodeproj::Plist.write_to_path(info,root.join('Info.plist').to_s)
FileUtils.cp(Pathname.new(__dir__).join('NavigationUITests.swift'),root)
p=Xcodeproj::Project.new(root.join('Validation.xcodeproj'))
a=p.new_target(:application,'Preview',:tvos,'18.0')
a.add_file_references(Dir[native.join('Sources/*.swift').to_s].map { |s| p.main_group.new_file(s) })
a.resources_build_phase.add_file_reference(p.main_group.new_file(native.join('Assets.xcassets').to_s))
a.build_configurations.each { |c| c.build_settings.merge!({'PRODUCT_BUNDLE_IDENTIFIER'=>'com.oriontv.layout-preview','INFOPLIST_FILE'=>'Info.plist','SWIFT_VERSION'=>'5.0','TARGETED_DEVICE_FAMILY'=>'3','ASSETCATALOG_COMPILER_APPICON_NAME'=>'TVAppIcon','SUPPORTED_PLATFORMS'=>'appletvsimulator','CODE_SIGN_IDENTITY'=>'-','LD_RUNPATH_SEARCH_PATHS'=>'$(inherited) @executable_path/Frameworks /usr/lib/swift'}) }
t=p.new_target(:ui_test_bundle,'NavigationTests',:tvos,'18.0')
t.add_file_references([p.main_group.new_file('NavigationUITests.swift')])
t.add_dependency(a)
t.build_configurations.each { |c| c.build_settings.merge!({'PRODUCT_BUNDLE_IDENTIFIER'=>'com.oriontv.navigation-tests','GENERATE_INFOPLIST_FILE'=>'YES','SWIFT_VERSION'=>'5.0','TARGETED_DEVICE_FAMILY'=>'3','TEST_TARGET_NAME'=>'Preview','CODE_SIGN_IDENTITY'=>'-'}) }
p.save
s=Xcodeproj::XCScheme.new
s.add_build_target(a)
s.add_build_target(t)
s.add_test_target(t)
s.set_launch_target(a)
s.save_as(p.path,'Validation',true)
