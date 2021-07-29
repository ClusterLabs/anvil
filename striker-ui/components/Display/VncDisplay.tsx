import { useEffect, useRef, MutableRefObject, memo } from 'react';
import RFB from './noVNC/core/rfb';

type Props = {
  rfb: MutableRefObject<RFB | undefined>;
  url: string;
  style: { width: string; height: string };
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
    style,
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

    if (rfb?.current) {
      rfb.current.focus();
    }
  };

  const handleMouseLeave = () => {
    if (rfb?.current) {
      rfb.current.blur();
    }
  };

  return (
    <div
      style={style}
      ref={screen}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    />
  );
};

export default memo(VncDisplay);
