import { useEffect, useRef, memo } from 'react';
import { RFB } from 'novnc-node';

type VncProps = {
  rfb: typeof RFB;
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

const VncDisplay = ({
  rfb,
  style,
  url,
  encrypt,
  ...opts
}: VncProps): JSX.Element => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  /* eslint-disable no-param-reassign */
  useEffect(() => {
    if (!rfb.current)
      rfb.current = new RFB({
        ...opts,
        style,
        encrypt: encrypt !== null ? encrypt : url.startsWith('wss:'),
        target: canvasRef.current,
      });

    if (!rfb.current) return;

    if (!canvasRef.current) {
      /* eslint-disable consistent-return */
      return (): void => {
        rfb.current.disconnect();
        rfb.current = undefined;
      };
    }

    rfb.current.connect(url);

    return (): void => {
      rfb.current.disconnect();
      rfb.current = undefined;
    };
  }, [rfb, encrypt, opts, url, style]);

  const handleMouseEnter = () => {
    if (!rfb.current) return;
    if (document.activeElement) (document.activeElement as HTMLElement).blur();
    rfb.current.get_keyboard().grab();
    rfb.current.get_mouse().grab();
  };

  const handleMouseLeave = () => {
    if (!rfb.current) return;

    rfb.current.get_keyboard().ungrab();
    rfb.current.get_mouse().ungrab();
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

const MemoVncDisplay = memo(VncDisplay);

export default MemoVncDisplay;
