import moment from 'moment';
import BaseDateTimePicker from 'react-datetime-picker';

import { Label, Text, XStack, isSafari } from '@jonline/ui';

import { Calendar } from '@tamagui/lucide-icons';
import { useComponentKey, useLocalConfiguration } from 'app/hooks';
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
  const { dateTimeRenderer: renderer } = useLocalConfiguration();

  const componentKey = useComponentKey('datetime-picker');
  const safari = isSafari();
  if (renderer === 'native') {
    return <XStack ai='center' borderColor='$body' borderWidth={2} borderRadius='$2' pt='$1'>
      <Text fontSize='$2' fontFamily='$body'>
        <input type='datetime-local' name={componentKey} id={componentKey} min={supportDateInput(moment(0))}
          value={supportDateInput(moment(value))}
          onChange={(v) => v ? onChange(moment(v.target.value).toISOString(true)) : undefined}
          // onChange={(v) => setQueryEndsAfter(moment(v.target.value).toISOString(true))}
          style={{
            padding: 10,
            //colorScheme: darkMode ? 'dark' : 'light', padding: 10
          }} />
      </Text>
      {safari
        ? <Label htmlFor={componentKey} mb='$1'>
          <Calendar size='$1' />
        </Label>
        : undefined}
    </XStack>;
  }

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
