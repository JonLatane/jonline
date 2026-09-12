import { Occasion } from "@rellm/api";
import moment from "moment";

export function isNotPastOccasion(i: Occasion) {
  return moment(i.endsAt!).isAfter(moment())
}
export function isPastOccasion(i: Occasion) {
  return !isNotPastOccasion(i);
}

export function occasionTimeSort(a: Occasion, b: Occasion) {
  const startSort = timeSort(a.startsAt!, b.startsAt!);
  if (startSort !== 0) return startSort;
  return timeSort(a.endsAt!, b.endsAt!);
}

export function timeSort(a: string, b: string) {
  return moment(a).isBefore(moment(b)) ? -1
    : moment(a).isAfter(moment(b)) ? 1 : 0;
}