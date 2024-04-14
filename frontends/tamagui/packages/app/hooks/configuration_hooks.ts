
import { useAppDispatch, useAppSelector } from 'app/hooks';
import { setShowBigCalendar, setShowEventsOnLatest } from 'app/store';

export function useShowEvents() {
  const dispatch = useAppDispatch();
  const { showEventsOnLatest: showEvents } = useAppSelector(state => state.app);
  const setShowEvents = (v: boolean) => dispatch(setShowEventsOnLatest(v));

  return {
    showEvents: showEvents ?? true,
    setShowEvents
  };
}

export function useBigCalendar() {
  const dispatch = useAppDispatch();
  const { showBigCalendar: bigCalendar } = useAppSelector(state => state.app);
  const setBigCalendar = (v: boolean) => dispatch(setShowBigCalendar(v));

  return {
    bigCalendar: bigCalendar ?? true,
    setBigCalendar

  };
}
