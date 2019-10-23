import 'interpolator.dart';
import 'options.dart';
import 'plural_resolver.dart';
import 'resource_store.dart';

class Translator {
  Translator(this.resourceStore)
      : assert(resourceStore != null),
        interpolator = Interpolator(),
        pluralResolver = PluralResolver();

  final ResourceStore resourceStore;
  final Interpolator interpolator;
  final PluralResolver pluralResolver;

  String translate(String key, I18NextOptions options) {
    assert(key != null);
    assert(options != null);

    String namespace = '', keyPath = key;
    final match = RegExp(options.namespaceSeparator).firstMatch(key);
    if (match != null) {
      namespace = key.substring(0, match.start);
      keyPath = key.substring(match.end);
    }
    return translateKey(namespace, keyPath, options);
  }

  /// Order of key resolution:
  ///
  /// - context + pluralization:
  ///   ['key_ctx_plr', 'key_ctx', 'key_plr', 'key']
  /// - context only:
  ///   ['key_ctx', 'key']
  /// - pluralization only:
  ///   ['key_plr', 'key']
  /// - Otherwise:
  ///   ['key']
  String translateKey(String namespace, String key, I18NextOptions options) {
    final context = options.context;
    final count = options.count;
    final needsContext = context != null && context.isNotEmpty;
    final needsPlural = count != null;

    String pluralSuffix;
    if (needsPlural) pluralSuffix = pluralResolver.pluralize(count, options);

    String tempKey = key;
    final List<String> keys = [key];
    if (needsContext && needsPlural) {
      keys.add(tempKey + pluralSuffix);
    }
    if (needsContext) {
      keys.add(tempKey += '${options.contextSeparator}$context');
    }
    if (needsPlural) {
      keys.add(tempKey += pluralSuffix);
    }

    String result;
    while (keys.isNotEmpty) {
      final currentKey = keys.removeLast();
      final found = find(namespace, currentKey, options);
      if (found != null) {
        result = found;
        break;
      }
    }
    return result;
  }

  /// Attempts to find the value given a [namespace] and [key].
  ///
  /// If one is not found directly, then tries to fallback (if necessary). May
  /// still return null if none is found.
  String find(String namespace, String key, I18NextOptions options) {
    final value = resourceStore.retrieve(namespace, key, options);
    if (value == null) {
      // TODO: fallback locales
      // TODO: fallback namespaces
      // TODO: fallback to default value
    }

    String result;
    if (value != null) {
      result = interpolator.interpolate(value, options);
      result = interpolator.nest(result, translate, options);
    }
    return result;
  }
}
