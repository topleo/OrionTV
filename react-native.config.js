// These Android download helpers and the unused WebKit cookie module have no tvOS target.
module.exports = {
  dependencies: process.env.EXPO_TV === '1' ? {
    '@react-native-cookies/cookies': { platforms: { ios: null } },
    'react-native-blob-util': { platforms: { ios: null } },
    'react-native-file-viewer': { platforms: { ios: null } },
  } : {},
};
