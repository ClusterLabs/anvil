import { Grid } from '@mui/material';
import { FC, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import FlexBox from '../FlexBox';
import List from '../List';
import { ExpandablePanel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import State from '../State';
import { BodyText, MonoText, SmallText } from '../Text';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

type InboundConnections = {
  [ipAddress: string]: {
    dbPort: number;
    dbUser: string;
    ipAddress: string;
    networkLinkNumber: number;
    networkNumber: number;
    networkType: string;
  };
};

type PeerConnections = {
  [peer: string]: {
    dbPort: number;
    dbUser: string;
    ipAddress: string;
    isDelete?: boolean;
    isEdit?: boolean;
    isNew?: boolean;
    isPingTest?: boolean;
  };
};

const ConfigPeersForm: FC = () => {
  const { protect } = useProtect();

  const [inboundConnections, setInboundConnections] =
    useProtectedState<InboundConnections>({}, protect);
  const [peerConnections, setPeerConnections] =
    useProtectedState<PeerConnections>({}, protect);
  const [isEditPeerConnections, setIsEditPeerConnections] =
    useState<boolean>(false);

  const { isLoading } = periodicFetch<{
    local: {
      inbound: {
        ipAddress: {
          [ipAddress: string]: {
            hostUUID: string;
            ipAddress: string;
            ipAddressUUID: string;
            networkLinkNumber: number;
            networkNumber: number;
            networkType: string;
          };
        };
        port: number;
        user: string;
      };
      peer: {
        [ipAddress: string]: {
          hostUUID: string;
          ipAddress: string;
          isPing: boolean;
          port: number;
          user: string;
        };
      };
    };
  }>(`${API_BASE_URL}/host/connection`, {
    onSuccess: ({
      local: {
        inbound: { ipAddress: ipAddressList, port: dbPort, user: dbUser },
        peer,
      },
    }) => {
      setInboundConnections(
        Object.entries(ipAddressList).reduce<InboundConnections>(
          (
            previous,
            [ipAddress, { networkLinkNumber, networkNumber, networkType }],
          ) => {
            previous[ipAddress] = {
              dbPort,
              dbUser,
              ipAddress,
              networkLinkNumber,
              networkNumber,
              networkType,
            };

            return previous;
          },
          {},
        ),
      );

      setPeerConnections(
        Object.entries(peer).reduce<PeerConnections>(
          (
            previous,
            [
              peerIPAddress,
              { isPing: isPingTest, port: peerDBPort, user: peerDBUser },
            ],
          ) => {
            previous[`${peerDBUser}@${peerIPAddress}:${peerDBPort}`] = {
              dbPort: peerDBPort,
              dbUser: peerDBUser,
              ipAddress: peerIPAddress,
              isPingTest,
            };

            return previous;
          },
          {},
        ),
      );
    },
  });

  return (
    <ExpandablePanel
      header={<BodyText>Configure striker peers</BodyText>}
      loading={isLoading}
    >
      <Grid columns={{ xs: 1, sm: 2 }} container spacing="1em">
        <Grid item xs={1}>
          <List
            header="Inbound connections"
            listItemKeyPrefix="config-peers-inbound-connection"
            listItems={inboundConnections}
            renderListItem={(
              ipAddress,
              { dbPort, dbUser, networkNumber, networkType },
            ) => (
              <FlexBox spacing={0} sx={{ width: '100%' }}>
                <MonoText>{`${dbUser}@${ipAddress}:${dbPort}`}</MonoText>
                <SmallText>{`${NETWORK_TYPES[networkType]} ${networkNumber}`}</SmallText>
              </FlexBox>
            )}
          />
        </Grid>
        <Grid item xs={1}>
          <List
            header="Peer connections"
            allowEdit
            edit={isEditPeerConnections}
            listItemKeyPrefix="config-peers-peer-connection"
            listItems={peerConnections}
            onEdit={() => {
              setIsEditPeerConnections((previous) => !previous);
            }}
            renderListItem={(peer, { isPingTest = false }) => (
              <FlexBox row spacing={0}>
                <FlexBox spacing={0}>
                  <MonoText>{peer}</MonoText>
                  <State label="Ping" state={isPingTest} />
                </FlexBox>
              </FlexBox>
            )}
          />
        </Grid>
      </Grid>
    </ExpandablePanel>
  );
};

export default ConfigPeersForm;
