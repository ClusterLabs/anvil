import { useEffect, useRef, MutableRefObject, memo } from 'react';
import RFB from '@novnc/novnc/core/rfb';

type Props = {
  rfb: MutableRefObject<typeof RFB | undefined>;
  url: string;
  viewOnly: boolean;
  focusOnClick: boolean;
  clipViewport: boolean;
  dragViewport: boolean;
  scaleViewport: boolean;
  resizeSession: boolean;
  showDotCursor: boolean;
  background: string;
  qualityLevel: number;
  compressionLevel: number;
};

const VncDisplay = (props: Props): JSX.Element => {
  const screen = useRef<HTMLDivElement>(null);

  const {
    rfb,
    url,
    viewOnly,
    focusOnClick,
    clipViewport,
    dragViewport,
    scaleViewport,
    resizeSession,
    showDotCursor,
    background,
    qualityLevel,
    compressionLevel,
  } = props;

  useEffect(() => {
    if (!screen.current) {
      return (): void => {
        if (rfb.current) {
          rfb?.current.disconnect();
          rfb.current = undefined;
        }
      };
    }

    if (!rfb.current) {
      screen.current.innerHTML = '';

      rfb.current = new RFB(screen.current, url);

      rfb.current.viewOnly = viewOnly;
      rfb.current.focusOnClick = focusOnClick;
      rfb.current.clipViewport = clipViewport;
      rfb.current.dragViewport = dragViewport;
      rfb.current.resizeSession = resizeSession;
      rfb.current.scaleViewport = scaleViewport;
      rfb.current.showDotCursor = showDotCursor;
      rfb.current.background = background;
      rfb.current.qualityLevel = qualityLevel;
      rfb.current.compressionLevel = compressionLevel;
    }

    /* eslint-disable consistent-return */
    if (!rfb.current) return;

    return (): void => {
      if (rfb.current) {
        rfb.current.disconnect();
        rfb.current = undefined;
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rfb]);

  const handleMouseEnter = () => {
    if (
      document.activeElement &&
      document.activeElement instanceof HTMLElement
    ) {
      document.activeElement.blur();
    }

    if (rfb?.current) rfb.current.focus();
  };

  return (
    <div
      style={{ width: '100%', height: '75vh' }}
      ref={screen}
      onMouseEnter={handleMouseEnter}
    />
  );
};

export default memo(VncDisplay);
