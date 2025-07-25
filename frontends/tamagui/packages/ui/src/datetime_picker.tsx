// import 'react-calendar/dist/Calendar.css';
// import 'react-clock/dist/Clock.css';

import './css/react-big-calendar-patches.css';
import './css/native-datetime-picker-patches.css';

import moment from 'moment';

import { Label, Text, XStack, isSafari } from '@jonline/ui';

import { Calendar } from '@tamagui/lucide-icons';
import { useComponentKey, useLocalConfiguration } from 'app/hooks';
import { useServerTheme } from 'app/hooks/server_theme_hooks';


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
  const { darkMode } = useServerTheme();
  return <XStack ai='center' borderColor='$body'
    className={darkMode ? 'native-datetime-picker-dark' : undefined}
    borderWidth={2} borderRadius='$2' pt='$1' px='$2'>
    <Text fontSize='$2' fontFamily='$body' color={darkMode ? 'white' : 'black'}>
      <input type='datetime-local' name={componentKey} id={componentKey} min={supportDateInput(moment(0))}
        value={supportDateInput(moment(value))}
        // defaultValue={supportDateInput(moment(value))}
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
};
