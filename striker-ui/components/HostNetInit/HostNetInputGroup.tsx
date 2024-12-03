import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import Autocomplete from '../Autocomplete';
import DropArea from '../DropArea';
import { deleteButtonOffset } from './HostNetBox';
import IconButton from '../IconButton';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';

const NETOPS: Record<string, string[]> = {
  dr: ['bcn', 'ifn', 'mn', 'sn'],
  striker: ['bcn', 'ifn'],
  subnode: ['bcn', 'ifn', 'sn'],
};

const netSeqInputWidth = '3.4em';

const HostNetInputGroup = <Values extends HostNetInitFormikExtension>(
  ...[props]: Parameters<FC<HostNetInputGroupProps<Values>>>
): ReturnType<FC<HostNetInputGroupProps<Values>>> => {
  const {
    appliedIfaces,
    formikUtils,
    host,
    ifaceHeld,
    ifaces,
    ifaceValues,
    netId,
  } = props;

  const { formik, handleChange, setFieldChanged } = formikUtils;

  const netTypeOptions = useMemo<SelectItem[]>(() => {
    let base: string[] = NETOPS[host.type];

    if (!base) return [];

    const nets = formik.values.networkInit.networks;

    if (
      host.type === 'subnode' &&
      ifaceValues.length >= 8 &&
      (nets[netId].type === 'mn' ||
        Object.values<HostNetFormikValues>(nets).every(
          (net) => net.type !== 'mn',
        ))
    ) {
      base = [...base, 'mn'].sort();
    }

    return base.map((type) => ({
      displayValue: NETWORK_TYPES[type] ?? 'Unknown network',
      value: type,
    }));
  }, [
    formik.values.networkInit.networks,
    host.type,
    ifaceValues.length,
    netId,
  ]);

  const chains = useMemo(() => {
    const ns = 'networkInit.networks';
    const n = `${ns}.${netId}`;

    return {
      ip: `${n}.ip`,
      link1: `${n}.interfaces.0`,
      link2: `${n}.interfaces.1`,
      networks: ns,
      sequence: `${n}.sequence`,
      subnetMask: `${n}.subnetMask`,
      type: `${n}.type`,
    };
  }, [netId]);

  return (
    <InnerPanel>
      <InnerPanelHeader>
        <Grid container spacing="0.1em">
          <Grid
            item
            width={{ xs: '100%', sm: `calc(100% - ${netSeqInputWidth})` }}
          >
            <SelectWithLabel
              id={chains.type}
              label="Network type"
              name={chains.type}
              onChange={formik.handleChange}
              required
              selectItems={netTypeOptions}
              value={formik.values.networkInit.networks[netId].type}
            />
          </Grid>
          <Grid item width={{ xs: '100%', sm: netSeqInputWidth }}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains.sequence}
                  label="#"
                  name={chains.sequence}
                  onChange={handleChange}
                  required
                  value={formik.values.networkInit.networks[netId].sequence}
                />
              }
            />
          </Grid>
        </Grid>
        {!formik.values.networkInit.networks[netId].required && (
          <IconButton
            mapPreset="delete"
            onClick={() => {
              const { [netId]: rm, ...keep } =
                formik.values.networkInit.networks;

              formik.setFieldValue(chains.networks, keep, true);
            }}
            sx={{
              padding: '.2em',
              position: 'absolute',
              right: `-${deleteButtonOffset}`,
              top: '-.2em',
            }}
          />
        )}
      </InnerPanelHeader>
      <InnerPanelBody>
        <Grid columns={1} container spacing="1em">
          <Grid item xs={1}>
            <DropArea
              onMouseUp={() => {
                if (!ifaceHeld) return;

                formik.setFieldValue(chains.link1, ifaceHeld, true);
              }}
            >
              <Autocomplete
                getOptionDisabled={(option) =>
                  appliedIfaces[option.uuid] &&
                  option.uuid !==
                    formik.values.networkInit.networks[netId].interfaces[0]
                }
                getOptionLabel={(option) => option.name}
                id={chains.link1}
                isOptionEqualToValue={(option, value) =>
                  option.uuid === value.uuid
                }
                label="Link 1"
                noOptionsText="No matching interface"
                onChange={(event, value) => {
                  formik.setFieldValue(
                    chains.link1,
                    value ? value.uuid : '',
                    true,
                  );
                }}
                openOnFocus
                options={ifaceValues}
                renderOption={(optionProps, option) => (
                  <li {...optionProps} key={`link1-ifop-${option.uuid}`}>
                    <BodyText inheritColour>{option.name}</BodyText>
                  </li>
                )}
                slotProps={{
                  clearIndicator: {
                    onClick: () => {
                      setFieldChanged(chains.link1, true);
                    },
                  },
                }}
                value={
                  ifaces[
                    formik.values.networkInit.networks[netId].interfaces[0]
                  ] ?? null
                }
              />
            </DropArea>
          </Grid>
          <Grid item xs={1}>
            <DropArea
              onMouseUp={() => {
                if (!ifaceHeld) return;

                formik.setFieldValue(chains.link2, ifaceHeld, true);
              }}
            >
              <Autocomplete
                getOptionDisabled={(option) =>
                  appliedIfaces[option.uuid] &&
                  option.uuid !==
                    formik.values.networkInit.networks[netId].interfaces[1]
                }
                getOptionLabel={(option) => option.name}
                id={chains.link2}
                isOptionEqualToValue={(option, value) =>
                  option.uuid === value.uuid
                }
                label="Link 2"
                noOptionsText="No matching interface"
                onChange={(event, value) => {
                  formik.setFieldValue(
                    chains.link2,
                    value ? value.uuid : '',
                    true,
                  );
                }}
                openOnFocus
                options={ifaceValues}
                renderOption={(optionProps, option) => (
                  <li {...optionProps} key={`link2-ifop-${option.uuid}`}>
                    <BodyText inheritColour>{option.name}</BodyText>
                  </li>
                )}
                slotProps={{
                  clearIndicator: {
                    onClick: () => {
                      setFieldChanged(chains.link2, true);
                    },
                  },
                }}
                value={
                  ifaces[
                    formik.values.networkInit.networks[netId].interfaces[1]
                  ] ?? null
                }
              />
            </DropArea>
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains.ip}
                  label="IP address"
                  name={chains.ip}
                  onChange={handleChange}
                  required
                  value={formik.values.networkInit.networks[netId].ip}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={chains.subnetMask}
                  label="Subnet mask"
                  name={chains.subnetMask}
                  onChange={handleChange}
                  required
                  value={formik.values.networkInit.networks[netId].subnetMask}
                />
              }
            />
          </Grid>
        </Grid>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default HostNetInputGroup;
