/* eslint-disable */

export const protobufPackage = "jonline";

export enum Permission {
  PERMISSION_UNKNOWN = 0,
  VIEW_USERS = 1,
  /** PUBLISH_USERS_LOCALLY - This generally only applies to the user's own profile, except for Admins. */
  PUBLISH_USERS_LOCALLY = 2,
  /** PUBLISH_USERS_GLOBALLY - This generally only applies to the user's own profile, except for Admins. */
  PUBLISH_USERS_GLOBALLY = 3,
  /**
   * MODERATE_USERS - "Moderate users" refers to granting VIEW_POSTS, CREATE_POSTS, VIEW_EVENTS
   * and CREATE_EVENTS permissions to users.
   */
  MODERATE_USERS = 4,
  FOLLOW_USERS = 5,
  /**
   * GRANT_BASIC_PERMISSIONS - "Basic Permissions" are defined by your ServerConfiguration's
   * basic_user_permissions.
   */
  GRANT_BASIC_PERMISSIONS = 6,
  VIEW_GROUPS = 10,
  CREATE_GROUPS = 11,
  PUBLISH_GROUPS_LOCALLY = 12,
  PUBLISH_GROUPS_GLOBALLY = 13,
  /** MODERATE_GROUPS - The Moderate Groups permission makes a user effectively an admin of *any* group. */
  MODERATE_GROUPS = 14,
  JOIN_GROUPS = 15,
  VIEW_POSTS = 20,
  CREATE_POSTS = 21,
  PUBLISH_POSTS_LOCALLY = 22,
  PUBLISH_POSTS_GLOBALLY = 23,
  MODERATE_POSTS = 24,
  VIEW_EVENTS = 30,
  CREATE_EVENTS = 31,
  PUBLISH_EVENTS_LOCALLY = 32,
  PUBLISH_EVENTS_GLOBALLY = 33,
  MODERATE_EVENTS = 34,
  RUN_BOTS = 9999,
  ADMIN = 10000,
  VIEW_PRIVATE_CONTACT_METHODS = 10001,
  UNRECOGNIZED = -1,
}

export function permissionFromJSON(object: any): Permission {
  switch (object) {
    case 0:
    case "PERMISSION_UNKNOWN":
      return Permission.PERMISSION_UNKNOWN;
    case 1:
    case "VIEW_USERS":
      return Permission.VIEW_USERS;
    case 2:
    case "PUBLISH_USERS_LOCALLY":
      return Permission.PUBLISH_USERS_LOCALLY;
    case 3:
    case "PUBLISH_USERS_GLOBALLY":
      return Permission.PUBLISH_USERS_GLOBALLY;
    case 4:
    case "MODERATE_USERS":
      return Permission.MODERATE_USERS;
    case 5:
    case "FOLLOW_USERS":
      return Permission.FOLLOW_USERS;
    case 6:
    case "GRANT_BASIC_PERMISSIONS":
      return Permission.GRANT_BASIC_PERMISSIONS;
    case 10:
    case "VIEW_GROUPS":
      return Permission.VIEW_GROUPS;
    case 11:
    case "CREATE_GROUPS":
      return Permission.CREATE_GROUPS;
    case 12:
    case "PUBLISH_GROUPS_LOCALLY":
      return Permission.PUBLISH_GROUPS_LOCALLY;
    case 13:
    case "PUBLISH_GROUPS_GLOBALLY":
      return Permission.PUBLISH_GROUPS_GLOBALLY;
    case 14:
    case "MODERATE_GROUPS":
      return Permission.MODERATE_GROUPS;
    case 15:
    case "JOIN_GROUPS":
      return Permission.JOIN_GROUPS;
    case 20:
    case "VIEW_POSTS":
      return Permission.VIEW_POSTS;
    case 21:
    case "CREATE_POSTS":
      return Permission.CREATE_POSTS;
    case 22:
    case "PUBLISH_POSTS_LOCALLY":
      return Permission.PUBLISH_POSTS_LOCALLY;
    case 23:
    case "PUBLISH_POSTS_GLOBALLY":
      return Permission.PUBLISH_POSTS_GLOBALLY;
    case 24:
    case "MODERATE_POSTS":
      return Permission.MODERATE_POSTS;
    case 30:
    case "VIEW_EVENTS":
      return Permission.VIEW_EVENTS;
    case 31:
    case "CREATE_EVENTS":
      return Permission.CREATE_EVENTS;
    case 32:
    case "PUBLISH_EVENTS_LOCALLY":
      return Permission.PUBLISH_EVENTS_LOCALLY;
    case 33:
    case "PUBLISH_EVENTS_GLOBALLY":
      return Permission.PUBLISH_EVENTS_GLOBALLY;
    case 34:
    case "MODERATE_EVENTS":
      return Permission.MODERATE_EVENTS;
    case 9999:
    case "RUN_BOTS":
      return Permission.RUN_BOTS;
    case 10000:
    case "ADMIN":
      return Permission.ADMIN;
    case 10001:
    case "VIEW_PRIVATE_CONTACT_METHODS":
      return Permission.VIEW_PRIVATE_CONTACT_METHODS;
    case -1:
    case "UNRECOGNIZED":
    default:
      return Permission.UNRECOGNIZED;
  }
}

