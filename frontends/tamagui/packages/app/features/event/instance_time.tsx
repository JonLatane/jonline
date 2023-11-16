import { useServerTheme } from "app/store";
import React from "react";

import { Event, EventInstance, Group } from "@jonline/api";
import { Button, Heading, Paragraph, XStack, YStack } from "@jonline/ui";
import moment from "moment";
import { useLink } from "solito/link";
import { useGroupContext } from "../groups/group_context";

interface Props {
  event: Event;
  instance: EventInstance;
  linkToInstance?: boolean;
  highlight?: boolean;
}

export const createInstanceLink = (event: Event, instance: EventInstance, group?: Group) => ({
  href: group
    ? `/g/${group.shortname}/e/${event.id}/i/${instance!.id}`
    : `/event/${event.id}/i/${instance!.id}`
});

export const InstanceTime: React.FC<Props> = ({ event, instance, linkToInstance = false, highlight = false }) => {
  const { startsAt, endsAt } = instance;
  const { server, primaryColor, primaryAnchorColor, navAnchorColor, textColor, backgroundColor: themeBgColor } = useServerTheme();
  const group = useGroupContext();
  const instanceLink = useLink(createInstanceLink(event, instance, group));

  const mx = linkToInstance ? 'auto' : undefined;
  const lh = 14;

  function dateView(date: string) {
    return <YStack>
      <Paragraph size="$2" color={color} fontWeight='800' mx={mx} lineHeight={lh}>
        {moment.utc(date).local().format('dddd')}
      </Paragraph>
      <Paragraph size="$1" color={color} mx={mx} lineHeight={lh}>
        {moment.utc(date).local().format('MMM Do YYYY')}
      </Paragraph>
      <Heading size="$2" color={color} lineHeight={lh} mx={mx}>
        {moment.utc(date).local().format('h:mma').replace(':00', '')}
      </Heading>
    </YStack>;
  }

  const startsAtDay = moment.utc(startsAt).local().format('dddd');
  const startsAtDate = moment.utc(startsAt).local().format('MMM Do YYYY');
  const endsAtDay = moment.utc(endsAt).local().format('dddd');
  const endsAtDate = moment.utc(endsAt).local().format('MMM Do YYYY');
  const isPast = moment.utc().isAfter(moment.utc(endsAt));
  const color = highlight
    ? primaryAnchorColor
    : linkToInstance
      ? (isPast ? textColor : navAnchorColor)
      : primaryAnchorColor;
  const key = `instance-time-${instance.id}`
  const opacity = linkToInstance || highlight ? undefined : 0.8;
  const mainView = (startsAtDate == endsAtDate)
    ? <YStack key={key}
      backgroundColor={linkToInstance ? undefined : themeBgColor}
      opacity={opacity}
      px='$2' borderRadius='$3'>
      <Paragraph size="$2" color={color} fontWeight='800' mx={mx} lineHeight={lh}>
        {startsAtDay}
      </Paragraph>
      <Paragraph size="$1" color={color} mx={mx} lineHeight={lh}>
        {startsAtDate}
      </Paragraph>
      <XStack space='$2' mx={mx}>
        <Heading size="$2" color={color} lineHeight={lh}>
          {moment.utc(startsAt).local().format('h:mma').replace(':00', '')}
        </Heading>
        <Heading size="$3" color={color} lineHeight={lh} fontWeight='900'>
          -
        </Heading>
        <Heading size="$2" color={color} lineHeight={lh}>
          {moment.utc(endsAt).local().format('h:mma').replace(':00', '')}
        </Heading>
      </XStack>
    </YStack>
    : <XStack space={linkToInstance ? undefined : '$2'}
      opacity={opacity}>
      <YStack f={linkToInstance ? 1 : undefined}>
        {startsAt ? dateView(startsAt) : undefined}
      </YStack>
      <Heading size="$3" color={color} my='auto' fontWeight='900'>
        -
      </Heading>
      <YStack f={linkToInstance ? 1 : undefined}>
        {endsAt ? dateView(endsAt) : undefined}
      </YStack>
    </XStack>;

  if (linkToInstance) {
    return <Button key={key} {...instanceLink} h='auto' mx='$2' px='$2'>
      {mainView}
    </Button>;
  } else {
    return mainView;
  }
}