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
    this.headers,
    this.enableRetry = false,
    this.maxRetries,
  });

  final String? url;
  final List<String>? urls;
  final bool? isAbsolute;
  final int? arangoVersion;
  final LoadBalancingStrategy? loadBalancingStrategy;
  final Map<String, String>? headers;
  final bool enableRetry;
  final int? maxRetries;
}
