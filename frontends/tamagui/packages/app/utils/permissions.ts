import { Permission } from '@jonline/api';

export type ContainsPermissions = {
  permissions?: Permission[];
}
export type HasPermissions = ContainsPermissions | Permission[] | undefined;



export function hasPermission(item: HasPermissions, permission: Permission) {
  if (typeof item === "undefined") return false;
  if (Array.isArray(item)) return _hasAdminPermission(item);

  return _hasPermission(item.permissions, permission);
}

export function hasAdminPermission(item: HasPermissions) {
  if (typeof item === "undefined") return false;
  if (Array.isArray(item)) return _hasAdminPermission(item);

  return _hasAdminPermission(item.permissions);
}

function _hasPermission(list: Permission[] | undefined, permission: Permission) {
  if (!list) return false;

  return list.includes(permission)
    || list.includes(Permission.ADMIN);
}

function _hasAdminPermission(list: Permission[] | undefined) {
  if (!list) return false;

  return list.includes(Permission.ADMIN);
}
