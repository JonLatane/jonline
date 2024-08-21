import { Author, Event, Location, Permission } from '@jonline/api';
import * as webllm from "@mlc-ai/web-llm";
import 'react-big-calendar/lib/css/react-big-calendar.css';

import { Button, Heading, Input, Paragraph, Select, Spinner, TextArea, Tooltip, XStack, YStack, useDebounceValue, useMedia, useToastController } from '@jonline/ui';
import { FederatedEvent, useServerTheme } from 'app/store';
import React, { useEffect, useMemo, useState } from 'react';

import { useBigCalendar } from "app/hooks/configuration_hooks";
import FlipMove from 'lumen5-react-flip-move';
import { AppSection } from '../navigation/features_navigation';
import { TabsNavigation } from '../navigation/tabs_navigation';

import { useScreenWidthAndHeight } from "../event/events_full_calendar";

import { Calendar as CalendarIcon, Check, ChevronDown, ChevronRight, Eye, EyeOff, Key } from '@tamagui/lucide-icons';
import { hasPermission, highlightedButtonBackground, setDocumentTitle, themedButtonBackground } from 'app/utils';
import OpenAI from 'openai';
import { isSafari } from '../../../ui/src/global';
import { useCreationAccountOrServer } from '../../hooks/account_or_server/use_creation_account_or_server';
import { CreationServerSelector } from '../accounts/creation_server_selector';
import { TamaguiMarkdown } from '../post';
import { EventListingLarge } from './event_listing_large';

export type EventAIScreenProps = {}

export type EventAIMode = 'inputText' | 'setupAi' | 'previewEvents';
export type EventAIBackend = 'webLlm' | 'openAi';

export function useLocalStorageState<T extends string>(key: string, defaultValue: T) {
  const [value, setValue] = useState<T>(
    localStorage.getItem(key) as T ??
    defaultValue
  );
  const debouncedValue = useDebounceValue(value, 1000);
  useEffect(() => {
    localStorage.setItem(key, debouncedValue);
  }, [debouncedValue]);

  return [value, setValue] as const;
}

export const useLocalStorageString = (key: string, defaultValue: string) =>
  useLocalStorageState<string>(key, defaultValue);

// WebLLM gives us easy control to cancel generation.
// OpenAI APIs are make canceling generation impossible,
// and force devs to use globals like this in their React apps
// if we want to cancel streaming generation.
// No idea if this works because my OpenAI API key doesn't seem to work.
let abortStreaming = false;

