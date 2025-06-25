import * as yup from 'yup';

import buildPeerStrikerTargetSchema from './buildPeerStrikerTargetSchema';

import {
  INPUT_ID_PEER_STRIKER_PASSWORD,
  INPUT_ID_PEER_STRIKER_PING_TEST,
  INPUT_ID_PEER_STRIKER_TARGET,
} from '../inputIds';

const buildPeerStrikerSchema = (peers: PeerConnectionList, hostUuid = '') =>
  yup.object({
    [INPUT_ID_PEER_STRIKER_PASSWORD]: yup.string(),
    [INPUT_ID_PEER_STRIKER_PING_TEST]: yup.boolean().default(true),
    [INPUT_ID_PEER_STRIKER_TARGET]: buildPeerStrikerTargetSchema(
      hostUuid,
      peers,
    ).required(),
  });

type PeerStrikerFormikValues = yup.InferType<
  ReturnType<typeof buildPeerStrikerSchema>
>;

export type { PeerStrikerFormikValues };

export default buildPeerStrikerSchema;
