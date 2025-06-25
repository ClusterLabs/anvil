import { PeerStrikerFormikValues } from './schemas/buildPeerStrikerSchema';

import {
  INPUT_ID_PEER_STRIKER_PASSWORD,
  INPUT_ID_PEER_STRIKER_PING_TEST,
  INPUT_ID_PEER_STRIKER_TARGET,
} from './inputIds';

const getPeerStrikerFormikInitialValues = (
  peer?: PeerConnection,
): PeerStrikerFormikValues => ({
  [INPUT_ID_PEER_STRIKER_PASSWORD]: '',
  [INPUT_ID_PEER_STRIKER_PING_TEST]: peer?.isPingTest ?? true,
  [INPUT_ID_PEER_STRIKER_TARGET]: peer?.ipAddress ?? '',
});

export default getPeerStrikerFormikInitialValues;
