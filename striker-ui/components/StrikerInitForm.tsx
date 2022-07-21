import { Dispatch, FC, SetStateAction, useState } from 'react';
import { Box as MUIBox } from '@mui/material';

import FlexBox from './FlexBox';
import NetworkInitForm from './NetworkInitForm';
import { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import { Panel, PanelHeader } from './Panels';
import { HeaderText } from './Text';

const MAX_ORGANIZATION_PREFIX_LENGTH = 5;
const MIN_ORGANIZATION_PREFIX_LENGTH = 2;
const MAX_HOST_NUMBER_LENGTH = 2;

const MAP_TO_ORGANIZATION_PREFIX_BUILDER: Record<
  number,
  (words: string[]) => string
> = {
  0: () => '',
  1: ([word]) =>
    word.substring(0, MIN_ORGANIZATION_PREFIX_LENGTH).toLocaleLowerCase(),
  2: (words) =>
    words.map((word) => word.substring(0, 1).toLocaleLowerCase()).join(''),
};

export type MapToType = {
  number: number;
  string: string;
};

export type MapToStateSetter = {
  [TypeName in keyof MapToType]: Dispatch<SetStateAction<MapToType[TypeName]>>;
};

export type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};

export type InputOnChangeParameters = Parameters<
  Exclude<OutlinedInputProps['onChange'], undefined>
>;

const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
};

const createInputOnChangeHandler =
  <TypeName extends keyof MapToType>({
    postSet,
    preSet,
    set,
    setType = 'string',
  }: {
    postSet?: (...args: InputOnChangeParameters) => void;
    preSet?: (...args: InputOnChangeParameters) => void;
    set?: MapToStateSetter[TypeName];
    setType?: TypeName | 'string';
  }): OutlinedInputProps['onChange'] =>
  (event) => {
    const {
      target: { value },
    } = event;
    const postConvertValue = MAP_TO_VALUE_CONVERTER[setType](
      value,
    ) as MapToType[TypeName];

    preSet?.call(null, event);
    set?.call(null, postConvertValue);
    postSet?.call(null, event);
  };

const buildOrganizationPrefix = (organizationName: string) => {
  const words: string[] = organizationName
    .split(/\s/)
    .filter((word) => !/and|of/.test(word))
    .slice(0, MAX_ORGANIZATION_PREFIX_LENGTH);

  const builderKey: number = words.length > 1 ? 2 : words.length;

  return MAP_TO_ORGANIZATION_PREFIX_BUILDER[builderKey](words);
};

const buildHostName = (
  organizationPrefix: string,
  hostNumber: number,
  domainName: string,
) =>
  organizationPrefix.length > 0 && hostNumber > 0 && domainName.length > 0
    ? `${organizationPrefix}-striker${pad(hostNumber)}.${domainName}`
    : '';

