import { useState } from "react";

let _key = 1;
export function useComponentKey(descriptor: string) {
  return useState(`${descriptor}-${_key++}`)[0];
}
