import MuiGrid from '@mui/material/Grid2';
import { useContext, useMemo } from 'react';

import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import ManifestInputContext, {
  ManifestInputContextValue,
} from './ManifestInputContext';
import MessageBox from '../MessageBox';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SwitchWithLabel from '../SwitchWithLabel';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import { ManifestFormikValues } from './schemas/buildManifestSchema';

import {
  INPUT_ID_AH_FENCE_PORT,
  INPUT_ID_AH_IPMI_IP,
  INPUT_ID_AH_NETWORK_IP,
  INPUT_ID_AH_UPS_POWER_HOST,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
} from './inputIds';

const AnHostInputGroup: React.FC<AnHostInputGroupProps> = (props) => {
  const { hostSequence } = props;

  const context = useManifestFormContext(ManifestFormContext);

  const inputContext = useContext<ManifestInputContextValue | null>(
    ManifestInputContext,
  );

  const chains = useMemo(() => {
    const host = `hosts.${hostSequence}`;

    return {
      [INPUT_ID_AH_IPMI_IP]: `${host}.${INPUT_ID_AH_IPMI_IP}`,
      fences: `${host}.fences`,
      networks: `${host}.networks`,
      upses: `${host}.upses`,
    };
  }, [hostSequence]);

  if (!context || !inputContext) {
    return null;
  }

  const { fences: knownFences, upses: knownUpses } = inputContext.template;

  const { changeFieldValue, formik, handleChange } = context.formikUtils;

  const fences = Object.entries<
    ManifestFormikValues['hosts'][string]['fences'][string]
  >(formik.values.hosts[hostSequence].fences);

  const networks = Object.entries<
    ManifestFormikValues['hosts'][string]['networks'][string]
  >(formik.values.hosts[hostSequence].networks);

  const upses = Object.entries<
    ManifestFormikValues['hosts'][string]['upses'][string]
  >(formik.values.hosts[hostSequence].upses);

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <BodyText>Subnode {hostSequence}</BodyText>
      </InnerPanelHeader>
      <InnerPanelBody>
        <MuiGrid container spacing="1em" width="100%">
          <MuiGrid width="100%">
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
              <MuiGrid width="100%">
                <MessageBox>
                  It is recommended to provide at least 1 fence device plug.
                </MessageBox>
              </MuiGrid>
              {networks.map((entry) => {
                const [networkId, hostNetwork] = entry;

                const { [INPUT_ID_AH_NETWORK_IP]: ip } = hostNetwork;

                const inputId = `${chains.networks}.${networkId}.${INPUT_ID_AH_NETWORK_IP}`;

                const {
                  [INPUT_ID_AN_NETWORK_NUMBER]: sequence,
                  [INPUT_ID_AN_NETWORK_TYPE]: type = '',
                } = formik.values.netconf.networks[networkId];

                const inputLabel = `${type.toUpperCase()} ${sequence} IP`;

                return (
                  <MuiGrid
                    key={`host-${hostSequence}-network-${networkId}`}
                    size={1}
                  >
                    <UncontrolledInput
                      input={
                        <OutlinedInputWithLabel
                          id={inputId}
                          label={inputLabel}
                          name={inputId}
                          onChange={handleChange}
                          required
                          value={ip}
                        />
                      }
                    />
                  </MuiGrid>
                );
              })}
              <MuiGrid size={1}>
                <UncontrolledInput
                  input={
                    <OutlinedInputWithLabel
                      id={chains[INPUT_ID_AH_IPMI_IP]}
                      label="IPMI IP"
                      name={chains[INPUT_ID_AH_IPMI_IP]}
                      onChange={handleChange}
                      value={
                        formik.values.hosts[hostSequence][INPUT_ID_AH_IPMI_IP]
                      }
                    />
                  }
                />
              </MuiGrid>
              {fences.map((entry) => {
                const [fenceUuid, hostFence] = entry;

                const { [INPUT_ID_AH_FENCE_PORT]: plug } = hostFence;

                const inputId = `${chains.fences}.${fenceUuid}.${INPUT_ID_AH_FENCE_PORT}`;

                const { [fenceUuid]: fence } = knownFences;

                const inputLabel = `Plug on ${fence.fenceName}`;

                return (
                  <MuiGrid
                    key={`host-${hostSequence}-fence-${fenceUuid}`}
                    size={1}
                  >
                    <UncontrolledInput
                      input={
                        <OutlinedInputWithLabel
                          id={inputId}
                          label={inputLabel}
                          name={inputId}
                          onChange={handleChange}
                          value={plug}
                        />
                      }
                    />
                  </MuiGrid>
                );
              })}
            </MuiGrid>
          </MuiGrid>
          {upses.length && (
            <MuiGrid width="100%">
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
                {upses.map((entry) => {
                  const [upsUuid, hostUps] = entry;

                  const { [INPUT_ID_AH_UPS_POWER_HOST]: power } = hostUps;

                  const inputId = `${chains.upses}.${upsUuid}.${INPUT_ID_AH_UPS_POWER_HOST}`;

                  const { [upsUuid]: ups } = knownUpses;

                  const inputLabel = `Uses ${ups.upsName}`;

                  return (
                    <MuiGrid
                      key={`host-${hostSequence}-ups-${upsUuid}`}
                      size={1}
                    >
                      <SwitchWithLabel
                        checked={power}
                        id={inputId}
                        label={inputLabel}
                        name={inputId}
                        onChange={(event, checked) => {
                          changeFieldValue(inputId, checked, true);
                        }}
                      />
                    </MuiGrid>
                  );
                })}
              </MuiGrid>
            </MuiGrid>
          )}
        </MuiGrid>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default AnHostInputGroup;
