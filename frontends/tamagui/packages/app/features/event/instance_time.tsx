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
  const { server, primaryColor, primaryAnchorColor, navAnchorColor, backgroundColor: themeBgColor } = useServerTheme();
  const group = useGroupContext();
  const instanceLink = useLink(createInstanceLink(event, instance, group));

  function dateView(date: string) {
    return <YStack>
      <Heading size="$2" color={primaryColor} mr='$2'>
        {moment.utc(date).local().format('ddd, MMM Do YYYY')}
      </Heading>
      <Heading size="$4" color={primaryColor}>
        {moment.utc(date).local().format('h:mm a')}
      </Heading>
    </YStack>;
  }

  function dateRangeView(startsAt: string, endsAt: string) {
    const startsAtDate = moment.utc(startsAt).local().format('ddd, MMM Do YYYY');
    const endsAtDate = moment.utc(endsAt).local().format('ddd, MMM Do YYYY');
    if (startsAtDate == endsAtDate) {
      return <YStack my='auto'
        backgroundColor={themeBgColor} opacity={0.8} pl='$2' borderRadius='$3'>
        <XStack>
          <Paragraph size="$3" fontWeight='800' color={primaryColor} mr='$2'>
            {startsAtDate}
          </Paragraph>
        </XStack>
        <XStack space>
          <Heading size="$3" color={primaryColor}>
            {moment.utc(startsAt).local().format('h:mm a')}
          </Heading>
          <Heading size="$3" color={primaryColor}>
            -
          </Heading>
          <Heading size="$3" color={primaryColor}>
            {moment.utc(endsAt).local().format('h:mm a')}
          </Heading>
        </XStack>
      </YStack>;
    } else {
      return <XStack>
        <YStack f={1}>
          {startsAt ? dateView(startsAt) : undefined}
        </YStack>
        <YStack f={1}>
          {endsAt ? dateView(endsAt) : undefined}
        </YStack>
      </XStack>;
    }
  }

  const startsAtDate = moment.utc(startsAt).local().format('ddd, MMM Do YYYY');
  const endsAtDate = moment.utc(endsAt).local().format('ddd, MMM Do YYYY');
  const color = highlight ? primaryAnchorColor : linkToInstance ? navAnchorColor : primaryAnchorColor;
  const mainView = (startsAtDate == endsAtDate)
    ? <YStack
      backgroundColor={linkToInstance ? undefined : themeBgColor}
      opacity={linkToInstance ? undefined : 0.8} pl='$2' borderRadius='$3'>
      <XStack>
        <Paragraph size="$3" color={color} fontWeight='800' mr='$2'>
          {startsAtDate}
        </Paragraph>
      </XStack>
      <XStack space='$2'>
        <Heading size="$3" color={color}>
          {moment.utc(startsAt).local().format('h:mm a')}
        </Heading>
        <Heading size="$3" color={color}>
          -
        </Heading>
        <Heading size="$3" color={color}>
          {moment.utc(endsAt).local().format('h:mm a')}
        </Heading>
      </XStack>
    </YStack>
    : <XStack>
      <YStack f={1}>
        {startsAt ? dateView(startsAt) : undefined}
      </YStack>
      <YStack f={1}>
        {endsAt ? dateView(endsAt) : undefined}
      </YStack>
    </XStack>;

  if (linkToInstance) {
    return <Button {...instanceLink} mx='$2' px='$2'>
      {mainView}
    </Button>;
  } else {
    return mainView;
  }
}