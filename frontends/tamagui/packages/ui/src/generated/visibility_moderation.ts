/* eslint-disable */

export const protobufPackage = "jonline";

export enum Visibility {
  VISIBILITY_UNKNOWN = 0,
  PRIVATE = 1,
  LIMITED = 2,
  SERVER_PUBLIC = 3,
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
  UNMODERATED = 1,
  PENDING = 2,
  APPROVED = 3,
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
