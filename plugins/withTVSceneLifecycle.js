const { withAppDelegate, withInfoPlist } = require('@expo/config-plugins');

const nativeControls = require('fs').readFileSync(require('path').join(__dirname, 'OrionTVNativeControls.mm'), 'utf8');

const sceneDelegate = require('fs').readFileSync(require('path').join(__dirname, 'OrionTVSceneDelegate.mm'), 'utf8');

/** Preserve Expo's root window while adopting the scene lifecycle required by tvOS 27. */
module.exports = function withTVSceneLifecycle(config) {
  if (process.env.EXPO_TV !== '1') return config;
  config = withInfoPlist(config, (mod) => {
    mod.modResults.NSAppTransportSecurity = {
      ...mod.modResults.NSAppTransportSecurity,
      NSAllowsArbitraryLoads: true,
      NSAllowsLocalNetworking: true,
    };
    mod.modResults.NSLocalNetworkUsageDescription = '连接家中的 LunaTV 服务器并播放局域网视频。';
    mod.modResults.UIApplicationSceneManifest = {
      UIApplicationSupportsMultipleScenes: false,
      UISceneConfigurations: {
        UIWindowSceneSessionRoleApplication: [{
          UISceneConfigurationName: 'Default Configuration',
          UISceneClassName: 'UIWindowScene',
          UISceneDelegateClassName: 'OrionTVSceneDelegate',
        }],
      },
    };
    return mod;
  });
  return withAppDelegate(config, (mod) => {
    if (mod.modResults.language !== 'objcpp' && mod.modResults.language !== 'objc') {
      throw new Error('withTVSceneLifecycle expects the Expo 51 Objective-C AppDelegate.');
    }
    if (!mod.modResults.contents.includes('@interface OrionTVSceneDelegate')) {
      mod.modResults.contents += '\n' + sceneDelegate;
    }
    // Regenerate our own block on every prebuild so native control updates are applied.
    mod.modResults.contents = mod.modResults.contents.replace(/\n\/\/ BEGIN ORION TV CONTROLS[\s\S]*?\/\/ END ORION TV CONTROLS\n?/g, '');
    const legacyControls = mod.modResults.contents.indexOf('\n#if TARGET_OS_TV\n#import <React/RCTViewManager.h>');
    if (legacyControls >= 0) mod.modResults.contents = mod.modResults.contents.slice(0, legacyControls);
    mod.modResults.contents += '\n// BEGIN ORION TV CONTROLS\n' + nativeControls + '\n// END ORION TV CONTROLS\n';
    return mod;
  });
};
