import { Location } from "@jonline/api";
import { Adapt, Anchor, Button, Heading, Input, Label, Paragraph, Popover, ScrollView, Spinner, XStack, YStack, useMedia } from "@jonline/ui";
import { MapPin, Scroll } from "@tamagui/lucide-icons";
import { NominatimResult, useNominatim } from "app/hooks/use_nominatim";
import { useQueryDebounce } from "app/hooks/use_query_debounce";
import { useEffect, useState } from "react";
import { useLink } from "solito/link";


interface Props {
  location: Location;
  setLocation: (location: Location) => void;
  disabled?: boolean;
  readOnly?: boolean;
}

export const LocationControl: React.FC<Props> = ({
  location,
  setLocation,
  disabled,
  readOnly
}) => {
  const mediaQuery = useMedia();
  const value = location.uniformlyFormattedAddress;
  function setValue(value: string) {
    setLocation({ ...location, uniformlyFormattedAddress: value });
  }

  const [isEditing, setIsEditing] = useState(!value);
  const [address, setAddress] = useState(value);
  const [candidateAddress, setCandidateAddress] = useState('');
  const [previousAddress, setPreviousAddress] = useState(value);

  const [osmQuery, setOsmQuery] = useState<string | undefined>(undefined);
  const [showResults, setShowResults] = useState(false);

  // NB: do not reduce to less than 1 second
  // https://operations.osmfoundation.org/policies/nominatim/
  // It says "No heavy uses (an absolute maximum of 1 request per second)."
  const debounceMs = 1000 * 2;
  const debouncedSearchAddress: string | undefined = useQueryDebounce<string | undefined>(candidateAddress, debounceMs);

  // comma-separated list of "ISO 3166-1alpha2" country codes.
  // As example here is set to Norway and Sweden.
  const countryCodes: string[] = ['us'];
  const [isSearching, , results] = useNominatim(osmQuery ?? '', countryCodes);

  const uriValue = encodeURIComponent(value);
  const googleMapsLink = useLink({ href: `https://maps.google.com?q=${uriValue}` });
  const appleMapsLink = useLink({ href: `https://maps.apple.com/?q=${uriValue}` });
  const osmLink = useLink({ href: `https://www.openstreetmap.org/search?query=${uriValue}` });

  const osmCopyrightLink = useLink({ href: 'openstreetmap.org/copyright' })

  useEffect(() => {
    if (debouncedSearchAddress && debouncedSearchAddress.length > 5) {
      setOsmQuery(debouncedSearchAddress);
    }
  }, [debouncedSearchAddress]);

  useEffect(() => {
    setShowResults(true);
  }, [results]);

  //https://maps.google.com?q=newyork or

  if (readOnly) {
    if (!location || location.uniformlyFormattedAddress === '') {
      return <></>;
    }
    return <XStack space='$2'>
      <Paragraph my='auto' f={1} size='$1'>{value}</Paragraph>
      <Button my='auto' h='auto' px='$2' {...osmLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$1'>OpenStreet</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Map</Paragraph></YStack></Button>
      <Button my='auto' h='auto' px='$2' {...appleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Apple</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
      <Button my='auto' h='auto' px='$2' {...googleMapsLink} target='_blank'><YStack><Paragraph mx='auto' lineHeight='$1' size='$2'>Google</Paragraph><Paragraph mx='auto' lineHeight='$1' size='$1'>Maps</Paragraph></YStack></Button>
    </XStack>;
  }

  const willAdapt = !mediaQuery.gtSm;

  const resultsView = <YStack space='$2'>
    {results
      ? results
        .filter(x => x)
        .map(x => x as NominatimResult)
        .sort((v1, v2) => v1.importance - v2.importance)
        .map((result, index) => {
          return (
            <Popover.Close asChild>

              <Button
                h='auto'
                onPress={() => {
                  setValue(result.display_name)
                  /* Custom code goes here, does not interfere with popover closure */
                }}
              >
                <Paragraph maw='$20'>
                  {result.display_name ?? '-'}
                </Paragraph>
              </Button>
            </Popover.Close>
          );
        })
      : undefined}
  </YStack>;
  return <XStack space='$1'>
    <Input f={1} textContentType="fullStreetAddress" placeholder={`Location (optional)`}
      disabled={disabled} opacity={disabled || '' ? 0.5 : 1}
      autoCapitalize='words'
      value={value}
      onChange={(data) => {
        setCandidateAddress(data.nativeEvent.text);
        setValue(data.nativeEvent.text)
      }} />

    <Popover size="$5" allowFlip placement='left'>
      <Popover.Trigger asChild>
        <Button icon={MapPin} />
      </Popover.Trigger>

      <Adapt when="sm" platform="touch">
        <Popover.Sheet modal dismissOnSnapToBottom>
          <Popover.Sheet.Frame padding="$4">
            <Adapt.Contents />
          </Popover.Sheet.Frame>
          <Popover.Sheet.Overlay
            animation="lazy"
            enterStyle={{ opacity: 0 }}
            exitStyle={{ opacity: 0 }}
          />
        </Popover.Sheet>
      </Adapt>

      <Popover.Content
        borderWidth={1}
        borderColor="$borderColor"
        enterStyle={{ y: -10, opacity: 0 }}
        exitStyle={{ y: -10, opacity: 0 }}
        elevate
        animation={[
          'quick',
          {
            opacity: {
              overshootClamping: true,
            },
          },
        ]}
      >
        <Popover.Arrow borderWidth={1} borderColor="$borderColor" />

        <YStack space="$3" h='100%'>
          <Heading size="$3" mx='auto'><Anchor {...osmCopyrightLink} target='_blank'>OpenStreetMap</Anchor> Suggestions</Heading>
          {isSearching ? <Spinner /> : undefined}

          {/* <Popover.Close asChild> */}
          {/* <Button
            size="$3"
            onPress={() => { }}
          >
            Submit
          </Button> */}
          {/* </Popover.Close> */}
          {results?.length === 0 ? <Paragraph mx='auto' {...willAdapt ? { f: 1 } : {}}>No results.</Paragraph> : undefined}
          {willAdapt ?
            <Popover.Sheet.ScrollView f={1}>
              {resultsView}
            </Popover.Sheet.ScrollView>
            : <ScrollView h='$20'>
              {resultsView}
            </ScrollView>}

          <Paragraph size="$2" mx='auto' ta='center'>© OpenStreetMap contributors</Paragraph>
        </YStack>
      </Popover.Content>
    </Popover >
  </XStack >;
}