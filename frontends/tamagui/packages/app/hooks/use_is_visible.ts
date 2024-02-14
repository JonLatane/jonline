import { useEffect, useState } from "react";

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
