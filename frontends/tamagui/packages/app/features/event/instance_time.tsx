import { FederatedEvent, federateId, useServerTheme } from "app/store";
import React from "react";

import { EventInstance, Group } from "@jonline/api";
import { Button, Heading, Paragraph, XStack, YStack, useTheme } from "@jonline/ui";
import { useGroupContext } from "app/contexts/group_context";
import { useAppSelector, useFederatedAccountOrServer, useCurrentServer } from "app/hooks";
import { themedButtonBackground } from "app/utils/themed_button_background";
import moment from "moment";
import { useLink } from "solito/link";
import { ThemedStar } from "../post/star_button";

interface Props {
  event: FederatedEvent;
  instance: EventInstance;
  linkToInstance?: boolean;
  highlight?: boolean;
  noAutoScroll?: boolean;
}

export const useInstanceLink = (event: FederatedEvent, instance: EventInstance, group?: Group) => {
  const { server } = useFederatedAccountOrServer(event);
  const showServerInfo = server?.host !== useCurrentServer()?.host;
  const detailsLinkId = showServerInfo
    ? federateId(instance!.id, server)
    : instance!.id;
  const groupLinkId = group ?
    (showServerInfo
      ? federateId(group.shortname, server)
      : group.shortname)
    : undefined;
  const instanceLink = useLink({
    href: group
      ? `/g/${groupLinkId}/e/${detailsLinkId}`
      : `/event/${detailsLinkId}`
  });
  return instanceLink;
}

export const InstanceTime: React.FC<Props> = ({
  event,
  instance,
  linkToInstance = false,
  highlight = false,
  noAutoScroll,
}) => {
  const { startsAt, endsAt } = instance;
  const { server } = useFederatedAccountOrServer(event);
  const { primaryColor, primaryAnchorColor, navAnchorColor, textColor, backgroundColor: themeBgColor } = useServerTheme(server);
  const { selectedGroup: group } = useGroupContext();
  const instanceLink = useInstanceLink(event, instance, group);

  const mx = linkToInstance ? 'auto' : undefined;
  const lh = 14;
  const federatedPostId = federateId(instance.post?.id ?? '', server);
  const starred = useAppSelector(state => state.app.starredPostIds.includes(federatedPostId));

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
  const mainView = <XStack ai='center'>
    {starred && linkToInstance ? <ThemedStar starred server={server} /> : undefined}
    {(startsAtDate == endsAtDate)
      ? <YStack f={1} key={key}
        className={highlight && !noAutoScroll ? 'highlighted-instance-time' : undefined}
        backgroundColor={linkToInstance ? undefined : themeBgColor}
        opacity={opacity}
        px='$1' borderRadius='$3'>
        <Paragraph size="$2" color={color} fontWeight='800' mx={mx} lineHeight={lh}>
          {startsAtDay}
        </Paragraph>
        <Paragraph size="$1" color={color} mx={mx} lineHeight={lh}>
          {startsAtDate}
        </Paragraph>
        <XStack gap='$2' mx={mx}>
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
      : <XStack f={1} gap={linkToInstance ? undefined : '$2'}
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
      </XStack>}
  </XStack>;

  if (linkToInstance) {
    return <Button key={key}
      {...themedButtonBackground(highlight ? '$backgroundFocus' : undefined)}
      // backgroundColor={highlight ? '$backgroundFocus' : undefined}
      {...instanceLink} h='auto' mx='$2' px='$2'>
      {mainView}
    </Button>;
  } else {
    return mainView;
  }
}
