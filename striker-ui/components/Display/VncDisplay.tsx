import RFB from '@novnc/novnc/core/rfb';
import { useEffect } from 'react';

const rfbConnect: RfbConnectFunction = ({
  background = '',
  clipViewport = false,
  compressionLevel = 2,
  dragViewport = false,
  focusOnClick = false,
  onConnect,
  onDisconnect,
  qualityLevel = 6,
  resizeSession = true,
  rfb,
  rfbScreen,
  scaleViewport = true,
  showDotCursor = false,
  url,
  viewOnly = false,
}) => {
  if (!rfbScreen?.current || rfb?.current) return;

  rfbScreen.current.innerHTML = '';

  rfb.current = new RFB(rfbScreen.current, url);

  rfb.current.background = background;
  rfb.current.clipViewport = clipViewport;
  rfb.current.compressionLevel = compressionLevel;
  rfb.current.dragViewport = dragViewport;
  rfb.current.focusOnClick = focusOnClick;
  rfb.current.qualityLevel = qualityLevel;
  rfb.current.resizeSession = resizeSession;
  rfb.current.scaleViewport = scaleViewport;
  rfb.current.showDotCursor = showDotCursor;
  rfb.current.viewOnly = viewOnly;

  // RFB extends custom class EventTargetMixin;
  // the usual .on or .once doesn't exist.

  if (onConnect) {
    rfb.current.addEventListener('connect', onConnect);
  }

  if (onDisconnect) {
    rfb.current.addEventListener('disconnect', onDisconnect);
  }
};

const rfbDisconnect: RfbDisconnectFunction = (rfb) => {
  if (!rfb?.current) return;

  rfb.current.disconnect();
  rfb.current = null;
};

const VncDisplay = (props: VncDisplayProps): JSX.Element => {
  const { rfb, rfbConnectPartialArgs, rfbScreen } = props;

  useEffect(() => {
    if (rfbConnectPartialArgs) {
      rfbConnect({ rfb, rfbScreen, ...rfbConnectPartialArgs });
    } else {
      rfbDisconnect(rfb);
    }
  }, [rfb, rfbConnectPartialArgs, rfbScreen]);

  useEffect(
    () => () => {
      rfbDisconnect(rfb);
    },
    [rfb],
  );

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
      ref={rfbScreen}
      onMouseEnter={handleMouseEnter}
    />
  );
};

VncDisplay.displayName = 'VncDisplay';

export default VncDisplay;
