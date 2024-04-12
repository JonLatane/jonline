import { AlertDialog, Button, Heading, Paragraph, Sheet, Spinner, XStack, YStack, needsScrollPreservers, useMedia, useTheme, useWindowDimensions } from '@jonline/ui';
import { useCreationServer, useCurrentAccount, useProvidedDispatch } from 'app/hooks';
import { RootState, deleteMedia, getServerTheme, selectMediaById, useRootSelector } from 'app/store';
import React, { useEffect, useState } from 'react';

import { Media, MediaReference } from '@jonline/api';
import { overlayAnimation } from '@jonline/ui';

import { Image as ImageIcon, Trash, Wand2 } from '@tamagui/lucide-icons';

import { useMediaPages } from 'app/hooks/pagination/media_pagination_hooks';
import { MediaRenderer } from './media_renderer';
import { MediaUploader } from './media_uploader';
import { MediaRef, useMediaContext } from 'app/contexts';

interface MediaChooserProps {
  children?: React.ReactNode;
  selectedMedia: MediaRef[];
  onMediaSelected?: (media: MediaRef[]) => void;
  multiselect?: boolean;
  disabled?: boolean;
}

export const MediaChooser: React.FC<MediaChooserProps> = ({ children, selectedMedia, onMediaSelected, multiselect = false, disabled }) => {
  const { dispatch, accountOrServer } = useProvidedDispatch();
  const { server } = accountOrServer;
  const { creationServer, setCreationServer } = useCreationServer();


  const { mediaSheetOpen, setMediaSheetOpen, isSelecting, isMultiselect, selectedMedia: contextSelectedMedia, setSelectedMedia, setSelecting, setMultiselect } = useMediaContext();
  const { primaryColor, primaryTextColor, navColor, navTextColor } = getServerTheme(server, useTheme());

  const [open, setOpen] = useState(false);
  useEffect(() => {
    if (open && !mediaSheetOpen) {
      setOpen(false);
    }
  }, [mediaSheetOpen]);

  function openMedia() {
    if (creationServer?.host !== server?.host) {
      setCreationServer(server);
    }
    setSelecting(true);
    setMultiselect(multiselect);
    setSelectedMedia(selectedMedia);
    setMediaSheetOpen(true);
    setOpen(true);
  }

  useEffect(() => {
    if (open && isSelecting) {
      onMediaSelected?.(contextSelectedMedia);
    }
  }, [contextSelectedMedia.map(m => m.id).join(',')]);

  return (
    <>
      <Button backgroundColor={navColor} o={0.95} hoverStyle={{ backgroundColor: navColor, opacity: 1 }} color={navTextColor}
        disabled={disabled}
        onPress={openMedia}>
        {children ?? <XStack>
          <ImageIcon size={24} color={navTextColor} />
          <Paragraph ml='$2' color={navTextColor}>Choose Media</Paragraph>
        </XStack>}
      </Button>
    </>
  )
}
