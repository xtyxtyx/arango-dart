enum LoadBalancingStrategy {
  none,
  roundRobin,
  oneRandom,
}

class ArangoConfig {
  ArangoConfig({
    this.url,
    this.urls,
    this.isAbsolute,
    this.arangoVersion,
    this.loadBalancingStrategy,
    this.maxRetries,
    this.headers,
    // this.agent,
    // this.agentOptions,
  });

  final String url;
  final List<String> urls;
  final bool isAbsolute;
  final int arangoVersion;
  final LoadBalancingStrategy loadBalancingStrategy;
  final int maxRetries;
  final Map<String, String> headers;
  // dynamic agent;
  // Map<String, dynamic> agentOptions;
}
