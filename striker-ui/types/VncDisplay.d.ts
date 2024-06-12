type RfbRef = import('react').MutableRefObject<
  typeof import('@novnc/novnc/core/rfb') | null
>;

type RfbScreenRef = import('react').MutableRefObject<HTMLDivElement | null>;

type WebsockCloseEvent = Event & { code: number; reason: string };

type RfbConnectArgs = {
  background?: string;
  clipViewport?: boolean;
  compressionLevel?: number;
  dragViewport?: boolean;
  focusOnClick?: boolean;
  onConnect?: () => void;
  onDisconnect?: (event: { detail: { clean: boolean } }) => void;
  onWsClose?: (event?: WebsockCloseEvent) => void;
  onWsError?: (event: Event) => void;
  qualityLevel?: number;
  resizeSession?: boolean;
  rfb: RfbRef;
  rfbScreen: RfbScreenRef;
  scaleViewport?: boolean;
  showDotCursor?: boolean;
  url: string;
  viewOnly?: boolean;
};

type RfbConnectFunction = (args: RfbConnectArgs) => void;

type RfbDisconnectFunction = (rfb: RfbRef) => void;

type VncDisplayProps = Pick<RfbConnectArgs, 'rfb' | 'rfbScreen'> &
  Partial<RfbConnectArgs> & {
    rfbConnectArgs?: Partial<RfbConnectArgs>;
  };