export const EventAIScreen: React.FC<EventAIScreenProps> = () => {
  const { account, server } = useCreationAccountOrServer();

  const serverTheme = useServerTheme();
  const { server: currentServer, navColor, navTextColor } = serverTheme;

  const toast = useToastController();
  const mediaQuery = useMedia();
  const { bigCalendar, setBigCalendar } = useBigCalendar();


  useEffect(() => {
    const serverName = currentServer?.serverConfiguration?.serverInfo?.name || '...';
    // const title = selectedGroup ? `${selectedGroup.name} | ${serverName}` : serverName;
    setDocumentTitle(`AI Event Importer | ${serverName}`)
  });

  const { screenWidth, screenHeight } = useScreenWidthAndHeight();

  const isSafariBrowser = isSafari();
  const [aiMode, setAiMode] = useState<EventAIMode>('inputText');
  const [aiBackend, setAiBackend] = useLocalStorageState<EventAIBackend>(
    'aiBackend',
    isSafariBrowser ? 'openAi' : 'webLlm'
  );

  const [aiText, setAiText] = useLocalStorageString('aiText', '');

  const [openAi, setOpenAi] = useState<OpenAI | undefined>(undefined);
  const [revealOpenAiKey, setRevealOpenAiKey] = useState(false);
  const [openAiKey, setOpenAiKey] = useState<string>(localStorage.getItem('openAiKey') ?? '');
  const debouncedApiKey = useDebounceValue(openAiKey, 1000);
  useEffect(() => {
    localStorage.setItem('openAiKey', debouncedApiKey);
    if (debouncedApiKey) {
      setOpenAi(new OpenAI({ apiKey: debouncedApiKey, dangerouslyAllowBrowser: true, maxRetries: 0 }));
    }
  }, [debouncedApiKey]);

  const [llmStatusText, setLlmStatusText] = useState<string>(
    isSafariBrowser ? 'WebLLM is not supported in Safari.'
      : 'Initializing WebLLM...');
  const [llmReady, setLlmReady] = useState(false);
  const availableModels = webllm.prebuiltAppConfig.model_list.map((model) => model.model_id);

  const [llmModel, setLlmModel] = useLocalStorageString('weblLlmModel', 'Llama-3-8B-Instruct-q4f32_1');
  // const selectedModel = "Llama-3-8B-Instruct-q4f32_1";
  const [llmEngine, setLlmEngine] = useState<webllm.MLCEngineInterface | undefined>(undefined);
  useEffect(() => { llmEngine?.reload(llmModel); }, [llmModel]);

  useEffect(() => {
    if (aiBackend === 'openAi') {
      llmEngine?.unload();
    } else {
      llmEngine?.reload(llmModel);
    }
  }, [aiBackend])

  const llmInitCallback = (report: webllm.InitProgressReport) => {
    setLlmStatusText(report.text);

    if (report.progress === 1) {
      setLlmStatusText(`WebLLM ${llmModel} is ready.`);
      setLlmReady(true);
    } else {
      setLlmReady(false);
    }
  };

  useEffect(() => {
    if (webllm && aiBackend === 'webLlm' && !llmEngine) {
      webllm.CreateMLCEngine(
        llmModel,
        {
          chatOpts: {
            max_gen_len: 512000,
            // temperature: 0.9,
          },
          initProgressCallback: llmInitCallback
        }
      ).then(setLlmEngine);
    }
  }, [llmEngine, webllm, aiBackend]);

  const [aiInstructions, setAiInstructions] = useLocalStorageString(
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
      `${trimmedInstructions}${trimmedInstructions.endsWith('.') ||
        trimmedInstructions.endsWith('!')
        ? ''
        : '.'} ` :
      ''}

Timestamp values should always be in UTC. Only send the JSON, no other text.

The input event text is:

${aiText}
`;

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
        }
      } catch (e) {
        if (!aiResultsLoading) {
          toast.show('Error parsing AI results. See browser console for error info.');
          console.error('error parsing AI results', e);
        }
      }
    }
  }, [aiResult]);
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


  useEffect(() => {
    if (!aiResultsLoading && abortStreaming) {
      abortStreaming = false;
    }
  }, [abortStreaming, aiResultsLoading])

  const [openAiModel, setOpenAiModel] = useLocalStorageString('openAiModel', 'gpt-3.5-turbo');
  const openAiModelOptions = [
    'gpt-3.5-turbo',
    'gpt-4',
  ];
  async function getAiResults() {
    if (aiBackend === 'webLlm' && !llmEngine) return;
    if (aiBackend === 'openAi' && !openAi) return;

    if (aiMode !== 'setupAi') {
      setAiMode('setupAi');
    }
    abortStreaming = false;
    setAiResult(undefined);
    setAiResultsLoading(true);
    try {
      const webllmStream = aiBackend === 'webLlm'
        ? await llmEngine?.chat.completions.create({
          messages: [{ "role": "user", "content": aiPrompt }],
          stream: true,
        })
        : undefined;
      const openAiStream = aiBackend === 'openAi'
        ? await openAi?.chat.completions.create({
          model: openAiModel,
          messages: [{ role: 'user', content: aiPrompt }],
          stream: true,
        })
        : undefined;
      const stream = webllmStream ?? openAiStream;

      if (!stream) {
        toast.show("Error getting AI results. No stream.")
        return;
      }

      let message = "";
      for await (const chunk of stream) {
        if (abortStreaming) {
          abortStreaming = false;
          break;
        }

        const token = chunk.choices[0]?.delta?.content || '';
        message += token;
        setAiResult(message);
      }
      const finalResult = aiBackend === 'webLlm'
        ? await llmEngine!.getMessage()
        : message;
      setAiResult(finalResult);
      console.log("LLM final message:\n", finalResult);
    } catch (e) {
      console.error('error getting AI results', e);
      toast.show('Error getting AI results. See browser console for error info.');
    } finally {
      setAiResultsLoading(false);
    }
  }

  async function createEvents() {
    toast.show('TODO: Creating events...');
  }

  const [showPromptPreview, setShowPromptPreview] = useState(false);
  const canCreateEvents = (aiResultEvents?.length ?? 0) > 0 && account
    && hasPermission(account.user, Permission.CREATE_EVENTS);
  const canParseText = !aiResultsLoading && aiText.length > 0 && (
    (aiBackend === 'webLlm' && llmReady) ||
    (aiBackend === 'openAi' && openAi && openAiKey.length > 0)
  );
  const eventListing = EventListingLarge({ events: resultEvents });
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
        {/* {aiMode === 'setupAi'
          ?
          <XStack w='100%'>
            <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'primary', aiBackend === 'webLlm')}
              onPress={() => setAiBackend('webLlm')}>
              WebLLM
            </Button>
            <Button f={1} transparent
              {...highlightedButtonBackground(serverTheme, 'primary', aiBackend === 'openAi')}
              onPress={() => setAiBackend('openAi')}>
              OpenAI
            </Button>
          </XStack>
          : undefined} */}
      </YStack>}
      bottomChrome={<YStack w='100%' my='$1' py='$1'>
        <XStack w='100%' ai='center' gap='$2' px='$2'>
          <Paragraph f={1} size='$2'>
            {aiBackend === 'webLlm' ? llmStatusText : undefined}
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
            ? <Button onPress={() => {
              llmEngine?.interruptGenerate();
              abortStreaming = true;
            }}>
              Stop Processing
            </Button>
            : <Tooltip>
              <Tooltip.Trigger>
                <Button {...highlightedButtonBackground(serverTheme, 'primary')}
                  disabled={!canParseText}
                  o={canParseText ? 1 : 0.5}
                  onPress={getAiResults}
                >
                  Process with LLM
                </Button>
              </Tooltip.Trigger>
              {aiText.length === 0
                ? <Tooltip.Content>
                  <Paragraph size='$2'>
                    Paste some text to process with AI.
                  </Paragraph>
                </Tooltip.Content>
                : aiBackend === 'openAi' && openAiKey.length === 0
                  ? <Tooltip.Content>
                    <Paragraph size='$2'>
                      Enter an OpenAI API key to use OpenAI.
                    </Paragraph>
                  </Tooltip.Content>
                  : aiBackend === 'webLlm' && !llmReady
                    ? <Tooltip.Content>
                      <Paragraph size='$2'>
                        Wait for WebLLM to finish initializing.
                      </Paragraph>
                    </Tooltip.Content>
                    : undefined}
            </Tooltip>
          }
          <Tooltip>
            <Tooltip.Trigger>
              <Button {...highlightedButtonBackground(serverTheme, 'primary', (aiResultEvents?.length ?? 0) > 0)}
                disabled={!canCreateEvents}
                o={canCreateEvents ? 1 : 0.5}
                onPress={createEvents}
              >
                {`Create ${aiResultEvents?.length ?? 0} ${aiResultEvents?.length === 1 ? 'Event' : 'Events'}`}
              </Button>
            </Tooltip.Trigger>
            {!canCreateEvents
              ? <Tooltip.Content>
                <Paragraph size='$2'>
                  Process some text with AI first.
                </Paragraph>
              </Tooltip.Content>
              : undefined}
          </Tooltip>
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
      <YStack f={1} w='100%' //jc="center" 
        ai="center"
        mt={bigCalendar ? mediaQuery.xShort ? '$15' : 0 : '$3'}
        mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        // mb={bigCalendar && mediaQuery.xShort ? '$15' : 0}
        px='$3'
        maw={2000}>
        <FlipMove style={{ width: '100%', minHeight: '100%', display: 'flex', flexDirection: 'column', gap: 25 }}>
          {[
            aiMode === 'inputText'
              ? <div key='input-text'>
                <TextArea key='bio-edit' animation='standard'
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

                <div key='ai-backend'>
                  <YStack w='100%' mt='$3'>
                    <Heading size='$3'>LLM Backend</Heading>
                    <XStack w='100%'>
                      <Button f={1} transparent {...highlightedButtonBackground(serverTheme, 'primary', aiBackend === 'webLlm')}
                        onPress={() => setAiBackend('webLlm')}>
                        WebLLM
                      </Button>
                      <Button f={1} transparent
                        {...highlightedButtonBackground(serverTheme, 'primary', aiBackend === 'openAi')}
                        onPress={() => setAiBackend('openAi')}>
                        OpenAI
                      </Button>
                    </XStack>
                  </YStack>
                </div>,

                aiBackend === 'openAi'
                  ? [
                    <div key='openai-config'>
                      <YStack w='100%'>
                        <Heading size='$3'>OpenAI API Key</Heading>
                        <XStack w='100%' gap='$2' ai='center'>
                          <Key />
                          <Input textContentType="password" f={1}
                            key='openai-api-key'
                            my='auto'
                            placeholder={`OpenAI API key`}
                            secureTextEntry={!revealOpenAiKey}
                            value={openAiKey}
                            onChange={(data) => { setOpenAiKey(data.nativeEvent.text) }} />
                          <Button circular
                            icon={revealOpenAiKey ? EyeOff : Eye}
                            onPress={() => setRevealOpenAiKey(!revealOpenAiKey)} />
                        </XStack>

                        <Heading size='$3'>OpenAI Model</Heading>
                        <Select native
                          value={openAiModel}
                          onValueChange={setOpenAiModel}
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
                                  {openAiModelOptions.map((model, i) => {
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
                      </YStack>
                    </div>
                  ]
                  : undefined,

                aiBackend === 'webLlm'
                  ? [
                    <div key='webllm-config'>
                      <YStack w='100%'>
                        <Heading size='$3'>WebLLM Model</Heading>
                        <Select native
                          value={llmModel}
                          onValueChange={setLlmModel}
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
                      </YStack>
                    </div>,
                  ]
                  : undefined,

                aiResult || aiResultsLoading
                  ? <div key='result'>
                    <YStack w='100%'>
                      <XStack ai='center' gap='$3'>
                        <Heading size='$3'>LLM Result</Heading>
                        {aiResultsLoading
                          ? <Spinner size='small' />
                          : undefined}
                      </XStack>

                      <YStack o={0.5}>
                        <TamaguiMarkdown key='ai-result' text={aiResult} shrink />
                      </YStack>
                    </YStack>
                  </div>
                  : undefined,

                <div key='instructions'>
                  <YStack w='100%'>
                    <Heading size='$3'>Custom Instructions</Heading>
                    <TextArea
                      value={aiInstructions} onChangeText={setAiInstructions}
                      w='100%' h='auto'
                      placeholder={`Give the AI custom instructions.`}
                    />
                  </YStack>
                </div>,

                <div key='prompt-preview-toggle'>
                  <Button key='prompt-preview-toggle' onPress={() => setShowPromptPreview(!showPromptPreview)}>
                    <XStack ai='center'>
                      <Heading key='prompt-header' f={1} size='$3'>Prompt Preview</Heading>
                      <XStack animation='standard' rotate={showPromptPreview ? '90deg' : '0deg'}>
                        <ChevronRight size='$2' />
                      </XStack>
                    </XStack>
                  </Button>
                </div>,
                showPromptPreview
                  ? <div key='ai-prompt' style={{ width: '100%', marginTop: -25 }} >
                    <YStack o={0.5}>
                      <TamaguiMarkdown key='ai-prompt' text={aiPrompt} shrink />
                    </YStack>
                  </div>
                  : undefined,
                // <Paragraph size='$2'>{aiPrompt}</Paragraph>
              ]
              : undefined,
            aiMode === 'previewEvents'
              ? eventListing//<EventListingLarge events={resultEvents} />//calendarEventsView
              : undefined
          ]}
        </FlipMove>

      </YStack >
    </TabsNavigation >
  )
}
