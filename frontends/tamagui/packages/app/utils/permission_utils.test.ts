import { describe, expect, test } from 'vitest';
import { Permission } from '@jonline/api';
import { hasAdminPermission, hasPermission } from './permission_utils';

describe('hasPermission', () => {
  test('returns false when item is undefined', () => {
    expect(hasPermission(undefined, Permission.MODERATE)).toBe(false);
  });

  test('returns true when the exact permission is present', () => {
    expect(hasPermission({ permissions: [Permission.MODERATE] }, Permission.MODERATE)).toBe(true);
  });

  test('returns false when the permission is absent', () => {
    expect(hasPermission({ permissions: [Permission.MODERATE] }, Permission.ADMIN)).toBe(false);
  });

  test('ADMIN implies other permissions', () => {
    expect(hasPermission({ permissions: [Permission.ADMIN] }, Permission.MODERATE)).toBe(true);
  });

  test('ADMIN does not imply BUSINESS', () => {
    expect(hasPermission({ permissions: [Permission.ADMIN] }, Permission.BUSINESS)).toBe(false);
  });
});

describe('hasAdminPermission', () => {
  test('returns false when item is undefined', () => {
    expect(hasAdminPermission(undefined)).toBe(false);
  });

  test('returns true when ADMIN is present in a raw permission list', () => {
    expect(hasAdminPermission([Permission.ADMIN])).toBe(true);
  });

  test('returns false when ADMIN is absent', () => {
    expect(hasAdminPermission({ permissions: [Permission.MODERATE] })).toBe(false);
  });
});
