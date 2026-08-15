import { describe, expect, test } from 'vitest';
import { Visibility } from '@jonline/api/generated/visibility_moderation';
import { publicOrPrivateVisibility, publicVisibility } from './visibility_utils';

describe('publicVisibility', () => {
  test('is false when visibility is undefined', () => {
    expect(publicVisibility(undefined)).toBe(false);
  });

  test.each([Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC])(
    '%s is public',
    (visibility) => {
      expect(publicVisibility(visibility)).toBe(true);
    },
  );

  test('PRIVATE is not public', () => {
    expect(publicVisibility(Visibility.PRIVATE)).toBe(false);
  });
});

describe('publicOrPrivateVisibility', () => {
  test('is false when visibility is undefined', () => {
    expect(publicOrPrivateVisibility(undefined)).toBe(false);
  });

  test.each([Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC, Visibility.PRIVATE])(
    '%s is included',
    (visibility) => {
      expect(publicOrPrivateVisibility(visibility)).toBe(true);
    },
  );

  test('LIMITED is not included', () => {
    expect(publicOrPrivateVisibility(Visibility.LIMITED)).toBe(false);
  });
});
