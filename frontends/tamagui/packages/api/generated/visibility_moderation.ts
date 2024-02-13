/* eslint-disable */

export const protobufPackage = "jonline";

/**
 * Visibility in Jonline is a complex topic. There are several different types of visibility,
 * and each type of entity (`User`, `Media`, `Group`, then `Post`/`Event`/etc. with common logic)
 * has different rules for visibility.
 *
 * From the top down, the rules break down as follows:
 *
 * - Even a `PRIVATE` entity is always visible to the user who owns it.
 *     - For `Group`s, this means all full members of the `Group`.
 *     - For `User`s, this is confusing and there is a whole `PrivateUserStrategy` thing
 *       in `ServerConfiguration` for this.
 * - A `LIMITED` entity is visible to to the owner(s) and any explicitly associated
 *   `User`s and `Group`s. Generally, this only applies to `Post`/`Event`/etc. entities.
 *   Associations exist via `UserPost`s and `GroupPost`s.
 *     - This is currently only implemented for `Group`s and `GroupPost`s. There are some
 *       choices to be made about how to implement this for `User`s and `UserPost`s, and whether
 *       `DIRECT` should be a separate visibility type.
 * - A `SERVER_PUBLIC` entity is visible to all authenticated users.
 * - A `GLOBAL_PUBLIC` entity is visible to the open internet.
 */
export enum Visibility {
  /** VISIBILITY_UNKNOWN - A visibility that is not known to the protocol. (Likely, the client and server use different versions of the Jonline protocol.) */
  VISIBILITY_UNKNOWN = 0,
  /** PRIVATE - Subject is only visible to the user who owns it. */
  PRIVATE = 1,
  /** LIMITED - Subject is only visible to explictly associated Groups and Users. See: [`GroupPost`](#jonline-GroupPost) and [`UserPost`](#jonline-UserPost). */
  LIMITED = 2,
  /** SERVER_PUBLIC - Subject is visible to all authenticated users. */
  SERVER_PUBLIC = 3,
  /** GLOBAL_PUBLIC - Subject is visible to all users on the internet. */
  GLOBAL_PUBLIC = 4,
  /**
   * DIRECT - [TODO] Subject is visible to explicitly-associated Users. Only applicable to Posts and Events.
   * For Users, this is the same as LIMITED.
   * See: [`UserPost`](#jonline-UserPost).
   */
  DIRECT = 5,
  UNRECOGNIZED = -1,
}

export function visibilityFromJSON(object: any): Visibility {
  switch (object) {
    case 0:
    case "VISIBILITY_UNKNOWN":
      return Visibility.VISIBILITY_UNKNOWN;
    case 1:
    case "PRIVATE":
      return Visibility.PRIVATE;
    case 2:
    case "LIMITED":
      return Visibility.LIMITED;
    case 3:
    case "SERVER_PUBLIC":
      return Visibility.SERVER_PUBLIC;
    case 4:
    case "GLOBAL_PUBLIC":
      return Visibility.GLOBAL_PUBLIC;
    case 5:
    case "DIRECT":
      return Visibility.DIRECT;
    case -1:
    case "UNRECOGNIZED":
    default:
      return Visibility.UNRECOGNIZED;
  }
}

export function visibilityToJSON(object: Visibility): string {
  switch (object) {
    case Visibility.VISIBILITY_UNKNOWN:
      return "VISIBILITY_UNKNOWN";
    case Visibility.PRIVATE:
      return "PRIVATE";
    case Visibility.LIMITED:
      return "LIMITED";
    case Visibility.SERVER_PUBLIC:
      return "SERVER_PUBLIC";
    case Visibility.GLOBAL_PUBLIC:
      return "GLOBAL_PUBLIC";
    case Visibility.DIRECT:
      return "DIRECT";
    case Visibility.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

/**
 * Nearly everything in Jonline has one or more `Moderation`s on it.
 *
 * From a high level:
 *
 * - A `User` has a `moderation` that determines whether they can log in (and their visibility per their `visibility`).
 *   (This is poorly enforced currently! Fix it if you want!)
 *     - This is managed by `people_settings.default_moderation` in `ServerConfiguration`.
 *       A default of `UNMODERATED` means that all users can log in. A default of `PENDING`
 *       means that all users must be approved by a moderator/admin before they can log in.
 * - A `Follow` has a `target_user_moderation` that determines whether the `User` is following the `Group`.
 *    - It is managed by `default_follow_moderation` in the targeted `User`.
 * - A `Group` has a `moderation` that determines whether the `Group` is visible to users (per its `visibility`).
 *     - This is managed by `group_settings.default_moderation` in `ServerConfiguration`.
 * - A `Membership` has a `group_moderation` and `user_moderation` that determine whether
 *   the `Group` admins and/or the invited user has approved the `Membership`, respectively.
 *     - User invites to `Group`s (i.e. the `user_moderation`) always start as `PENDING`.
 *       The group side of this is managed by `default_membership_moderation` of the `Group` in question.
 * - A `Post` has a `moderation` that determines whether the `Post` is visible to users (per its `visibility`).
 *     - This is managed by `post_settings.default_moderation` in `ServerConfiguration`.
 * - A `GroupPost` has a `moderation` that determines whether the admins/mods of the `Group` has approved the `Post` (or `Post`-descended thing like `Event`s).
 * - `Event`s and further objects contain a `Post` and thus inherit its `moderation` and
 *   related `GroupPost` behavior, for "Group Events."
 */
export enum Moderation {
  /** MODERATION_UNKNOWN - A moderation that is not known to the protocol. (Likely, the client and server use different versions of the Jonline protocol.) */
  MODERATION_UNKNOWN = 0,
  /** UNMODERATED - Subject has not been moderated and is visible to all users. */
  UNMODERATED = 1,
  /** PENDING - Subject is awaiting moderation and not visible to any users. */
  PENDING = 2,
  /** APPROVED - Subject has been approved by moderators and is visible to all users. */
  APPROVED = 3,
  /** REJECTED - Subject has been rejected by moderators and is not visible to any users. */
  REJECTED = 4,
  UNRECOGNIZED = -1,
}

export function moderationFromJSON(object: any): Moderation {
  switch (object) {
    case 0:
    case "MODERATION_UNKNOWN":
      return Moderation.MODERATION_UNKNOWN;
    case 1:
    case "UNMODERATED":
      return Moderation.UNMODERATED;
    case 2:
    case "PENDING":
      return Moderation.PENDING;
    case 3:
    case "APPROVED":
      return Moderation.APPROVED;
    case 4:
    case "REJECTED":
      return Moderation.REJECTED;
    case -1:
    case "UNRECOGNIZED":
    default:
      return Moderation.UNRECOGNIZED;
  }
}

export function moderationToJSON(object: Moderation): string {
  switch (object) {
    case Moderation.MODERATION_UNKNOWN:
      return "MODERATION_UNKNOWN";
    case Moderation.UNMODERATED:
      return "UNMODERATED";
    case Moderation.PENDING:
      return "PENDING";
    case Moderation.APPROVED:
      return "APPROVED";
    case Moderation.REJECTED:
      return "REJECTED";
    case Moderation.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}
