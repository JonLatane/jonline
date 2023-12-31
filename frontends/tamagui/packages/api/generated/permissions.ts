/* eslint-disable */

export const protobufPackage = "jonline";

export enum Permission {
  PERMISSION_UNKNOWN = 0,
  VIEW_USERS = 1,
  /**
   * PUBLISH_USERS_LOCALLY - Allow the user to publish profiles with `SERVER_PUBLIC` Visbility.
   * This generally only applies to the user's own profile, except for Admins.
   */
  PUBLISH_USERS_LOCALLY = 2,
  /**
   * PUBLISH_USERS_GLOBALLY - Allow the user to publish profiles with `GLOBAL_PUBLIC` Visbility.
   * This generally only applies to the user's own profile, except for Admins.
   */
  PUBLISH_USERS_GLOBALLY = 3,
  /**
   * MODERATE_USERS - Allow the user to grant `VIEW_POSTS`, `CREATE_POSTS`, `VIEW_EVENTS`
   * and `CREATE_EVENTS` permissions to users.
   */
  MODERATE_USERS = 4,
  /** FOLLOW_USERS - Allow the user to follow other users. */
  FOLLOW_USERS = 5,
  /**
   * GRANT_BASIC_PERMISSIONS - Allow the user to grant Basic Permissions to other users. "Basic Permissions"
   * are defined by your `ServerConfiguration`'s `basic_user_permissions`.
   */
  GRANT_BASIC_PERMISSIONS = 6,
  /** VIEW_GROUPS - Allow the user to view groups with `SERVER_PUBLIC` visibility. */
  VIEW_GROUPS = 10,
  /** CREATE_GROUPS - Allow the user to create groups. */
  CREATE_GROUPS = 11,
  /** PUBLISH_GROUPS_LOCALLY - Allow the user to give groups `SERVER_PUBLIC` visibility. */
  PUBLISH_GROUPS_LOCALLY = 12,
  /** PUBLISH_GROUPS_GLOBALLY - Allow the user to give groups `GLOBAL_PUBLIC` visibility. */
  PUBLISH_GROUPS_GLOBALLY = 13,
  /** MODERATE_GROUPS - The Moderate Groups permission makes a user effectively an admin of *any* group. */
  MODERATE_GROUPS = 14,
  /**
   * JOIN_GROUPS - Allow the user to (potentially request to) join groups of `SERVER_PUBLIC` or higher
   * visibility.
   */
  JOIN_GROUPS = 15,
  /** INVITE_GROUP_MEMBERS - Allow the user to invite other users to groups. Only applicable as a Group permission (not at the User level). */
  INVITE_GROUP_MEMBERS = 16,
  /**
   * VIEW_POSTS - In the context of user permissions, allow the user to view posts with `SERVER_PUBLIC`
   * or higher visibility. In the context of group permissions, allow the user to view `GroupPost`s whose `Post`s have `LIMITED`
   * or higher visibility.
   */
  VIEW_POSTS = 20,
  /**
   * CREATE_POSTS - In the context of user permissions, allow the user to view posts with `SERVER_PUBLIC`
   * or higher visibility. In the context of group permissions, allow the user to create `GroupPost`s whose `Post`s have `LIMITED`
   * or higher visibility.
   */
  CREATE_POSTS = 21,
  PUBLISH_POSTS_LOCALLY = 22,
  PUBLISH_POSTS_GLOBALLY = 23,
  MODERATE_POSTS = 24,
  REPLY_TO_POSTS = 25,
  VIEW_EVENTS = 30,
  CREATE_EVENTS = 31,
  PUBLISH_EVENTS_LOCALLY = 32,
  PUBLISH_EVENTS_GLOBALLY = 33,
  /** MODERATE_EVENTS - Allow the user to moderate events. */
  MODERATE_EVENTS = 34,
  RSVP_TO_EVENTS = 35,
  VIEW_MEDIA = 40,
  CREATE_MEDIA = 41,
  PUBLISH_MEDIA_LOCALLY = 42,
  PUBLISH_MEDIA_GLOBALLY = 43,
  /** MODERATE_MEDIA - Allow the user to moderate events. */
  MODERATE_MEDIA = 44,
  /**
   * RUN_BOTS - Allow the user to run bots. There is no enforcement of this permission (yet),
   * but it lets other users know that the user is allowed to run bots.
   */
  RUN_BOTS = 9999,
  /**
   * ADMIN - Marks the user as an admin. In the context of user permissions, allows the user to configure the server,
   * moderate/update visibility/permissions to any `User`, `Group`, `Post` or `Event`. In the context of group permissions, allows the user to configure the group,
   * modify members and member permissions, and moderate `GroupPost`s and `GroupEvent`s.
   */
  ADMIN = 10000,
  /**
   * VIEW_PRIVATE_CONTACT_METHODS - Allow the user to view the private contact methods of other users.
   * Kept separate from `ADMIN` to allow for more fine-grained privacy control.
   */
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
    case 16:
    case "INVITE_GROUP_MEMBERS":
      return Permission.INVITE_GROUP_MEMBERS;
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
    case 25:
    case "REPLY_TO_POSTS":
      return Permission.REPLY_TO_POSTS;
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
    case 35:
    case "RSVP_TO_EVENTS":
      return Permission.RSVP_TO_EVENTS;
    case 40:
    case "VIEW_MEDIA":
      return Permission.VIEW_MEDIA;
    case 41:
    case "CREATE_MEDIA":
      return Permission.CREATE_MEDIA;
    case 42:
    case "PUBLISH_MEDIA_LOCALLY":
      return Permission.PUBLISH_MEDIA_LOCALLY;
    case 43:
    case "PUBLISH_MEDIA_GLOBALLY":
      return Permission.PUBLISH_MEDIA_GLOBALLY;
    case 44:
    case "MODERATE_MEDIA":
      return Permission.MODERATE_MEDIA;
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
    case Permission.INVITE_GROUP_MEMBERS:
      return "INVITE_GROUP_MEMBERS";
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
    case Permission.REPLY_TO_POSTS:
      return "REPLY_TO_POSTS";
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
    case Permission.RSVP_TO_EVENTS:
      return "RSVP_TO_EVENTS";
    case Permission.VIEW_MEDIA:
      return "VIEW_MEDIA";
    case Permission.CREATE_MEDIA:
      return "CREATE_MEDIA";
    case Permission.PUBLISH_MEDIA_LOCALLY:
      return "PUBLISH_MEDIA_LOCALLY";
    case Permission.PUBLISH_MEDIA_GLOBALLY:
      return "PUBLISH_MEDIA_GLOBALLY";
    case Permission.MODERATE_MEDIA:
      return "MODERATE_MEDIA";
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
