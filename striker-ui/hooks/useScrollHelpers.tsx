import React, { useCallback, useEffect, useRef, useState } from 'react';

const useScrollHelpers = <Element extends HTMLElement>(
  props: {
    follow?: boolean;
  } = {},
): {
  follow: boolean;
  ref: React.Ref<Element>;
  setFollow: React.Dispatch<React.SetStateAction<boolean>>;
  setScrollTop: (value?: number) => void;
} => {
  const { follow: initialFollow = true } = props;

  const ref = useRef<Element | null>(null);

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

  useEffect(() => {
    if (!ref.current) {
      return () => null;
    }

    const element = ref.current;

    element.addEventListener('scroll', handleScroll);

    const observer = new MutationObserver(handleMutations);

    observer.observe(element, {
      characterData: true,
      childList: true,
      subtree: true,
    });

    return () => {
      observer.disconnect();

      element.removeEventListener('scroll', handleScroll);
    };
  }, [handleMutations, handleScroll]);

  return {
    follow,
    ref,
    setFollow,
    setScrollTop,
  };
};

export default useScrollHelpers;
