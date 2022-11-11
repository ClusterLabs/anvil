import {
  Box as MUIBox,
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel as MUIFormLabel,
  Grid,
  Radio as MUIRadio,
  radioClasses as muiRadioClasses,
  RadioGroup,
  styled,
  SxProps,
  Theme,
} from '@mui/material';
import Head from 'next/head';
import { FC, useMemo, useRef, useState } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import FlexBox from '../../components/FlexBox';
import Header from '../../components/Header';
import { Panel, PanelHeader } from '../../components/Panels';
import { BodyText, HeaderText } from '../../components/Text';
import OutlinedInputWithLabel from '../../components/OutlinedInputWithLabel';
import ContainedButton from '../../components/ContainedButton';
import InputWithRef, {
  InputForwardedRefContent,
} from '../../components/InputWithRef';
import Spinner from '../../components/Spinner';
import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';
import mainAxiosInstance from '../../lib/singletons/mainAxiosInstance';

const INPUT_PARENT_SX: SxProps<Theme> = {
  '& > *': { flexBasis: { xs: '50%' } },
};

const Radio = styled(MUIRadio)({
  [`&.${muiRadioClasses.root}`]: {
    color: GREY,
  },
});

const PrepareHost: FC = () => {
  const inputEnterpriseKeyRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputHostIPAddressRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputHostNameRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputHostPasswordRef = useRef<InputForwardedRefContent<'string'>>({});
  const inputRedhatPassword = useRef<InputForwardedRefContent<'string'>>({});
  const inputRedhatUser = useRef<InputForwardedRefContent<'string'>>({});

  const [isShowAccessSection, setIsShowAccessSection] =
    useState<boolean>(false);
  const [isShowOptionalSection, setIsShowOptionalSection] =
    useState<boolean>(false);
  const [isShowRedhatSection, setIsShowRedhatSection] =
    useState<boolean>(false);
  const [isTestAccessInProgress, setIsTestAccessInProgress] =
    useState<boolean>(false);

  const testAccessElement = useMemo(
    () =>
      isShowOptionalSection ? (
        <></>
      ) : (
        <FlexBox row sx={{ justifyContent: 'flex-end' }}>
          <ContainedButton
            onClick={() => {
              setIsTestAccessInProgress(true);

              mainAxiosInstance
                .put<
                  { status: number },
                  {
                    hostName: string;
                    hostOS: string;
                    hostUUID: string;
                    isConnected: boolean;
                    isInetConnected: boolean;
                    isOSRegistered: boolean;
                  },
                  { ipAddress?: string; password?: string }
                >('/command/inquire', {
                  ipAddress: inputHostIPAddressRef.current.getValue?.call(null),
                  password: inputHostPasswordRef.current.getValue?.call(null),
                })
                .then(
                  ({ hostName, hostOS, isInetConnected, isOSRegistered }) => {
                    inputHostNameRef.current.setValue?.call(null, hostName);

                    if (
                      isInetConnected &&
                      /rhel/i.test(hostOS) &&
                      !isOSRegistered
                    ) {
                      setIsShowRedhatSection(true);
                    }

                    setIsShowOptionalSection(true);
                  },
                )
                .catch((error) => {
                  const { request, response, message, config } = error;
                })
                .finally(() => {
                  setIsTestAccessInProgress(false);
                });
            }}
          >
            Test access
          </ContainedButton>
        </FlexBox>
      ),
    [isShowOptionalSection],
  );

  return (
    <>
      <Head>
        <title>Prepare Host</title>
      </Head>
      <Header />
      <Grid container columns={{ xs: 1, sm: 6, md: 4 }}>
        <Grid item sm={1} xs={0} />
        <Grid item md={2} sm={4} xs={1}>
          <Panel>
            <PanelHeader>
              <HeaderText>Prepare a host to include in Anvil!</HeaderText>
            </PanelHeader>
            <FlexBox>
              {/* Build radio group with label */}
              <FormControl>
                <MUIFormLabel>
                  <BodyText>Host type</BodyText>
                </MUIFormLabel>
                <RadioGroup
                  onChange={() => {
                    setIsShowAccessSection(true);
                  }}
                  row
                >
                  <FormControlLabel
                    control={<Radio />}
                    value="node"
                    label={<BodyText>Node</BodyText>}
                  />
                  <FormControlLabel
                    control={<Radio />}
                    value="drhost"
                    label={<BodyText>Disaster Recovery (DR) host</BodyText>}
                  />
                </RadioGroup>
              </FormControl>
              {isShowAccessSection && (
                <FlexBox>
                  <FlexBox sm="row" spacing="1em" sx={INPUT_PARENT_SX}>
                    <InputWithRef
                      input={<OutlinedInputWithLabel label="Host IP address" />}
                      ref={inputHostIPAddressRef}
                    />
                    <InputWithRef
                      input={
                        <OutlinedInputWithLabel
                          inputProps={{ type: INPUT_TYPES.password }}
                          label="Host root password"
                        />
                      }
                      ref={inputHostPasswordRef}
                    />
                  </FlexBox>
                  {isTestAccessInProgress ? <Spinner /> : testAccessElement}
                </FlexBox>
              )}
              {isShowOptionalSection && (
                <FlexBox>
                  <FlexBox sm="row" sx={INPUT_PARENT_SX}>
                    <InputWithRef
                      input={<OutlinedInputWithLabel label="Host name" />}
                      ref={inputHostNameRef}
                    />
                    <InputWithRef
                      input={
                        <OutlinedInputWithLabel label="Alteeve enterprise key" />
                      }
                      ref={inputEnterpriseKeyRef}
                    />
                  </FlexBox>
                  {isShowRedhatSection && (
                    <FlexBox sm="row" sx={INPUT_PARENT_SX}>
                      <InputWithRef
                        input={
                          <OutlinedInputWithLabel label="RedHat username" />
                        }
                        ref={inputRedhatUser}
                      />
                      <InputWithRef
                        input={
                          <OutlinedInputWithLabel
                            inputProps={{ type: INPUT_TYPES.password }}
                            label="RedHat password"
                          />
                        }
                        ref={inputRedhatPassword}
                      />
                    </FlexBox>
                  )}
                  <FlexBox row sx={{ justifyContent: 'flex-end' }}>
                    <ContainedButton>Prepare host</ContainedButton>
                  </FlexBox>
                </FlexBox>
              )}
            </FlexBox>
          </Panel>
        </Grid>
      </Grid>
    </>
  );
};

export default PrepareHost;
