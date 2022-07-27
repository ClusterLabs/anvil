import { Box as MUIBox } from '@mui/material';
import { forwardRef, useImperativeHandle, useRef } from 'react';

import createFunction from '../lib/createFunction';
import FlexBox from './FlexBox';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import isEmpty from '../lib/isEmpty';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import SuggestButton from './SuggestButton';

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

const buildOrganizationPrefix = (organizationName = '') => {
  const words: string[] = organizationName
    .split(/\s/)
    .filter((word) => !/and|of/.test(word))
    .slice(0, MAX_ORGANIZATION_PREFIX_LENGTH);

  const builderKey: number = words.length > 1 ? 2 : words.length;

  return MAP_TO_ORGANIZATION_PREFIX_BUILDER[builderKey](words);
};

const buildHostName = ({
  organizationPrefix,
  hostNumber,
  domainName,
}: {
  organizationPrefix?: string;
  hostNumber?: number;
  domainName?: string;
}) =>
  isEmpty([organizationPrefix, hostNumber, domainName], { not: true })
    ? `${organizationPrefix}-striker${pad(hostNumber)}.${domainName}`
    : '';

const GeneralInitForm = forwardRef((generalInitFormProps, ref) => {
  const organizationNameInputRef = useRef<InputForwardedRefContent<'string'>>(
    {},
  );
  const organizationPrefixInputRef = useRef<InputForwardedRefContent<'string'>>(
    {},
  );
  const domainNameInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const hostNumberInputRef = useRef<InputForwardedRefContent<'number'>>({});
  const hostNameInputRef = useRef<InputForwardedRefContent<'string'>>({});

  const {
    current: { value: organizationNameInputValue },
  } = organizationNameInputRef;
  const {
    current: {
      isChangedByUser: isOrganizationPrefixInputChangedByUser,
      setValue: setOrganizationPrefixInputValue,
      value: organizationPrefixInputValue,
    },
  } = organizationPrefixInputRef;
  const {
    current: { value: domainNameInputValue },
  } = domainNameInputRef;
  const {
    current: { value: hostNumberInputValue },
  } = hostNumberInputRef;
  const {
    current: {
      isChangedByUser: isHostNameInputChangedByUser,
      setValue: setHostNameInputValue,
      value: hostNameInputValue,
    },
  } = hostNameInputRef;

  const populateOrganizationPrefixInput = ({
    organizationName = organizationNameInputValue,
  } = {}) => {
    const organizationPrefix = buildOrganizationPrefix(organizationName);

    setOrganizationPrefixInputValue?.call(null, organizationPrefix);

    return organizationPrefix;
  };
  const populateHostNameInput = ({
    organizationPrefix = organizationPrefixInputValue,
    hostNumber = hostNumberInputValue,
    domainName = domainNameInputValue,
  } = {}) => {
    const hostName = buildHostName({
      organizationPrefix,
      hostNumber,
      domainName,
    });

    setHostNameInputValue?.call(null, hostName);

    return hostName;
  };
  const populateOrganizationPrefixInputOnBlur = createFunction(
    { condition: !isOrganizationPrefixInputChangedByUser },
    populateOrganizationPrefixInput,
  );
  const populateHostNameInputOnBlur = createFunction(
    { condition: !isHostNameInputChangedByUser },
    populateHostNameInput,
  );
  const handleOrganizationPrefixSuggest = createFunction(
    {
      conditionFn: () =>
        isOrganizationPrefixInputChangedByUser === true &&
        isEmpty([organizationNameInputValue], { not: true }),
    },
    () => {
      const organizationPrefix = populateOrganizationPrefixInput();

      if (!isHostNameInputChangedByUser) {
        populateHostNameInput({ organizationPrefix });
      }
    },
  );
  const handlerHostNameSuggest = createFunction(
    {
      conditionFn: () =>
        isHostNameInputChangedByUser === true &&
        isEmpty(
          [
            organizationPrefixInputValue,
            hostNumberInputValue,
            domainNameInputValue,
          ],
          {
            not: true,
          },
        ),
    },
    populateHostNameInput,
  );

  useImperativeHandle(ref, () => ({
    organizationName: organizationNameInputValue,
    organizationPrefix: organizationPrefixInputValue,
    domainName: domainNameInputValue,
    hostNumber: hostNumberInputValue,
    hostName: hostNameInputValue,
  }));

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
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              helpMessageBoxProps={{
                text: 'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
              }}
              id="striker-init-general-organization-name"
              inputProps={{
                onBlur: populateOrganizationPrefixInputOnBlur,
              }}
              label="Organization name"
            />
          }
          ref={organizationNameInputRef}
        />
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              helpMessageBoxProps={{
                text: "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
              }}
              id="striker-init-general-organization-prefix"
              inputProps={{
                endAdornment: (
                  <SuggestButton onClick={handleOrganizationPrefixSuggest} />
                ),
                inputProps: {
                  maxLength: MAX_ORGANIZATION_PREFIX_LENGTH,
                  style: { width: '2.5em' },
                },
                onBlur: populateHostNameInputOnBlur,
                sx: {
                  minWidth: 'min-content',
                  width: 'fit-content',
                },
              }}
              label="Prefix"
            />
          }
          ref={organizationPrefixInputRef}
        />
      </FlexBox>
      <FlexBox>
        <InputWithRef
          input={
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
            />
          }
          ref={domainNameInputRef}
        />
        <InputWithRef
          input={
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
            />
          }
          ref={hostNumberInputRef}
          valueType="number"
        />
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              helpMessageBoxProps={{
                text: "Host name for this striker. It's usually a good idea to use the auto-generated value.",
              }}
              id="striker-init-general-host-name"
              inputProps={{
                endAdornment: (
                  <SuggestButton onClick={handlerHostNameSuggest} />
                ),
                inputProps: {
                  style: {
                    minWidth: '4em',
                  },
                },
                sx: {
                  minWidth: 'min-content',
                },
              }}
              label="Host name"
            />
          }
          ref={hostNameInputRef}
        />
      </FlexBox>
    </MUIBox>
  );
});

GeneralInitForm.displayName = 'GeneralInitForm';

export default GeneralInitForm;
