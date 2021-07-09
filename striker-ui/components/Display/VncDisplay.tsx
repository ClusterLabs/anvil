import { useEffect, useRef, useState } from 'react';
import { RFB } from 'novnc-node';

type VncProps = {
  // The URL for the VNC connection: protocol, host, port, and path.
  url: string;

  // Define width and height via style or separate props
  style?: { width: number | string; height: number | string };
  width?: number | string;
  height?: number | string;

  // Force a URL to be communicated with as encrypted.
  encrypt?: boolean;

  // List of WebSocket protocols this connection should support.
  wsProtocols?: string[];

  // VNC connection changes.
  onUpdateState?: () => void;

  onPasswordRequired?: () => void;

  // Alert is raised on the VNC connection.
  onBell?: () => void;

  // The desktop name is entered for the connection.
  onDesktopName?: () => void;

  connectTimeout?: number;

  disconnectTimeout?: number;

  // A VNC connection should disconnect other connections before connecting.
  shared?: boolean;

  trueColor?: boolean;
  localCursor?: boolean;
};

const VncDisplay = (props: VncProps): JSX.Element => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [rfb, setRfb] = useState<typeof RFB>(undefined);
  const { style, url, encrypt, ...opts } = props;

  useEffect(() => {
    if (!rfb)
      setRfb(
        new RFB({
          ...opts,
          encrypt: encrypt !== null ? encrypt : url.startsWith('wss:'),
          target: canvasRef.current,
        }),
      );

    if (!rfb) return;

    if (!canvasRef.current) {
      /* eslint-disable consistent-return */
      return (): void => rfb.disconnect();
    }

    rfb.connect(url);

    return (): void => rfb.disconnect();
  }, [rfb, encrypt, opts, url]);

  const handleMouseEnter = () => {
    if (!rfb) return;
    // document.activeElement && document.activeElement.blur();
    rfb.get_keyboard().grab();
    rfb.get_mouse().grab();
  };

  const handleMouseLeave = () => {
    if (!rfb) return;

    rfb.get_keyboard().ungrab();
    rfb.get_mouse().ungrab();
  };

  return (
    <canvas
      style={style}
      ref={canvasRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    />
  );
};

VncDisplay.defaultProps = {
  style: null,
  encrypt: null,
  wsProtocols: ['binary'],
  trueColor: true,
  localCursor: true,
  connectTimeout: 5,
  disconnectTimeout: 5,
  width: 1280,
  height: 720,
  onUpdateState: null,
  onPasswordRequired: null,
  onBell: null,
  onDesktopName: null,
  shared: false,
};

export default VncDisplay;
