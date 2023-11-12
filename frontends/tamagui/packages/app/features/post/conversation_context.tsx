import { useState } from 'react'

import { createContext, useContext } from "react"

export type ConversationContextType = {
  // All the post IDs (or event post IDs) that are currently being edited.
  editingPosts: string[];
  // The top-down path to the post ID that is being replied to in a ReplyArea.
  replyPostIdPath: string[];
  // Set the top-down path to the post ID that is being replied to in a ReplyArea.
  setReplyPostIdPath: (postIdPath: string[]) => void;
  // Handler for when post editing begins or ends. Sets editingPosts.
  editHandler: (postId: string) => (editing: boolean) => void;
};

export const ConversationContext = createContext<ConversationContextType | undefined>(undefined);

export const ConversationContextProvider = ConversationContext.Provider;
export const useConversationContext = () => useContext(ConversationContext);

export function useStatefulConversationContext(): ConversationContextType {
  const [editingPosts, setEditingPosts] = useState([] as string[]);
  const [replyPostIdPath, setReplyPostIdPath] = useState([] as string[]);

  
  const editHandler = (postId: string) => ((editing: boolean) => {
    if (editing) {
      setEditingPosts([...editingPosts, postId]);
    } else {
      setEditingPosts(editingPosts.filter(p => p != postId));
    }
  });

  return { editingPosts, replyPostIdPath, setReplyPostIdPath, editHandler };
}
