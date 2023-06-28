import { EventInstance } from "@jonline/api/index";
import moment from "moment";

export function isNotPastInstance(i: EventInstance) {
  return moment(i.endsAt!).isAfter(moment())
}
export function isPastInstance(i: EventInstance) {
  return !isNotPastInstance(i);
}

export function instanceTimeSort(a: EventInstance, b: EventInstance) {
  const startSort = timeSort(a.startsAt!, b.startsAt!);
  if (startSort !== 0) return startSort;
  return timeSort(a.endsAt!, b.endsAt!);
}

export function timeSort(a: string, b: string) {
  return moment(a).isBefore(moment(b)) ? -1
    : moment(a).isAfter(moment(b)) ? 1 : 0;
}