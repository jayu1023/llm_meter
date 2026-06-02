import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  group('openAiUsage', () {
    test('parses standard chat completion usage', () {
      final MeterUsage u = openAiUsage(<String, Object?>{
        'usage': <String, Object?>{
          'prompt_tokens': 1000,
          'completion_tokens': 500,
        },
      });
      expect(u.tokensIn, 1000);
      expect(u.tokensOut, 500);
      expect(u.cachedTokensIn, 0);
    });

    test('splits cached tokens out of prompt_tokens', () {
      final MeterUsage u = openAiUsage(<String, Object?>{
        'usage': <String, Object?>{
          'prompt_tokens': 1000,
          'completion_tokens': 500,
          'prompt_tokens_details': <String, Object?>{'cached_tokens': 400},
        },
      });
      expect(u.tokensIn, 600);
      expect(u.cachedTokensIn, 400);
    });

    test('returns empty when no usage block', () {
      expect(openAiUsage(<String, Object?>{}), MeterUsage.empty);
    });
  });

  group('anthropicUsage', () {
    test('parses standard messages usage', () {
      final MeterUsage u = anthropicUsage(<String, Object?>{
        'usage': <String, Object?>{
          'input_tokens': 1000,
          'output_tokens': 500,
        },
      });
      expect(u.tokensIn, 1000);
      expect(u.tokensOut, 500);
    });

    test('reads cache_read_input_tokens', () {
      final MeterUsage u = anthropicUsage(<String, Object?>{
        'usage': <String, Object?>{
          'input_tokens': 200,
          'output_tokens': 50,
          'cache_read_input_tokens': 800,
        },
      });
      expect(u.tokensIn, 200);
      expect(u.cachedTokensIn, 800);
    });
  });

  group('geminiUsage', () {
    test('parses standard generateContent usage', () {
      final MeterUsage u = geminiUsage(<String, Object?>{
        'usageMetadata': <String, Object?>{
          'promptTokenCount': 1000,
          'candidatesTokenCount': 500,
        },
      });
      expect(u.tokensIn, 1000);
      expect(u.tokensOut, 500);
    });

    test('splits cachedContentTokenCount out of promptTokenCount', () {
      final MeterUsage u = geminiUsage(<String, Object?>{
        'usageMetadata': <String, Object?>{
          'promptTokenCount': 1000,
          'candidatesTokenCount': 500,
          'cachedContentTokenCount': 700,
        },
      });
      expect(u.tokensIn, 300);
      expect(u.cachedTokensIn, 700);
    });

    test('tolerates numeric strings', () {
      final MeterUsage u = geminiUsage(<String, Object?>{
        'usageMetadata': <String, Object?>{
          'promptTokenCount': '1234',
          'candidatesTokenCount': '56',
        },
      });
      expect(u.tokensIn, 1234);
      expect(u.tokensOut, 56);
    });
  });
}
