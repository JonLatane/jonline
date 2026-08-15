import { EventInstance } from '@jonline/api';
import { describe, expect, test } from 'vitest';
import { instanceTimeSort, isNotPastInstance, isPastInstance, timeSort } from './time';

function instance(startsAt: string, endsAt: string): EventInstance {
  return EventInstance.fromPartial({ startsAt, endsAt });
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

describe('instanceTimeSort', () => {
  test('sorts by startsAt first', () => {
    const a = instance('2020-01-01T00:00:00Z', '2020-01-01T01:00:00Z');
    const b = instance('2020-01-02T00:00:00Z', '2020-01-02T01:00:00Z');
    expect(instanceTimeSort(a, b)).toBe(-1);
  });

  test('falls back to endsAt when startsAt matches', () => {
    const a = instance('2020-01-01T00:00:00Z', '2020-01-01T01:00:00Z');
    const b = instance('2020-01-01T00:00:00Z', '2020-01-01T02:00:00Z');
    expect(instanceTimeSort(a, b)).toBe(-1);
  });
});

describe('isPastInstance / isNotPastInstance', () => {
  test('an instance that ended in the past is past', () => {
    const past = instance('2000-01-01T00:00:00Z', '2000-01-01T01:00:00Z');
    expect(isPastInstance(past)).toBe(true);
    expect(isNotPastInstance(past)).toBe(false);
  });

  test('an instance ending far in the future is not past', () => {
    const future = instance('2999-01-01T00:00:00Z', '2999-01-01T01:00:00Z');
    expect(isPastInstance(future)).toBe(false);
    expect(isNotPastInstance(future)).toBe(true);
  });
});
