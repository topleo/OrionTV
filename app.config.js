// Keep machine-specific signing identifiers outside the shared app configuration.
module.exports = ({ config }) => ({
  ...config,
  ios: {
    ...config.ios,
    ...(process.env.ORION_BUNDLE_IDENTIFIER
      ? { bundleIdentifier: process.env.ORION_BUNDLE_IDENTIFIER }
      : {}),
  },
});
