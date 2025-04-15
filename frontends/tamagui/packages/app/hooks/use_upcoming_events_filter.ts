import { TimeFilter } from "@jonline/api";
import { toProtoISOString } from "@jonline/ui/src";
import { setUpcomingEventsTimeFilter } from "app/store";
import moment from "moment";
import { useAppDispatch, useAppSelector } from "./store_hooks";

export function useUpcomingEventsFilter(): TimeFilter {
  const dispatch = useAppDispatch();
  const filter = useAppSelector(state => state.events.upcomingEventsTimeFilter);
  const createFilter = () => {
    const pageLoadTime = moment(Date.now()).toISOString(true);
    const endsAfter = moment(pageLoadTime).subtract(1, "week").toISOString(true);
    const timeFilter: TimeFilter = { endsAfter: toProtoISOString(endsAfter) };
    dispatch(setUpcomingEventsTimeFilter({ timeFilter }));
    return timeFilter;
  };
  return filter ?? createFilter();
}