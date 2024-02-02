import { useEffect, useState } from "react";

export function useIsVisible(ref/*: React.MutableRefObject<Element>*/): boolean {
  const [isIntersecting, setIntersecting] = useState(false);

  useEffect(() => {
    // try {
    if (ref.current) {
      const observer = new IntersectionObserver(([entry]) =>
        entry && setIntersecting(entry.isIntersecting)
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
