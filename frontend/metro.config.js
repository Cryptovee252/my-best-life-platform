const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Disable SSR for web to prevent hydration issues
config.resolver.platforms = ['ios', 'android', 'native', 'web'];

// Web-specific configuration
config.transformer.minifierConfig = {
  keep_fnames: true,
  mangle: {
    keep_fnames: true,
  },
};

// Disable static rendering for web
config.transformer.unstable_allowRequireContext = true;

module.exports = config;
