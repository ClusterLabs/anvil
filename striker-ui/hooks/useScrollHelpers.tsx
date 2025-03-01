import React, { useCallback, useEffect, useRef, useState } from 'react';

const useScrollHelpers = <Element extends HTMLElement>(
  options: {
    follow?: boolean;
  } = {},
): {
  callbackRef: (element: Element | null) => void;
  follow: boolean;
  ref: React.MutableRefObject<Element | null>;
  setFollow: React.Dispatch<React.SetStateAction<boolean>>;
  setScrollTop: (value?: number) => void;
} => {
  const { follow: initialFollow = true } = options;

  const ref = useRef<Element | null>(null);

  const observer = useRef<MutationObserver | null>(null);

  const [follow, setFollow] = useState<boolean>(initialFollow);

  const handleScroll = useCallback(
    <E extends Event>(event: E): void => {
      const { target } = event;

      if (
        !(
          target &&
          'clientHeight' in target &&
          'scrollTop' in target &&
          'scrollTopMax' in target
        )
      ) {
        return;
      }

      const { clientHeight, scrollTop, scrollTopMax } = target;

      const height = Number(clientHeight);
      const max = Number(scrollTopMax);
      const top = Number(scrollTop);

      const result = top >= max - height * 0.1;

      if (result !== follow) {
        setFollow(result);
      }
    },
    [follow],
  );

  const setScrollTop = useCallback(
    (value?: number): void => {
      if (!ref.current) {
        return;
      }

      const { scrollHeight, scrollTop } = ref.current;

      if (scrollTop === scrollHeight) {
        return;
      }

      let top = scrollHeight;

      if (value && value < scrollHeight) {
        top = value;
      }

      ref.current.removeEventListener('scroll', handleScroll);

      ref.current.scroll({ top });

      ref.current.addEventListener('scroll', handleScroll);
    },
    [handleScroll],
  );

  const handleMutations = useCallback<MutationCallback>(
    (mutations) => {
      mutations.forEach((mutation) => {
        const { type } = mutation;

        if (!['characterData', 'childList'].includes(type)) {
          return;
        }

        if (follow) {
          setScrollTop();
        }
      });
    },
    [follow, setScrollTop],
  );

  const callbackRef = useCallback(
    (element: Element | null) => {
      if (!element) {
        return;
      }

      ref.current = element;

      // The exact same instance of a listener will only be set once
      element.addEventListener('scroll', handleScroll);

      // Only create and set the observer once
      if (observer.current) {
        return;
      }

      observer.current = new MutationObserver(handleMutations);

      observer.current.observe(element, {
        characterData: true,
        childList: true,
        subtree: true,
      });
    },
    [handleMutations, handleScroll],
  );

  // Remember to set key={} on the scrollable element to prevent unnecessary
  // re-rendering
  useEffect(() => {
    const element = ref.current;

    // Try to clean up the listeners on unmount
    return () => {
      observer.current?.disconnect();

      element?.removeEventListener('scroll', handleScroll);
    };
  }, [handleScroll]);

  return {
    callbackRef,
    follow,
    ref,
    setFollow,
    setScrollTop,
  };
};

export default useScrollHelpers;
