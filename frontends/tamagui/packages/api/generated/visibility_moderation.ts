/* eslint-disable */

export const protobufPackage = "jonline";

export enum Visibility {
  VISIBILITY_UNKNOWN = 0,
  /** PRIVATE - Subject is only visible to the user who owns it. */
  PRIVATE = 1,
  /** LIMITED - Subject is only visible to explictly associated Groups and Users. See: [`GroupPost`](#jonline-GroupPost) and [`UserPost`](#jonline-UserPost). */
  LIMITED = 2,
  /** SERVER_PUBLIC - Subject is visible to all authenticated users. */
  SERVER_PUBLIC = 3,
  /** GLOBAL_PUBLIC - Subject is visible to all users on the internet. */
  GLOBAL_PUBLIC = 4,
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
    case Visibility.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export enum Moderation {
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
