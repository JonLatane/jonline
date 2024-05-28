import { Author, Event, Location, Permission } from '@jonline/api';
import * as webllm from "@mlc-ai/web-llm";
import 'react-big-calendar/lib/css/react-big-calendar.css';

import { Button, Heading, Paragraph, Select, Spinner, TextArea, Tooltip, XStack, YStack, needsScrollPreservers, standardAnimation, useDebounceValue, useMedia, useToastController } from '@jonline/ui';
import { FederatedEvent, federateId, federatedId, useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';

import { useLocalConfiguration, usePaginatedRendering } from 'app/hooks';
import { useBigCalendar } from "app/hooks/configuration_hooks";
import FlipMove from 'react-flip-move';
import EventCard from '../event/event_card';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';

import { EventsFullCalendar, useScreenWidthAndHeight } from "../event/events_full_calendar";

import { Calendar as CalendarIcon, Check, ChevronDown, ChevronRight } from '@tamagui/lucide-icons';
import { hasPermission, highlightedButtonBackground, setDocumentTitle, themedButtonBackground } from 'app/utils';
import { useCreationAccountOrServer } from '../../hooks/account_or_server/use_creation_account_or_server';
import { CreationServerSelector } from '../accounts/creation_server_selector';
import { PageChooser } from "../home/page_chooser";
import { TamaguiMarkdown } from '../post';
import { isSafari } from '../../../ui/src/global';
import { C } from '@fullcalendar/core/internal-common';

export type EventAIScreenProps = {}
// export type EventDisplayMode = 'upcoming' | 'all' | 'filtered';
export type EventAIMode = 'inputText' | 'setupAi' | 'previewEvents';

export function useLocalStorageState(key: string, defaultValue: string) {

  const [value, setValue] = useState<string>(
    localStorage.getItem(key) ??
    defaultValue
  );
  const debouncedValue = useDebounceValue(value, 1000);
  useEffect(() => {
    localStorage.setItem(key, debouncedValue);
  }, [debouncedValue]);

  return [value, setValue] as const;
}

export const EventAIScreen: React.FC<EventAIScreenProps> = () => {
  const toast = useToastController();
  const mediaQuery = useMedia();
  const { shrinkPreviews } = useLocalConfiguration();
  const { bigCalendar, setBigCalendar } = useBigCalendar();

  // const eventsState = useRootSelector((state: RootState) => state.events);

  const [showScrollPreserver, setShowScrollPreserver] = useState(needsScrollPreservers());

  const serverTheme = useServerTheme();
  const { server: currentServer, primaryColor, primaryAnchorColor, navColor, navTextColor, transparentBackgroundColor } = serverTheme;//useServerTheme();

  // const { results: allEvents, loading: loadingEvents, reload: reloadEvents, hasMorePages, firstPageLoaded } =
  //   useEventPages(EventListingType.ALL_ACCESSIBLE_EVENTS);

  // const [pageLoadTime] = useState<string>(moment(Date.now()).toISOString(true));

  const numberOfColumns = mediaQuery.gtXxxxl ? 6
    : mediaQuery.gtXxl ? 5
      : mediaQuery.gtLg ? 4
        : mediaQuery.gtMd ? 3
          : mediaQuery.gtXs ? 2 : 1;

  const renderInColumns = numberOfColumns > 1;

  const widthAdjustedPageSize = renderInColumns
    ? numberOfColumns * 2
    : 8;
  useEffect(() => {
    const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
    // const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`AI Event Importer | ${serverName}`)
  });
  const pageSize = renderInColumns && shrinkPreviews
    ? mediaQuery.gtMdHeight
      ? Math.round(widthAdjustedPageSize * 2)
      : mediaQuery.gtShort
        ? Math.round(widthAdjustedPageSize * 1.5)
        : widthAdjustedPageSize
    : widthAdjustedPageSize;


  const eventCardWidth = renderInColumns
    ? (window.innerWidth - 50 - (20 * numberOfColumns)) / numberOfColumns
    : undefined;
  const maxWidth = 2000;


  // const oneLineFilterBar = mediaQuery.xShort && mediaQuery.gtXs;

  const { screenWidth, screenHeight } = useScreenWidthAndHeight();

  const [aiMode, setAiMode] = useState<EventAIMode>('inputText');
  // const [aiText, setAiText] = useState<string>('');

  const [aiText, setAiText] = useLocalStorageState('aiText', '');

  // const [openAi, setOpenAi] = useState<OpenAI | undefined>(undefined);
  // const [openAiKey, setOpenAiKey] = useState<string>(localStorage.getItem('openAiKey') ?? '');
  // const debouncedApiKey = useDebounceValue(openAiKey, 1000);
  // useEffect(() => {
  //   localStorage.setItem('openAiKey', debouncedApiKey);
  //   if (debouncedApiKey) {
  //     setOpenAi(new OpenAI({ apiKey: debouncedApiKey, dangerouslyAllowBrowser: true, maxRetries: 0 }));
  //   }
  // }, [debouncedApiKey]);

  const isSafariBrowser = isSafari();
  const [llmStatusText, setLlmStatusText] = useState<string>(
    isSafariBrowser ? 'WebLLM is not supported in Safari. Use a browser with WebGPU support, like Chrome.'
      : 'Initializing WebLLM...');
  const [llmReady, setLlmReady] = useState(false);
  const availableModels = webllm.prebuiltAppConfig.model_list.map((model) => model.model_id);

  const [selectedModel, setSelectedModel] = useLocalStorageState('aiModel', 'Llama-3-8B-Instruct-q4f32_1');
  // const selectedModel = "Llama-3-8B-Instruct-q4f32_1";
  const [llmEngine, setLlmEngine] = useState<webllm.MLCEngineInterface | undefined>(undefined);
  useEffect(() => { llmEngine?.reload(selectedModel); }, [selectedModel]);


  const llmInitCallback = (report: webllm.InitProgressReport) => {
    // const label = document.getElementById("init-label");
    setLlmStatusText(report.text);
    // label.innerText = report.text;
    if (report.progress === 1) {
      setLlmStatusText(`WebLLM ${selectedModel} is ready.`);
      setLlmReady(true);
    } else {
      setLlmReady(false);
    }
  };
  useEffect(() => {
    if (webllm && !llmEngine) {
      webllm.CreateMLCEngine(
        selectedModel,
        {
          chatOpts: {
            max_gen_len: 512000,
            // temperature: 0.9,
          },
          initProgressCallback: llmInitCallback
        }
      ).then(setLlmEngine);
    }
  }, [llmEngine, webllm]);

  const [aiInstructions, setAiInstructions] = useLocalStorageState(
    'aiInstructions',
    'If event times are not specified, assume the events are from 6PM-9PM Eastern Time.'
  );
  const trimmedInstructions = aiInstructions.trim();

  type AiEventFormat = { title: string, content: string, startsAt: string, endsAt: string, location: string };
  const aiPrompt = `
I am going to send you a list of one or more events pasted from a user. Please parse them into JSON in the following format:


\`\`\`
[
  {
    "title": "Sunrise Yoga",
    "content": "Free to TRC members. $21 day pass for non-members; punch passes and other options are also available!",
    "startsAt":"2024-05-28T11:00:00.000Z",
    "endsAt":"2024-05-28T11:45:00.000Z",
    "location":  "Triangle Rock Club - Durham, 1010, Ardmore Drive, Durham, Durham County, North Carolina, 27713, United States"
  }
]
\`\`\`

All generated events should have only one instance. Do not invent content if there is none - title-only events are fine.

${trimmedInstructions ?
      `${trimmedInstructions}${trimmedInstructions.endsWith('.') ? '' : '.'} ` :
      ''}

Timestamp values should always be in UTC. Only send the JSON, no other text.

The input event text is:

${aiText}
`;
  // console.log('aiPrompt', aiPrompt);

  const [aiResultsLoading, setAiResultsLoading] = useState(false);
  const [aiResult, setAiResult] = useState<string | undefined>(undefined);
  const aiResultEvents: AiEventFormat[] | undefined = useMemo(() => {
    if (aiResult) {
      try {
        const parsedEvents = JSON.parse(aiResult);
        if (Array.isArray(parsedEvents)) {
          return parsedEvents as AiEventFormat[];
        } else {
          if (!aiResultsLoading) {
            toast.show('Error parsing AI results.');
          }
          // setAiResultEvents(undefined);
        }
      } catch (e) {
        if (!aiResultsLoading) {
          toast.show('Error parsing AI results. See browser console for error info.');
          console.error('error parsing AI results', e);
        }
        // setAiResultEvents(undefined);
      }
    } else {
      // setAiResultEvents(undefined);
    }
  }, [aiResult]);
  // const [aiResultEvents, setAiResultEvents] = useState<AiEventFormat[] | undefined>(undefined);
  // const { creationServer } = useCreationServer();
  const { account, server } = useCreationAccountOrServer();
  const resultEvents: FederatedEvent[] = aiResultEvents?.map((event, index) => ({
    serverHost: server?.host ?? 'no-host',
    ...Event.create({
      id: `ai-event-${index}`,
      post: {
        title: event.title,
        content: event.content,
        author: Author.create(account?.user ?? {}),
      },
      instances: [
        {
          startsAt: event.startsAt,
          endsAt: event.endsAt,
          location: event.location
            ? Location.create({ uniformlyFormattedAddress: event.location })
            : undefined
        }
      ],
    })
  })) ?? [];
  useEffect(() => {
    if (resultEvents.length > 0) {
      setAiMode('previewEvents');
    }
  }, [resultEvents.length])


  const pagination = usePaginatedRendering(
    resultEvents,
    pageSize
  );
  const paginatedEvents = pagination.results;

  // useEffect(() => {
  //   if (firstPageLoaded) {
  //     dismissScrollPreserver(setShowScrollPreserver);
  //   }
  // }, [firstPageLoaded]);
  // const [parsedAiResul]
  // const parsedAiResultEvents = aiResult ? JSON.parse(aiResult) : undefined;
  // const aiResultEvents = Array.isArray(parsedAiResultEvents)
  //   ? parsedAiResultEvents
  //   : undefined;
  // const aiMode: EventAIMode = 'inputText'

  async function getAiResults() {
    if (!llmEngine) return;

    if (aiMode !== 'setupAi') {
      setAiMode('setupAi');
    }
    setAiResult(undefined);
    setAiResultsLoading(true);
    try {
      // const chatCompletion = await openAi.chat.completions.create({
      //   messages: [{ role: 'user', content: aiPrompt }],
      //   model: 'gpt-3.5-turbo',
      // });
      const stream = await llmEngine.chat.completions.create({
        messages: [{ "role": "user", "content": aiPrompt }],
        stream: true,
      });

      let message = "";
      for await (const chunk of stream) {
        const token = chunk.choices[0]?.delta?.content || '';
        message += token;
        // if (token.length > 0) {
        setAiResult(message);
        // }
      }
      const finalResult = await llmEngine.getMessage();
      setAiResult(finalResult);
      console.log("LLM final message:\n", finalResult);
    } catch (e) {
      console.error('error getting AI results', e);
      toast.show('Error getting AI results. See browser console for error info.');
    } finally {
      // debugger;
      // setTimeout(() => 
      setAiResultsLoading(false);
      // , 3000);
    }
  }

  async function createEvents() {
    toast.show('TODO: Creating events...');
  }

  const calendarEventsView = [
    bigCalendar
      ? <div key='bigcalendar-rendering'>
        <EventsFullCalendar events={resultEvents}
          scrollToTime={resultEvents[0]?.instances[0]?.startsAt} />
      </div>
      : renderInColumns
        ? [
          <div key='pages-top' id='pages-top'>
            <PageChooser {...pagination} />
          </div>,
          <div key={`multi-column-rendering-page-${pagination.page}`}>
            {/* <YStack gap='$2' width='100%' > */}
            <XStack mx='auto' jc='center' flexWrap='wrap'>
              {/* <AnimatePresence> */}
              {resultEvents.length === 0
                ? <XStack key='no-events-found' style={{ width: '100%', margin: 'auto' }}
                // animation='standard' {...standardAnimation}
                >
                  <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                    <Heading size='$5' mb='$3' o={0.5}>No events found.</Heading>
                  </YStack>
                </XStack>
                : undefined}
              {paginatedEvents.map((event) => {
                return <XStack key={federateId(event.instances[0]?.id ?? '', currentServer)}
                  animation='standard' {...standardAnimation}
                >
                  <XStack w={eventCardWidth}
                    mx='$1' px='$1'>
                    <EventCard event={event} isPreview />
                  </XStack>
                </XStack>;
              })}
              {/* </FlipMove> */}
              {/* </AnimatePresence> */}
            </XStack>
          </div>,
          <div key='pages-bottom' id='pages-bottom'>
            <PageChooser {...pagination} pageTopId='pages-top' showResultCounts
              entityName={{ singular: 'event', plural: 'events' }} />
          </div>,
        ]
        : [
          <div id='pages-top' key='pagest-top'>
            <PageChooser {...pagination} />
          </div>,

          resultEvents.length === 0
            ? <div key='no-events-found' style={{ width: '100%', margin: 'auto' }}>
              <YStack width='100%' maw={600} jc="center" ai="center" mx='auto'>
                <Heading size='$5' o={0.5} mb='$3'>No events found.</Heading>
                {/* <Heading size='$2' o={0.5} ta='center'>The events you're looking for may either not exist, not be visible to you, or be hidden by moderators.</Heading> */}
              </YStack>
            </div>
            : undefined,

          paginatedEvents.map((event) => {
            return <div key={`event-preview-${federatedId(event)}-${event.instances[0]!.id}`}>
              <XStack w='100%'>
                <EventCard event={event} key={federateId(event.instances[0]?.id ?? '', currentServer)} isPreview />
              </XStack>
            </div>
          }),

          <div key='pages-bottom' style={{ width: '100%', margin: 'auto' }}>
            <PageChooser {...pagination} pageTopId='pages-top' showResultCounts
              entityName={{ singular: 'event', plural: 'events' }} />
          </div>
        ],
    showScrollPreserver && !bigCalendar ? <div key='scroll-preserver' style={{ height: 100000 }} /> : undefined

  ];
  const [showPromptPreview, setShowPromptPreview] = useState(false);
  const canCreateEvents = (aiResultEvents?.length ?? 0) > 0 && account
    && hasPermission(account.user, Permission.CREATE_EVENTS);
  const canParseText = !aiResultsLoading && aiText.length > 0 && llmReady;
  return (
    <TabsNavigation
      appSection={AppSection.EVENTS}
      groupPageForwarder={(groupIdentifier) => `/g/${groupIdentifier}/events`}
      groupPageReverse='/events'
      // withServerPinning
      showShrinkPreviews={!bigCalendar}
      loading={aiResultsLoading}
      topChrome={<YStack w='100%' my='$1' py='$1'>
        <CreationServerSelector requiredPermissions={[Permission.CREATE_EVENTS]} />
        <XStack w='100%'>
          <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'nav', aiMode === 'inputText')}
            onPress={() => setAiMode('inputText')}>
            Input Text
          </Button>
          <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'nav', aiMode === 'setupAi')}
            onPress={() => setAiMode('setupAi')}>
            Setup LLM
          </Button>
          <Tooltip>
            <Tooltip.Trigger f={1}>
              <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'nav', aiMode === 'previewEvents')}
                onPress={() => setAiMode('previewEvents')}
                disabled={resultEvents.length === 0}
                o={resultEvents.length === 0 ? 0.5 : 1}
              >
                Preview Events
              </Button>
            </Tooltip.Trigger>
            {resultEvents.length === 0
              ? <Tooltip.Content>
                <Paragraph size='$2' o={0.5}>
                  There are no events to preview. Process some text with AI first.
                </Paragraph>
              </Tooltip.Content>
              : undefined}
          </Tooltip>
        </XStack>
      </YStack>}
      bottomChrome={<YStack w='100%' my='$1' py='$1'>
        <XStack w='100%' ai='center' gap='$2' px='$2'>
          <Paragraph f={1} size='$2'>
            {llmStatusText}
          </Paragraph>

          {aiMode === 'previewEvents'
            ? <Button onPress={() => setBigCalendar(!bigCalendar)}
              icon={CalendarIcon}
              transparent
              disabled={aiMode !== 'previewEvents'}
              {...themedButtonBackground(
                bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)}
              o={aiMode === 'previewEvents' ? 1 : 0.5} />
            : undefined}

          {aiResultsLoading
            ? <Button onPress={() => llmEngine?.interruptGenerate()}>
              Stop Processing
            </Button>
            : <Button {...highlightedButtonBackground(serverTheme, 'primary')}
              disabled={!canParseText}
              o={canParseText ? 1 : 0.5}
              onPress={getAiResults}
            >
              Process with LLM
            </Button>
          }

          <Button {...highlightedButtonBackground(serverTheme, 'primary', (aiResultEvents?.length ?? 0) > 0)}
            disabled={!canCreateEvents}
            o={canCreateEvents ? 1 : 0.5}
            onPress={createEvents}
          >
            {`Create ${aiResultEvents?.length ?? 0} ${aiResultEvents?.length === 1 ? 'Event' : 'Events'}`}
          </Button>
          {/* <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'primary', aiMode === 'setupAi')}
            onPress={() => setAiMode('setupAi')}>
            Setup AI
          </Button>
          <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'primary', aiMode === 'previewEvents')}
            onPress={() => setAiMode('previewEvents')}>
            Preview Events
          </Button>

          <Button onPress={() => setBigCalendar(!bigCalendar)}
            icon={CalendarIcon}
            transparent
            {...themedButtonBackground(
              bigCalendar ? navColor : undefined, bigCalendar ? navTextColor : undefined)} /> */}

        </XStack>
      </YStack>}
    >
      <YStack f={1} w='100%' jc="center" ai="center"
        mt={bigCalendar ? mediaQuery.xShort ? '$15' : 0 : '$3'}
        mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        // mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        px='$3'
        maw={maxWidth}>
        <FlipMove style={{ width: '100%' }} maintainContainerHeight>
          {[
            aiMode === 'inputText'
              ? <div key='input-text'>
                <TextArea key='bio-edit' animation='quick'
                  value={aiText} onChangeText={setAiText}
                  // size='$5'
                  // h='$14'
                  w={screenWidth} h={screenHeight}
                  placeholder={`Paste any text here to extract events from it using AI.`}
                />
              </div>
              : undefined,
            aiMode === 'setupAi'
              ? [
                // <Heading size='$3' key='openai-api-key-header'>OpenAI API Key</Heading>,
                // <XStack w='100%' gap='$2' ai='center'>
                //   <Key />
                //   <Input textContentType="password" f={1}
                //     key='openai-api-key'
                //     my='auto'
                //     mr='$2'
                //     placeholder={`OpenAI API key`}
                //     // disabled={editingDisabled} opacity={editingDisabled || username == '' ? 0.5 : 1}
                //     // autoCapitalize='words'
                //     value={openAiKey}
                //     onChange={(data) => { setOpenAiKey(data.nativeEvent.text) }} />
                // </XStack>,

                <div key='model-header'>
                  <Heading size='$3'>WebLLM Model</Heading>
                </div>,
                <div key='ai-model'
                // style={llmReady
                //   ? {}
                //   : { opacity: 0.5, pointerEvents: 'none' }}
                >
                  <Select native
                    value={selectedModel}
                    onValueChange={setSelectedModel}
                  // disabled={!llmReady}
                  >
                    <Select.Trigger w='100%' f={1} iconAfter={ChevronDown}
                      disabled={!llmReady}
                    >
                      <Select.Value w='100%' placeholder="Choose LLM" />
                    </Select.Trigger>
                    <Select.Content zIndex={200000} >
                      <Select.Viewport minWidth={200} w='100%'>
                        <XStack w='100%'>
                          <Select.Group gap="$0" w='100%'>
                            <Select.Label w='100%'>AI Model</Select.Label>
                            {availableModels.map((model, i) => {
                              return (
                                <Select.Item w='100%' index={i} key={`${model}`} value={model.toString()}>
                                  <Select.ItemText w='100%'>
                                    {model}
                                  </Select.ItemText>
                                  <Select.ItemIndicator ml="auto">
                                    <Check size={16} />
                                  </Select.ItemIndicator>
                                </Select.Item>
                              )
                            })}
                          </Select.Group>
                          <YStack
                            position="absolute"
                            right={0}
                            top={0}
                            bottom={0}
                            alignItems="center"
                            justifyContent="center"
                            width={'$4'}
                            pointerEvents="none"
                          >
                            <ChevronDown size='$2' />
                          </YStack>
                        </XStack>
                      </Select.Viewport>
                    </Select.Content>
                  </Select>
                </div>,
                <div key='instructions-header'>
                  <Heading size='$3'>Custom Instructions</Heading>
                </div>,
                <div key='bio-edit'>
                  <TextArea animation='quick'
                    value={aiInstructions} onChangeText={setAiInstructions}
                    w='100%' h='auto'
                    // size='$5'
                    // h='$14'
                    // w={screenWidth} h={screenHeight}
                    placeholder={`Give the AI custom instructions.`}
                  />
                </div>,

                aiResult || aiResultsLoading ? [
                  <div key='result-header'>
                    <XStack ai='center' gap='$3'>
                      <Heading size='$3'>LLM Result</Heading>
                      {aiResultsLoading
                        ? <Spinner size='small' />
                        : undefined}
                    </XStack>
                  </div>,
                  <div key='ai-result' style={{ opacity: 0.5, paddingBottom: 16 }}>
                    <YStack o={0.5}>
                      <TamaguiMarkdown key='ai-result' text={aiResult} shrink />
                    </YStack>
                  </div>,
                ] : undefined,

                <div key='prompt-preview-toggle'>
                  <Button key='prompt-preview-toggle' onPress={() => setShowPromptPreview(!showPromptPreview)}>
                    <XStack ai='center'>
                      <Heading key='prompt-header' f={1} size='$3'>Prompt Preview</Heading>
                      <XStack animation='standard' rotate={showPromptPreview ? '90deg' : '0deg'}>
                        <ChevronRight size='$3' />
                      </XStack>
                    </XStack>
                  </Button>
                </div>,
                showPromptPreview
                  ? <div key='ai-prompt' style={{ width: '100%' }} >
                    <YStack o={0.5}>
                      <TamaguiMarkdown key='ai-prompt' text={aiPrompt} shrink />
                    </YStack>
                  </div>
                  : undefined,
                // <Paragraph size='$2'>{aiPrompt}</Paragraph>
              ]
              : undefined,
            aiMode === 'previewEvents'
              ? calendarEventsView
              : undefined
          ]}
        </FlipMove>

      </YStack >
    </TabsNavigation >
  )
}
