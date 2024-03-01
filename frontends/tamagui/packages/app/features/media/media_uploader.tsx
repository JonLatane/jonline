import { Button, Heading, Progress, Text, XStack, YStack, isTouchable, isWebTouchable, useWindowDimensions } from '@jonline/ui';
import { Upload } from '@tamagui/lucide-icons';
import { useAccountOrServer } from 'app/hooks';
import { getCredentialClient, serverUrl, useServerTheme } from 'app/store';
import React, { useState } from 'react';
import { FileUploader } from "react-drag-drop-files";
import { resizeImage } from './resize_media';
import { useMediaPages } from 'app/hooks/pagination/media_pagination_hooks';


interface MediaUploaderProps {
  uploading: boolean;
  setUploading: (uploading: boolean) => void;
  uploadProgress: number | undefined;
  setUploadProgress: (progress: number | undefined) => void;
  onMediaUploaded?: (mediaId: string) => void;
}
export const MediaUploader: React.FC<MediaUploaderProps> = ({ uploading, setUploading, uploadProgress, setUploadProgress, onMediaUploaded }) => {
  const accountOrServer = useAccountOrServer();
  const { server, primaryColor, primaryTextColor, navColor, navTextColor } = useServerTheme();
  const dimensions = useWindowDimensions();
  const [dragging, setDragging] = useState(false);

  const { reload: reloadMedia } = useMediaPages();

  // useEffect(() => {
  //   let title = 'Media';
  //   title += ` | ${server?.serverConfiguration?.serverInfo?.name || '...'}`;
  //   setDocumentTitle(title)
  // });

  function handleUpload(arg: File | Array<File>) {
    if (!server) return;

    const currentServer = server;
    console.log("Uploading file...");

    async function uploadFile(file: File) {
      // Updates the access token in case it needs updating.
      getCredentialClient(accountOrServer);

      const uploadUrl = `${serverUrl(currentServer)}/media`

      setUploading(true);

      let _data: Blob | null = null;
      switch (file.type) {
        case "image/jpeg":
        case "image/jpg":
        case "image/png":
        // case "image/svg":
        case "image/wepb":
          _data = await resizeImage(file, 1920, 1920);
      }
      if (_data == null) {
        _data = file;
      }
      const fileData = _data;

      const xhr = new XMLHttpRequest();
      xhr.upload.addEventListener("progress", (event) => {
        if (event.lengthComputable) {
          // console.log("upload progress:", event.loaded / event.total);
          setUploadProgress(0.9 * (event.loaded / event.total));
        }
      });
      xhr.addEventListener("loadend", () => {
        setUploading(false);
        setUploadProgress(1);
        setTimeout(() => setUploadProgress(undefined), 1000);
        reloadMedia();
      });
      xhr.onreadystatechange = () => {
        if (xhr.readyState === 4) {
          const newMediaId = xhr.responseText;
          onMediaUploaded?.(newMediaId);
        }
      };
      xhr.open("POST", uploadUrl, true);
      xhr.setRequestHeader("Authorization", accountOrServer.account?.accessToken?.token || '');
      xhr.setRequestHeader("Filename", file.name);
      xhr.setRequestHeader("Content-Type", file.type);
      xhr.send(fileData);
    }

    if (arg instanceof File) {
      uploadFile(arg);
    } else {
      for (const file of arg) {
        uploadFile(file);
      }
    }
  }
  return (
    <YStack mb={-19} maw={600} p='$5' als='center' overflow='hidden'>
      <Text fontFamily='$body' fontSize='$3' mx='auto' mb='$3'>
        <FileUploader handleChange={handleUpload} name="file"
          label='Add Media'
          width='250px'
          onDraggingStateChange={setDragging}
          types={["JPG", "JPEG", "PNG", "SVG", "WEBP", "GIF", "PDF", "MOV", "AVI", "OGG", "MP3", "MP4", "MPG", "WEBM", "WEBP", "WMV"]}>
          <Button onPress={() => { }}
            backgroundColor={dragging ? primaryColor : navColor}
            opacity={0.95}
            hoverStyle={{ opacity: 1, backgroundColor: dragging ? primaryColor : navColor }}>
            <XStack gap='$2'>
              <XStack my='auto'>
                <Upload size={24} color={dragging ? primaryTextColor : navTextColor} />
              </XStack>
              <YStack jc="center" ai="center" f={1} my='auto' p='$3'>
                <Heading size='$3' ta='center' color={dragging ? primaryTextColor : navTextColor}>
                  Upload Media
                </Heading>
                <Heading size='$1' ta='center' color={dragging ? primaryTextColor : navTextColor}>
                  {isTouchable || isWebTouchable ? 'Tap' : 'Drag/drop or click'} to choose
                </Heading>
              </YStack>
            </XStack>
          </Button>
        </FileUploader>
      </Text>
      <Progress value={(uploadProgress ?? 0) * 100} >
        <Progress.Indicator animation="quick" />
      </Progress>
    </YStack>
  )
}
