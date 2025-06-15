import { RefObject, useEffect, useMemo, useState } from "react";
import { View } from "react-native";

export function useIsVisible(ref/*: React.MutableRefObject<Element>*/, noisy?: boolean): boolean {
  const [isIntersecting, setIntersecting] = useState(false);

  useEffect(() => {
    // try {
    if (ref.current) {
      const observer = new IntersectionObserver(([entry]) => {
        if (noisy)
          console.log("observer entry", entry);
        entry && setIntersecting(entry.isIntersecting);
      },
        { threshold: 0.1 }
      );

      observer.observe(ref.current);
      return () => {
        observer.disconnect();
      };
    }
    // } catch (e) {
    //   console.warn("Error measuring element visibility", e);
    // }
  }, [ref.current]);

  return isIntersecting;
}

export default function useIsVisibleHorizontal(ref: RefObject<HTMLElement | null>) {
  const [isIntersecting, setIntersecting] = useState(false)

  const observer = useMemo(() => new IntersectionObserver(
    ([entry]) => entry
      ? setIntersecting(entry.isIntersecting)
      : console.warn('useIsVisibleHorizontal: entry is null')
  ), [ref])


  useEffect(() => {
    if (ref.current) {
      observer.observe(ref.current)
    } else {
      console.warn('useIsVisibleHorizontal: ref.current is null')
    }
    return () => observer.disconnect()
  }, [])

  return isIntersecting
}