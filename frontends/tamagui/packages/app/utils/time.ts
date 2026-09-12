import { Occasion } from "@rellm/api";
import moment from "moment";

export function isNotPastInstance(i: Occasion) {
  return moment(i.endsAt!).isAfter(moment())
}
export function isPastInstance(i: Occasion) {
  return !isNotPastInstance(i);
}

export function instanceTimeSort(a: Occasion, b: Occasion) {
  const startSort = timeSort(a.startsAt!, b.startsAt!);
  if (startSort !== 0) return startSort;
  return timeSort(a.endsAt!, b.endsAt!);
}

export function timeSort(a: string, b: string) {
  return moment(a).isBefore(moment(b)) ? -1
    : moment(a).isAfter(moment(b)) ? 1 : 0;
}