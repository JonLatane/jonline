
import { Heading, Tooltip } from "@jonline/ui";
import moment from "moment";

export type DateViewerProps = {
  date?: string
  prefix?: string
}
export const DateViewer = ({ date, prefix }: DateViewerProps) => {
  if (!date) return <></>;

  return <Tooltip placement="bottom-start">
    <Tooltip.Trigger>
      <Heading size="$1" marginVertical='auto' mr='$2'>
        {moment.utc(date).local().startOf('seconds').fromNow()}
      </Heading>
    </Tooltip.Trigger>
    <Tooltip.Content>
      <Heading size='$2'>{prefix != undefined ? `${prefix} ` : ''}{moment.utc(date).local().format("ddd, MMM Do YYYY, h:mm:ss a")}</Heading>
    </Tooltip.Content>
  </Tooltip>;
}