export function permissionToJSON(object: Permission): string {
  switch (object) {
    case Permission.PERMISSION_UNKNOWN:
      return "PERMISSION_UNKNOWN";
    case Permission.VIEW_USERS:
      return "VIEW_USERS";
    case Permission.PUBLISH_USERS_LOCALLY:
      return "PUBLISH_USERS_LOCALLY";
    case Permission.PUBLISH_USERS_GLOBALLY:
      return "PUBLISH_USERS_GLOBALLY";
    case Permission.MODERATE_USERS:
      return "MODERATE_USERS";
    case Permission.FOLLOW_USERS:
      return "FOLLOW_USERS";
    case Permission.GRANT_BASIC_PERMISSIONS:
      return "GRANT_BASIC_PERMISSIONS";
    case Permission.VIEW_GROUPS:
      return "VIEW_GROUPS";
    case Permission.CREATE_GROUPS:
      return "CREATE_GROUPS";
    case Permission.PUBLISH_GROUPS_LOCALLY:
      return "PUBLISH_GROUPS_LOCALLY";
    case Permission.PUBLISH_GROUPS_GLOBALLY:
      return "PUBLISH_GROUPS_GLOBALLY";
    case Permission.MODERATE_GROUPS:
      return "MODERATE_GROUPS";
    case Permission.JOIN_GROUPS:
      return "JOIN_GROUPS";
    case Permission.VIEW_POSTS:
      return "VIEW_POSTS";
    case Permission.CREATE_POSTS:
      return "CREATE_POSTS";
    case Permission.PUBLISH_POSTS_LOCALLY:
      return "PUBLISH_POSTS_LOCALLY";
    case Permission.PUBLISH_POSTS_GLOBALLY:
      return "PUBLISH_POSTS_GLOBALLY";
    case Permission.MODERATE_POSTS:
      return "MODERATE_POSTS";
    case Permission.VIEW_EVENTS:
      return "VIEW_EVENTS";
    case Permission.CREATE_EVENTS:
      return "CREATE_EVENTS";
    case Permission.PUBLISH_EVENTS_LOCALLY:
      return "PUBLISH_EVENTS_LOCALLY";
    case Permission.PUBLISH_EVENTS_GLOBALLY:
      return "PUBLISH_EVENTS_GLOBALLY";
    case Permission.MODERATE_EVENTS:
      return "MODERATE_EVENTS";
    case Permission.RUN_BOTS:
      return "RUN_BOTS";
    case Permission.ADMIN:
      return "ADMIN";
    case Permission.VIEW_PRIVATE_CONTACT_METHODS:
      return "VIEW_PRIVATE_CONTACT_METHODS";
    case Permission.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}
