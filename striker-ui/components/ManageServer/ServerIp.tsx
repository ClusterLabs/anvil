import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';

import { BodyText, BodyTextProps } from '../Text';
import { ago, now } from '../../lib/time';

type ServerIpProps<Server extends ServerMinimum> = {
  ip: Server['ip'];
  slotProps?: {
    box?: MuiBoxProps;
    text?: BodyTextProps;
  };
};

const ServerIp = <T extends ServerMinimum>(
  ...[props]: Parameters<React.FC<ServerIpProps<T>>>
): ReturnType<React.FC<ServerIpProps<T>>> => {
  const { ip, slotProps } = props;

  const nao = now();

  return (
    <MuiBox {...slotProps?.box}>
      {ip.address ? (
        <>
          <BodyText noWrap {...slotProps?.text}>
            {ip.address}
          </BodyText>
          <BodyText noWrap variant="caption" {...slotProps?.text}>
            Changed {ago(Math.round(nao - ip.timestamp))} ago
          </BodyText>
        </>
      ) : (
        <BodyText noWrap {...slotProps?.text}>
          IP: not found yet
        </BodyText>
      )}
    </MuiBox>
  );
};

export default ServerIp;
