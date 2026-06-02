import 'package:flutter_test/flutter_test.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  group('pricingFor — known models', () {
    test(r'gpt-5 matches OpenAI list price ($1.25 / $10 per 1M)', () {
      final ModelPricing p = pricingFor('gpt-5');
      expect(p.inputRate, closeTo(1.25 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(10.0 / 1000000, 1e-12));
      expect(p.cachedInputRate, closeTo(0.125 / 1000000, 1e-12));
    });

    test('gpt-5-mini matches list price', () {
      final ModelPricing p = pricingFor('gpt-5-mini');
      expect(p.inputRate, closeTo(0.25 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(2.0 / 1000000, 1e-12));
    });

    test('gpt-5-nano matches list price', () {
      final ModelPricing p = pricingFor('gpt-5-nano');
      expect(p.inputRate, closeTo(0.05 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(0.40 / 1000000, 1e-12));
    });

    test('gpt-4.1 matches list price', () {
      final ModelPricing p = pricingFor('gpt-4.1');
      expect(p.inputRate, closeTo(2.0 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(8.0 / 1000000, 1e-12));
    });

    test('gpt-4o matches list price', () {
      final ModelPricing p = pricingFor('gpt-4o');
      expect(p.inputRate, closeTo(2.50 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(10.0 / 1000000, 1e-12));
    });

    test('gpt-4o-mini matches list price', () {
      final ModelPricing p = pricingFor('gpt-4o-mini');
      expect(p.inputRate, closeTo(0.15 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(0.60 / 1000000, 1e-12));
    });

    test('o3 matches list price', () {
      final ModelPricing p = pricingFor('o3');
      expect(p.outputRate, closeTo(8.0 / 1000000, 1e-12));
    });

    test('o4-mini matches list price', () {
      final ModelPricing p = pricingFor('o4-mini');
      expect(p.outputRate, closeTo(4.40 / 1000000, 1e-12));
    });

    test(r'claude-opus-4-7 matches Anthropic list price ($15 / $75 per 1M)', () {
      final ModelPricing p = pricingFor('claude-opus-4-7');
      expect(p.inputRate, closeTo(15.0 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(75.0 / 1000000, 1e-12));
      expect(p.cachedInputRate, closeTo(1.50 / 1000000, 1e-12));
    });

    test(r'claude-sonnet-4-6 matches list price ($3 / $15 per 1M)', () {
      final ModelPricing p = pricingFor('claude-sonnet-4-6');
      expect(p.inputRate, closeTo(3.0 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(15.0 / 1000000, 1e-12));
      expect(p.cachedInputRate, closeTo(0.30 / 1000000, 1e-12));
    });

    test('claude-haiku-4-5 matches list price', () {
      final ModelPricing p = pricingFor('claude-haiku-4-5');
      expect(p.outputRate, closeTo(5.0 / 1000000, 1e-12));
    });

    test('gemini-2.5-pro matches Google list price', () {
      final ModelPricing p = pricingFor('gemini-2.5-pro');
      expect(p.inputRate, closeTo(1.25 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(10.0 / 1000000, 1e-12));
    });

    test('gemini-2.5-flash matches list price', () {
      final ModelPricing p = pricingFor('gemini-2.5-flash');
      expect(p.outputRate, closeTo(2.50 / 1000000, 1e-12));
    });

    test('gemini-2.0-flash matches list price', () {
      final ModelPricing p = pricingFor('gemini-2.0-flash');
      expect(p.inputRate, closeTo(0.10 / 1000000, 1e-12));
    });

    test('llama-3.3-70b matches hosted list price', () {
      final ModelPricing p = pricingFor('llama-3.3-70b');
      expect(p.outputRate, closeTo(0.79 / 1000000, 1e-12));
    });

    test('mistral-large matches list price', () {
      final ModelPricing p = pricingFor('mistral-large');
      expect(p.outputRate, closeTo(6.0 / 1000000, 1e-12));
    });

    test('grok-4 matches xAI list price', () {
      final ModelPricing p = pricingFor('grok-4');
      expect(p.outputRate, closeTo(15.0 / 1000000, 1e-12));
    });

    test('deepseek-v3 matches list price', () {
      final ModelPricing p = pricingFor('deepseek-v3');
      expect(p.inputRate, closeTo(0.27 / 1000000, 1e-12));
      expect(p.outputRate, closeTo(1.10 / 1000000, 1e-12));
    });

    test('command-r-plus matches Cohere list price', () {
      final ModelPricing p = pricingFor('command-r-plus');
      expect(p.outputRate, closeTo(10.0 / 1000000, 1e-12));
    });
  });

  group('pricingFor — id normalization', () {
    test('strips provider prefix from OpenRouter-style ids', () {
      expect(pricingFor('openai/gpt-5'), pricingFor('gpt-5'));
      expect(pricingFor('anthropic/claude-sonnet-4-6'), pricingFor('claude-sonnet-4-6'));
      expect(pricingFor('google/gemini-2.5-flash'), pricingFor('gemini-2.5-flash'));
    });

    test('is case insensitive', () {
      expect(pricingFor('GPT-5'), pricingFor('gpt-5'));
      expect(pricingFor('Claude-Opus-4-7'), pricingFor('claude-opus-4-7'));
    });

    test('strips Anthropic dated suffix', () {
      expect(
        pricingFor('claude-3-5-sonnet-20241022'),
        pricingFor('claude-3-5-sonnet'),
      );
    });

    test('alias map: gpt5 -> gpt-5', () {
      expect(pricingFor('gpt5'), pricingFor('gpt-5'));
    });

    test('alias map: gemini-2-5-pro -> gemini-2.5-pro', () {
      expect(pricingFor('gemini-2-5-pro'), pricingFor('gemini-2.5-pro'));
    });

    test('prefix fallback: gpt-5-mini-2026-05-01 -> gpt-5-mini', () {
      expect(
        pricingFor('gpt-5-mini-2026-05-01'),
        pricingFor('gpt-5-mini'),
      );
    });

    test('unknown model returns free pricing', () {
      final ModelPricing p = pricingFor('not-a-real-model-xyz');
      expect(p, ModelPricing.free);
      expect(p.inputRate, 0);
      expect(p.outputRate, 0);
    });

    test('user overrides take precedence over built-ins', () {
      const ModelPricing custom = ModelPricing.perMillion(
        inputPerMillion: 99.0,
        outputPerMillion: 99.0,
      );
      final ModelPricing p =
          pricingFor('gpt-5', overrides: <String, ModelPricing>{'gpt-5': custom});
      expect(p, custom);
    });

    test('user override for unknown model resolves to the override', () {
      const ModelPricing custom = ModelPricing.perMillion(
        inputPerMillion: 1.0,
        outputPerMillion: 2.0,
      );
      final ModelPricing p = pricingFor(
        'my-fine-tune-v2',
        overrides: <String, ModelPricing>{'my-fine-tune-v2': custom},
      );
      expect(p, custom);
    });
  });

  group('priceForModel — cost math', () {
    test(r'gpt-5 — 1000 in / 2000 out = $0.02125', () {
      final double cost = priceForModel(
        model: 'gpt-5',
        tokensIn: 1000,
        tokensOut: 2000,
      );
      // 1000 * 1.25e-6 + 2000 * 10e-6 = 0.00125 + 0.020 = 0.02125
      expect(cost, closeTo(0.02125, 1e-9));
    });

    test('claude-sonnet-4-6 — 10k in / 5k out / 50k cached', () {
      final double cost = priceForModel(
        model: 'claude-sonnet-4-6',
        tokensIn: 10000,
        tokensOut: 5000,
        cachedTokensIn: 50000,
      );
      // 10000 * 3e-6 + 5000 * 15e-6 + 50000 * 0.30e-6
      // = 0.03 + 0.075 + 0.015 = 0.12
      expect(cost, closeTo(0.12, 1e-9));
    });

    test('cache discount applied when cachedInputRate is set', () {
      final double withCache = priceForModel(
        model: 'gpt-5',
        tokensIn: 0,
        tokensOut: 0,
        cachedTokensIn: 1000000,
      );
      // 1M cached * 0.125e-6 = 0.125
      expect(withCache, closeTo(0.125, 1e-9));
    });

    test('cached tokens fall back to input rate when no cachedInputRate', () {
      final double cost = priceForModel(
        model: 'mistral-large',
        tokensIn: 0,
        tokensOut: 0,
        cachedTokensIn: 1000000,
      );
      // Mistral large has no cache discount; cache billed at input rate ($2/1M).
      expect(cost, closeTo(2.0, 1e-9));
    });

    test('zero tokens => zero cost', () {
      expect(
        priceForModel(model: 'gpt-5', tokensIn: 0, tokensOut: 0),
        0.0,
      );
    });

    test('unknown model => zero cost', () {
      expect(
        priceForModel(model: 'not-a-model', tokensIn: 1000, tokensOut: 1000),
        0.0,
      );
    });

    test('overrides flow through priceForModel', () {
      final double cost = priceForModel(
        model: 'my-model',
        tokensIn: 1000,
        tokensOut: 1000,
        overrides: <String, ModelPricing>{
          'my-model': const ModelPricing.perMillion(
            inputPerMillion: 1.0,
            outputPerMillion: 2.0,
          ),
        },
      );
      // 1000 * 1e-6 + 1000 * 2e-6 = 0.003
      expect(cost, closeTo(0.003, 1e-9));
    });
  });

  group('builtInModels', () {
    test('exposes >=30 canonical model ids', () {
      expect(builtInModels.length, greaterThanOrEqualTo(30));
    });

    test('contains the headliners from each provider family', () {
      expect(builtInModels, containsAll(<String>[
        'gpt-5',
        'claude-opus-4-7',
        'claude-sonnet-4-6',
        'gemini-2.5-pro',
        'llama-3.3-70b',
        'mistral-large',
        'grok-4',
        'deepseek-v3',
      ]));
    });

    test('list is unmodifiable', () {
      expect(
        () => builtInModels.add('hacked'),
        throwsUnsupportedError,
      );
    });
  });
}