const StrikerInitGeneralForm: FC = () => {
  const [organizationNameInput, setOrganizationNameInput] =
    useState<string>('');
  const [organizationPrefixInput, setOrganizationPrefixInput] =
    useState<string>('');
  const [
    isOrganizationPrefixInputUserChanged,
    setIsOrganizationPrefixInputUserChanged,
  ] = useState<boolean>(false);
  const [domainNameInput, setDomainNameInput] = useState<string>('');
  const [hostNumberInput, setHostNumberInput] = useState<number>(0);
  const [hostNameInput, setHostNameInput] = useState<string>('');
  const [isHostNameInputUserChanged, setIsHostNameInputUserChanged] =
    useState<boolean>(false);

  const handleOrganizationNameInputOnChange = createInputOnChangeHandler({
    set: setOrganizationNameInput,
  });
  const handleOrganizationPrefixInputOnChange = createInputOnChangeHandler({
    postSet: () => {
      setIsOrganizationPrefixInputUserChanged(true);
    },
    set: setOrganizationPrefixInput,
  });
  const handleDomainNameInputOnChange = createInputOnChangeHandler({
    set: setDomainNameInput,
  });
  const handleHostNumberInputOnChange = createInputOnChangeHandler({
    set: setHostNumberInput,
    setType: 'number',
  });
  const handleHostNameInputOnChange = createInputOnChangeHandler({
    postSet: () => {
      setIsHostNameInputUserChanged(true);
    },
    set: setHostNameInput,
  });
  const populateOrganizationPrefixInput = () => {
    setOrganizationPrefixInput(buildOrganizationPrefix(organizationNameInput));
  };
  const populateHostNameInput = () => {
    setHostNameInput(
      buildHostName(organizationPrefixInput, hostNumberInput, domainNameInput),
    );
  };
  const createPopulateOnBlurHandler =
    (
      {
        condition = true,
        toPopulate = '',
      }: { condition?: boolean; toPopulate?: string },
      populate: (...args: unknown[]) => void,
      ...populateArgs: Parameters<typeof populate>
    ) =>
    () => {
      if (condition && toPopulate.length === 0) {
        populate(...populateArgs);
      }
    };
  const populateOrganizationPrefixInputOnBlur = createPopulateOnBlurHandler(
    { condition: !isOrganizationPrefixInputUserChanged },
    populateOrganizationPrefixInput,
  );
  const populateHostNameInputOnBlur = createPopulateOnBlurHandler(
    { condition: !isHostNameInputUserChanged },
    populateHostNameInput,
  );

  return (
    <MUIBox
      sx={{
        display: 'flex',
        flexDirection: { xs: 'column', sm: 'row' },

        '& > *': {
          flexBasis: '50%',
        },

        '& > :not(:first-child)': {
          marginLeft: { xs: 0, sm: '1em' },
          marginTop: { xs: '1em', sm: 0 },
        },
      }}
    >
      <FlexBox>
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: 'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
          }}
          id="striker-init-general-organization-name"
          inputProps={{
            onBlur: populateOrganizationPrefixInputOnBlur,
          }}
          label="Organization name"
          onChange={handleOrganizationNameInputOnChange}
          value={organizationNameInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
          }}
          id="striker-init-general-organization-prefix"
          inputProps={{
            inputProps: { maxLength: MAX_ORGANIZATION_PREFIX_LENGTH },
            onBlur: populateHostNameInputOnBlur,
            sx: {
              width: '8em',
            },
          }}
          label="Prefix"
          onChange={handleOrganizationPrefixInputOnChange}
          value={organizationPrefixInput}
        />
      </FlexBox>
      <FlexBox>
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Domain name for this striker. It's also the default domain used when creating new install manifests.",
          }}
          id="striker-init-general-domain-name"
          inputProps={{
            onBlur: populateHostNameInputOnBlur,
            sx: {
              minWidth: { sm: '16em' },
              width: { xs: '100%', sm: '50%' },
            },
          }}
          label="Domain name"
          onChange={handleDomainNameInputOnChange}
          value={domainNameInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such.",
          }}
          id="striker-init-general-host-number"
          inputProps={{
            inputProps: { maxLength: MAX_HOST_NUMBER_LENGTH },
            onBlur: populateHostNameInputOnBlur,
            sx: {
              width: '5em',
            },
          }}
          label="Host #"
          onChange={handleHostNumberInputOnChange}
          value={hostNumberInput}
        />
        <OutlinedInputWithLabel
          helpMessageBoxProps={{
            text: "Host name for this striker. It's usually a good idea to use the auto-generated value.",
          }}
          id="striker-init-general-host-name"
          label="Host name"
          onChange={handleHostNameInputOnChange}
          value={hostNameInput}
        />
      </FlexBox>
    </MUIBox>
  );
};

const StrikerInitForm: FC = () => (
  <Panel>
    <PanelHeader>
      <HeaderText text="Initialize striker" />
    </PanelHeader>
    <FlexBox>
      <StrikerInitGeneralForm />
      <NetworkInitForm />
    </FlexBox>
  </Panel>
);

export default StrikerInitForm;
