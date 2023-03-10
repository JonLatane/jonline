import { Moderation } from '../../ui/src/generated/visibility_moderation';

export function passes(moderation: Moderation | undefined): boolean {
  return moderation != undefined && [Moderation.UNMODERATED, Moderation.APPROVED].includes(moderation);
}

export function pending(moderation: Moderation | undefined): boolean {
  return moderation != undefined && [Moderation.PENDING].includes(moderation);
}