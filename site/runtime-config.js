(function loadVtbRuntimeConfig() {
  const placeholderPrefix = '__VTB_';
  const readConfiguredValue = (value, fallback = '') => {
    if (typeof value !== 'string') {
      return fallback;
    }

    const trimmed = value.trim();
    if (!trimmed || trimmed.startsWith(placeholderPrefix)) {
      return fallback;
    }

    return trimmed;
  };

  window.__VTB_RUNTIME_CONFIG__ = Object.freeze({
    publicAppUrl: readConfiguredValue('https://src-assistant.github.io/vtbot'),
    publicBasePath: readConfiguredValue('/vtbot/', '/'),
    apiBaseUrl: readConfiguredValue('https://vtb-api.eigensol.com'),
    nativeAmountDisplayDecimals: readConfiguredValue('6'),
  });
})();
