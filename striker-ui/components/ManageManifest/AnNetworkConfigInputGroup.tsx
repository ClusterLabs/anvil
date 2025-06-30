import MuiGrid from '@mui/material/Grid2';
import { useMemo } from 'react';

import AnNetworkInputGroup from './AnNetworkInputGroup';
import IconButton from '../IconButton';
import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import addNetwork from './addNetwork';

import {
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_ANC_DNS,
  INPUT_ID_ANC_NTP,
} from './inputIds';

const AnNetworkConfigInputGroup: React.FC<AnNetworkConfigInputGroupProps> = (
  props,
) => {
  const { slotProps } = props;

  const context = useManifestFormContext(ManifestFormContext);

  const chains = useMemo(() => {
    const netconf = `netconf`;

    const networks = `${netconf}.networks`;

    return {
      [INPUT_ID_ANC_DNS]: `${netconf}.${INPUT_ID_ANC_DNS}`,
      [INPUT_ID_ANC_NTP]: `${netconf}.${INPUT_ID_ANC_NTP}`,
      netconf,
      networks,
    };
  }, []);

  if (!context) {
    return null;
  }

  const { formik, handleChange } = context.formikUtils;

  const networkEntries = Object.entries(formik.values.netconf.networks);

  return (
    <MuiGrid
      columns={{
        xs: 1,
        sm: 2,
        md: 3,
      }}
      container
      spacing="1em"
      width="100%"
      {...slotProps?.container}
    >
      {networkEntries.map((network) => {
        const [id, value] = network;

        return (
          <MuiGrid key={`netconf-network-${id}`} size="grow" width="100%">
            <AnNetworkInputGroup
              networkId={id}
              showGateway={value[INPUT_ID_AN_NETWORK_TYPE] === 'ifn'}
            />
          </MuiGrid>
        );
      })}
      <MuiGrid display="flex" justifyContent="center" width="100%">
        <IconButton
          mapPreset="add"
          onClick={() => {
            formik.setValues(addNetwork(formik.values), true);
          }}
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains[INPUT_ID_ANC_DNS]}
              label="DNS"
              name={chains[INPUT_ID_ANC_DNS]}
              onChange={handleChange}
              value={formik.values.netconf[INPUT_ID_ANC_DNS]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={chains[INPUT_ID_ANC_NTP]}
              label="NTP"
              name={chains[INPUT_ID_ANC_NTP]}
              onChange={handleChange}
              value={formik.values.netconf[INPUT_ID_ANC_NTP]}
            />
          }
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export default AnNetworkConfigInputGroup;
