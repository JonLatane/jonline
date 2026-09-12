import { Occasion } from '@rellm/api';
import { describe, expect, test } from 'vitest';
import { occasionTimeSort, isNotPastOccasion, isPastOccasion, timeSort } from './time';

function occasion(startsAt: string, endsAt: string): Occasion {
  return Occasion.fromPartial({ startsAt, endsAt });
}

describe('timeSort', () => {
  test('orders earlier time before later time', () => {
    expect(timeSort('2020-01-01T00:00:00Z', '2020-01-02T00:00:00Z')).toBe(-1);
  });

  test('orders later time after earlier time', () => {
    expect(timeSort('2020-01-02T00:00:00Z', '2020-01-01T00:00:00Z')).toBe(1);
  });

  test('treats equal times as equal', () => {
    expect(timeSort('2020-01-01T00:00:00Z', '2020-01-01T00:00:00Z')).toBe(0);
  });
});

describe('occasionTimeSort', () => {
  test('sorts by startsAt first', () => {
    const a = occasion('2020-01-01T00:00:00Z', '2020-01-01T01:00:00Z');
    const b = occasion('2020-01-02T00:00:00Z', '2020-01-02T01:00:00Z');
    expect(occasionTimeSort(a, b)).toBe(-1);
  });

  test('falls back to endsAt when startsAt matches', () => {
    const a = occasion('2020-01-01T00:00:00Z', '2020-01-01T01:00:00Z');
    const b = occasion('2020-01-01T00:00:00Z', '2020-01-01T02:00:00Z');
    expect(occasionTimeSort(a, b)).toBe(-1);
  });
});

describe('isPastOccasion / isNotPastOccasion', () => {
  test('an occasion that ended in the past is past', () => {
    const past = occasion('2000-01-01T00:00:00Z', '2000-01-01T01:00:00Z');
    expect(isPastOccasion(past)).toBe(true);
    expect(isNotPastOccasion(past)).toBe(false);
  });

  test('an occasion ending far in the future is not past', () => {
    const future = occasion('2999-01-01T00:00:00Z', '2999-01-01T01:00:00Z');
    expect(isPastOccasion(future)).toBe(false);
    expect(isNotPastOccasion(future)).toBe(true);
  });
});
