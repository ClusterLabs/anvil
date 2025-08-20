import MuiBox from '@mui/material/Box';

import { BodyText } from '../Text';
import { ago, now } from '../../lib/time';

type ServerIpProps<Server extends ServerMinimum> = {
  ip: Server['ip'];
};

const ServerIp = <T extends ServerMinimum>(
  ...[props]: Parameters<React.FC<ServerIpProps<T>>>
): ReturnType<React.FC<ServerIpProps<T>>> => {
  const { ip } = props;

  const nao = now();

  return (
    <MuiBox>
      {ip.address ? (
        <>
          <BodyText inheritColour noWrap>
            {ip.address}
          </BodyText>
          <BodyText inheritColour noWrap variant="caption">
            Changed {ago(nao - ip.timestamp)} ago
          </BodyText>
        </>
      ) : (
        <BodyText inheritColour noWrap>
          IP: not found yet
        </BodyText>
      )}
    </MuiBox>
  );
};

export default ServerIp;
