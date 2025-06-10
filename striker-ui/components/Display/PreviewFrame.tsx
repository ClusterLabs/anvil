import { BoxProps as MuiBoxProps } from '@mui/material';

import { ServerMenu } from '../ManageServer';
import { InnerPanel, InnerPanelHeader } from '../Panels';
import { BodyText } from '../Text';

type PreviewFrameProps<Server extends APIServerOverview> = {
  getHeader?: (server: Server) => React.ReactNode;
  server: Server;
  showControls?: boolean;
  slotProps?: {
    header?: Partial<MuiBoxProps>;
    panel?: Partial<InnerPanelProps>;
  };
};

const PreviewFrame = <Server extends APIServerOverview>(
  ...[props]: Parameters<
    React.FC<React.PropsWithChildren<PreviewFrameProps<Server>>>
  >
): ReturnType<React.FC<PreviewFrameProps<Server>>> => {
  const {
    children,
    getHeader = ({ name }) => <BodyText>{name}</BodyText>,
    server,
    showControls = true,
    slotProps,
  } = props;

  return (
    <InnerPanel mb={0} mt={0} {...slotProps?.panel}>
      <InnerPanelHeader {...slotProps?.header}>
        {getHeader(server)}
        {showControls && (
          <ServerMenu
            node={server.anvil}
            server={server}
            slotProps={{
              button: {
                slotProps: {
                  button: {
                    icon: {
                      size: 'small',
                    },
                  },
                },
              },
            }}
          />
        )}
      </InnerPanelHeader>
      {children}
    </InnerPanel>
  );
};

export default PreviewFrame;
