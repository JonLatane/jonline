import moment from 'moment';
import BaseDateTimePicker from 'react-datetime-picker';

import { Text } from '@jonline/ui';

import { Calendar } from '@tamagui/lucide-icons';
import 'react-calendar/dist/Calendar.css';
import 'react-clock/dist/Clock.css';
import 'react-datetime-picker/dist/DateTimePicker.css';
import './datetime_picker.css';


export const supportDateInput = (m: moment.Moment) => m.local().format('YYYY-MM-DDTHH:mm');
export const toProtoISOString = (localDateTimeInput: string) =>
  moment(localDateTimeInput).toISOString(true);

export type DateTimePickerProps = {
  value: string;
  onChange: (value: string) => void;
}

export const DateTimePicker: React.FC<DateTimePickerProps> = ({
  value,
  onChange,
}) => {

  {/* <Text fontSize='$2' fontFamily='$body'>
    <input type='datetime-local' 
      style={{ colorScheme: darkMode ? 'dark' : 'light', padding: 10 }}
      min={editingInstance.startsAt}
      value={supportDateInput(moment(editingInstance.endsAt))}
      onChange={(v) => setEndTime(v.target.value)} />
  </Text> */}

  {/* <Text ml='auto' my='auto' fontSize='$2' fontFamily='$body'> */ }
  {/* <input type='datetime-local' min={supportDateInput(moment(0))} value={supportDateInput(moment(endsAfter))} onChange={(v) => setQueryEndsAfter(moment(v.target.value).toISOString(true))} style={{ padding: 10 }} /> */ }
  {/* </Text> */ }

  return <Text fontSize='$2' fontFamily='$body'>
    <BaseDateTimePicker
      onChange={(v) => v ? onChange(moment(v).toISOString(true)) : undefined}
      value={value}
      minDate={moment(0).toDate()}
      calendarIcon={<Calendar />}
      // clearIcon={<X />}
      required
    />
  </Text>
};
