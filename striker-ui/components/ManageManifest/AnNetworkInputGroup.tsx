import MuiGrid from '@mui/material/Grid2';
import { useContext, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import IconButton from '../IconButton';
import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import ManifestInputContext, {
  ManifestInputContextValue,
} from './ManifestInputContext';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import UncontrolledInput from '../UncontrolledInput';
import guessManifestNetworks from './guessManifestNetworks';
import deleteNetwork from './deleteNetwork';

import {
  INPUT_ID_AN_GATEWAY,
  INPUT_ID_AN_MIN_IP,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_AN_SUBNET_MASK,
} from './inputIds';

const networkTypeOptions = ['bcn', 'ifn', 'mn', 'sn'].map((type) => ({
  displayValue: NETWORK_TYPES[type] ?? 'Unknown network',
  value: type,
}));

const netSeqInputWidth = '4em';

const AnNetworkInputGroup: React.FC<AnNetworkInputGroupProps> = (props) => {
  const { networkId, showGateway } = props;

  const context = useManifestFormContext(ManifestFormContext);

  const inputContext = useContext<ManifestInputContextValue | null>(
    ManifestInputContext,
  );

  const chains = useMemo(() => {
    const networks = `netconf.networks`;

    const network = `${networks}.${networkId}`;

    return {
      [INPUT_ID_AN_GATEWAY]: `${network}.${INPUT_ID_AN_GATEWAY}`,
      [INPUT_ID_AN_MIN_IP]: `${network}.${INPUT_ID_AN_MIN_IP}`,
      [INPUT_ID_AN_NETWORK_NUMBER]: `${network}.${INPUT_ID_AN_NETWORK_NUMBER}`,
      [INPUT_ID_AN_NETWORK_TYPE]: `${network}.${INPUT_ID_AN_NETWORK_TYPE}`,
      [INPUT_ID_AN_SUBNET_MASK]: `${network}.${INPUT_ID_AN_SUBNET_MASK}`,
    };
  }, [networkId]);

  if (!context || !inputContext) {
    return null;
  }

  const {
    changeFieldValue,
    formik,
    getFieldChanged,
    handleChange,
    setValuesKai,
  } = context.formikUtils;

  const { hosts } = inputContext;

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <MuiGrid container spacing="0.1em" width="100%">
          <MuiGrid
            width={{
              xs: '100%',
              sm: `calc(100% - ${netSeqInputWidth})`,
            }}
          >
            <SelectWithLabel
              id={chains[INPUT_ID_AN_NETWORK_TYPE]}
              name={chains[INPUT_ID_AN_NETWORK_TYPE]}
              onChange={(event) => {
                const { value } = event.target;

                setValuesKai({
                  event: event as unknown as React.ChangeEvent<{
                    name: string;
                  }>,
                  values: (previous) => {
                    const shallow = { ...previous };

                    shallow.netconf.networks[networkId] = {
                      ...shallow.netconf.networks[networkId],
                      [INPUT_ID_AN_NETWORK_TYPE]: value,
                    };

                    return guessManifestNetworks({
                      getFieldChanged,
                      hosts,
                      values: shallow,
                    });
                  },
                });

                changeFieldValue(chains[INPUT_ID_AN_NETWORK_TYPE], value, true);
              }}
              required
              selectItems={networkTypeOptions}
              selectProps={{
                renderValue: (value) => `${NETWORK_TYPES[value]}`,
              }}
              value={
                formik.values.netconf.networks[networkId][
                  INPUT_ID_AN_NETWORK_TYPE
                ]
              }
            />
          </MuiGrid>
          <MuiGrid
            size="grow"
            width={{
              xs: '100%',
              sm: netSeqInputWidth,
            }}
          >
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains[INPUT_ID_AN_NETWORK_NUMBER]}
                  label="#"
                  name={chains[INPUT_ID_AN_NETWORK_NUMBER]}
                  onChange={(event) => {
                    const { value } = event.target;

                    setValuesKai({
                      debounce: true,
                      event,
                      values: (previous) => {
                        const shallow = { ...previous };

                        shallow.netconf.networks[networkId] = {
                          ...shallow.netconf.networks[networkId],
                          [INPUT_ID_AN_NETWORK_NUMBER]: Number(value),
                        };

                        return guessManifestNetworks({
                          getFieldChanged,
                          hosts,
                          values: shallow,
                        });
                      },
                    });
                  }}
                  required
                  value={
                    formik.values.netconf.networks[networkId][
                      INPUT_ID_AN_NETWORK_NUMBER
                    ]
                  }
                />
              }
            />
          </MuiGrid>
        </MuiGrid>
        <IconButton
          mapPreset="delete"
          onClick={() => {
            formik.setValues(deleteNetwork(formik.values, networkId), true);
          }}
          sx={{
            padding: '.2em',
            position: 'absolute',
            right: '-.5em',
            top: '-.2em',
          }}
        />
      </InnerPanelHeader>
      <InnerPanelBody>
        <MuiGrid
          columns={{
            xs: 1,
            sm: 2,
            md: 3,
          }}
          container
          spacing="1em"
          width="100%"
        >
          <MuiGrid size={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains[INPUT_ID_AN_MIN_IP]}
                  label="IP address"
                  name={chains[INPUT_ID_AN_MIN_IP]}
                  onChange={handleChange}
                  required
                  value={
                    formik.values.netconf.networks[networkId][
                      INPUT_ID_AN_MIN_IP
                    ]
                  }
                />
              }
            />
          </MuiGrid>
          <MuiGrid size={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains[INPUT_ID_AN_SUBNET_MASK]}
                  label="Subnet mask"
                  name={chains[INPUT_ID_AN_SUBNET_MASK]}
                  onChange={handleChange}
                  required
                  value={
                    formik.values.netconf.networks[networkId][
                      INPUT_ID_AN_SUBNET_MASK
                    ]
                  }
                />
              }
            />
          </MuiGrid>
          {showGateway && (
            <MuiGrid size={1}>
              <UncontrolledInput
                input={
                  <OutlinedInputWithLabel
                    id={chains[INPUT_ID_AN_GATEWAY]}
                    label="Gateway"
                    name={chains[INPUT_ID_AN_GATEWAY]}
                    onChange={handleChange}
                    value={
                      formik.values.netconf.networks[networkId][
                        INPUT_ID_AN_GATEWAY
                      ]
                    }
                  />
                }
              />
            </MuiGrid>
          )}
        </MuiGrid>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default AnNetworkInputGroup;
