import { Visibility } from '@jonline/api/generated/visibility_moderation';

export function publicVisibility(visibility: Visibility | undefined): boolean {
  return visibility != undefined && [Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC].includes(visibility);
}

export function publicOrPrivateVisibility(visibility: Visibility | undefined): boolean {
  return visibility != undefined && [Visibility.SERVER_PUBLIC, Visibility.GLOBAL_PUBLIC, Visibility.PRIVATE].includes(visibility);
}
