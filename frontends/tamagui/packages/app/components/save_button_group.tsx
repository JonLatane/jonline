import { Button, Dialog, XStack, YStack } from '@jonline/ui';
import { Delete, Edit3 as Edit, Eye, Save, X as XIcon } from '@tamagui/lucide-icons';
import { useServerTheme } from 'app/store';
import React, { useEffect, useState } from 'react';
import { } from '../features/post/post_card';

export type EditableContext = {
  canEdit: boolean;
  editing: boolean;
  setEditing: (editing: boolean) => void;
  previewingEdits: boolean;
  setPreviewingEdits: (previewingEdits: boolean) => void;

  savingEdits: boolean;
  setSavingEdits: (editing: boolean) => void;
  deleting: boolean;
  setDeleting: (editing: boolean) => void;
};

const EditingContext = React.createContext<EditableContext>({
  canEdit: false,
  editing: false,
  setEditing: () => { },
  previewingEdits: false,
  setPreviewingEdits: () => { },

  savingEdits: false,
  setSavingEdits: () => { },
  deleting: false,
  setDeleting: () => { },
});



export const EditingContextProvider = EditingContext.Provider;

export function useStatefulEditingContext(canEdit: boolean): EditableContext {
  const [editing, setEditing] = useState(false);
  const [previewingEdits, setPreviewingEdits] = useState(false);

  const [deleting, setDeleting] = useState(false);
  const [savingEdits, setSavingEdits] = useState(false);
  useEffect(() => {
    if (!editing && previewingEdits) {
      setPreviewingEdits(false);
    }
  }, [editing, previewingEdits]);
  useEffect(() => {
    if (!canEdit && editing) {
      setEditing(false);
      if (previewingEdits) {
        setPreviewingEdits(false);
      }
    }
  }, [editing, canEdit]);
  return { canEdit, editing, setEditing, savingEdits, setSavingEdits, deleting, setDeleting, previewingEdits, setPreviewingEdits };
}

export function useEditingContext() {
  return React.useContext(EditingContext);
}

// Should not change editingContext?.
export function useEditableState<T>(uneditedValue: T, editingContext?: EditableContext): [T, T, (newValue: T) => void] {
  const { editing } = editingContext ?? useEditingContext();
  const [editedValue, setEditedValue] = useState(uneditedValue);
  // console.log('editing', editing, 'editedValue', editedValue, 'uneditedValue', uneditedValue)
  const value = editing ? editedValue : uneditedValue;

  useEffect(() => {
    const changed = Array.isArray(uneditedValue) || Array.isArray(editedValue)
      ? !arrayEquals(uneditedValue as Array<any>, editedValue as Array<any>)
      : uneditedValue != editedValue;

    if (changed) {
      // console.log('overwriting editedValue', editedValue, 'with uneditedValue', uneditedValue, arrayEquals(uneditedValue as Array<any>, editedValue as Array<any>))
      setEditedValue(uneditedValue);
    }
  }, [uneditedValue]);
  return [value, editedValue, setEditedValue];
}

function arrayEquals(a: Array<any>, b: Array<any>) {
  return Array.isArray(a) &&
    Array.isArray(b) &&
    a.length === b.length &&
    a.every((val, index) => val === b[index]);
}

export type SaveButtonGroupProps = {
  entityType: 'Post' | 'Event' | 'Group' | 'User' | 'Comment' | 'Media';
  entityName?: string;
  deleteDialogText?: React.JSX.Element | string;
  // When set, implicitly hides the delete button.
  deleteInstructions?: React.JSX.Element | string;

  doUpdate: () => void;
  doDelete: () => void;
}

export function SaveButtonGroup({
  entityType,
  deleteDialogText,
  deleteInstructions,
  doUpdate,
  doDelete
}: SaveButtonGroupProps) {
  const {
    canEdit,
    editing,
    setEditing,
    deleting,
    setDeleting,
    previewingEdits,
    setPreviewingEdits,
    savingEdits,
    setSavingEdits
  } = useEditingContext();
  const { primaryAnchorColor, navAnchorColor } = useServerTheme();

  const reallyDelete = () => {
    setDeleting(true);
    doDelete();
  }

  const reallyUpdate = () => {
    setSavingEdits(true);
    doUpdate();
  }

  return <XStack p='$3' gap='$2'>
    {canEdit
      ? editing
        ? <>
          <Button my='auto' size='$2' icon={Save} onPress={reallyUpdate} color={primaryAnchorColor} disabled={savingEdits} transparent>
            Save
          </Button>
          <Button my='auto' size='$2' icon={XIcon} onPress={() => setEditing(false)} disabled={savingEdits} transparent>
            Cancel
          </Button>
          {previewingEdits
            ? <Button my='auto' size='$2' icon={Edit} onPress={() => setPreviewingEdits(false)} color={navAnchorColor} disabled={savingEdits} transparent>
              Edit
            </Button>
            :
            <Button my='auto' size='$2' icon={Eye} onPress={() => setPreviewingEdits(true)} color={navAnchorColor} disabled={savingEdits} transparent>
              Preview
            </Button>}
        </>
        : <>
          <Button my='auto' size='$2' icon={Edit} onPress={() => setEditing(true)} disabled={deleting} transparent>
            Edit
          </Button>

          {deleteInstructions
            ? deleteInstructions
            : <Dialog>
              <Dialog.Trigger asChild>
                <Button my='auto' size='$2' icon={Delete}
                  disabled={deleting} transparent>
                  Delete
                </Button>
              </Dialog.Trigger>

              {/* zIndex={1000000} */}
              <Dialog.Portal zIndex={2000011}>
                <Dialog.Overlay
                  key="overlay"
                  animation='standard'
                  o={0.5}
                  enterStyle={{ o: 0 }}
                  exitStyle={{ o: 0 }}
                // zIndex={2000011}
                />
                <Dialog.Content
                  bordered
                  elevate
                  // zIndex={2000011}
                  key="content"
                  animation={[
                    'standard',
                    {
                      opacity: {
                        overshootClamping: true,
                      },
                    },
                  ]}
                  m='$3'
                  enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
                  exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
                  x={0}
                  scale={1}
                  opacity={1}
                  y={0}
                >
                  <YStack space>
                    <Dialog.Title>Delete {entityType}</Dialog.Title>
                    {typeof deleteDialogText === 'string'
                      ? <Dialog.Description>
                        {deleteDialogText}
                      </Dialog.Description>
                      : deleteDialogText
                        ? <Dialog.Content>
                          {deleteDialogText}
                        </Dialog.Content>
                        : undefined}

                    <XStack gap="$3" jc="flex-end">
                      <Dialog.Close asChild>
                        <Button>Cancel</Button>
                      </Dialog.Close>
                      <Dialog.Close asChild>
                        <Button color={primaryAnchorColor}
                          onPress={reallyDelete}>Delete</Button>
                      </Dialog.Close>
                    </XStack>
                  </YStack>
                </Dialog.Content>
              </Dialog.Portal>
            </Dialog>
          }
        </>
      : undefined}
  </XStack>;
}

