# Generates only the standalone native target; Expo's project is untouched.
require 'xcodeproj'
require 'pathname'
root = Pathname.new(__dir__)
project = Xcodeproj::Project.new(root.join('OrionTVNative.xcodeproj'))
target = project.new_target(:application, 'OrionTVNative', :tvos, '17.0')
sources = project.main_group.new_group('Sources', 'Sources')
files = root.join('Sources').children.select { |p| p.extname == '.swift' }.sort.map { |p| sources.new_file(p.basename.to_s) }
target.add_file_references(files)
assets = project.main_group.new_file('Assets.xcassets')
target.resources_build_phase.add_file_reference(assets)
project.main_group.new_file('Info.plist')
target.build_configurations.each do |configuration|
  configuration.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.oriontv.native',
    'PRODUCT_NAME' => 'OrionTVNative',
    'INFOPLIST_FILE' => 'Info.plist',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'SWIFT_VERSION' => '5.0',
    'TVOS_DEPLOYMENT_TARGET' => '17.0',
    'TARGETED_DEVICE_FAMILY' => '3',
    'CODE_SIGN_STYLE' => 'Automatic',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'TVAppIcon',
    'SUPPORTED_PLATFORMS' => 'appletvos appletvsimulator',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks /usr/lib/swift'
  })
end
project.save
