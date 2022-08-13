import { Grid as MUIGrid } from '@mui/material';
import {
  FC,
  forwardRef,
  ReactNode,
  useCallback,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';

import INPUT_TYPES from '../lib/consts/INPUT_TYPES';
import { REP_DOMAIN } from '../lib/consts/REG_EXP_PATTERNS';

import FlexBox, { FlexBoxProps } from './FlexBox';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import isEmpty from '../lib/isEmpty';
import MessageBox, { Message } from './MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import pad from '../lib/pad';
import SuggestButton from './SuggestButton';
import { createTestInputFunction, testNotBlank } from '../lib/test_input';
import { InputTestBatches, InputTestInputs } from '../types/TestInputFunction';
import { BodyText } from './Text';

type GeneralInitFormForwardRefContent = {
  get?: () => {
    adminPassword?: string;
    domainName?: string;
    hostName?: string;
    hostNumber?: number;
    organizationName?: string;
    organizationPrefix?: string;
  };
};

type OutlinedInputWithLabelOnBlur = Exclude<
  OutlinedInputWithLabelProps['inputProps'],
  undefined
>['onBlur'];

const MAX_ORGANIZATION_PREFIX_LENGTH = 5;
const MIN_ORGANIZATION_PREFIX_LENGTH = 1;
const MAX_HOST_NUMBER_LENGTH = 2;
const INPUT_COUNT = 7;
const INPUT_TEST_IDS = {
  adminPassword: 'adminPassword',
  confirmAdminPassword: 'confirmAdminPassword',
  domainName: 'domainName',
  hostName: 'hostName',
  hostNumber: 'hostNumber',
  organizationName: 'organizationName',
  organizationPrefix: 'organizationPrefix',
};

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

const ms = (text: ReactNode) => (
  <BodyText className="inline-monospace-text" monospaced text={text} />
);

const MessageChildren: FC<FlexBoxProps> = ({ ...flexBoxProps }) => (
  <FlexBox
    {...flexBoxProps}
    row
    spacing={0}
    sx={{
      '& > .inline-monospace-text': {
        marginTop: '-.2em',
      },
    }}
  />
);

const GeneralInitForm = forwardRef<
  GeneralInitFormForwardRefContent,
  { toggleSubmitDisabled?: ToggleSubmitDisabledFunction }
>(({ toggleSubmitDisabled }, ref) => {
  const [helpMessage, setHelpMessage] = useState<ReactNode | undefined>();
  const [isShowOrganizationPrefixSuggest, setIsShowOrganizationPrefixSuggest] =
    useState<boolean>(false);
  const [isShowHostNameSuggest, setIsShowHostNameSuggest] =
    useState<boolean>(false);
  const [isConfirmAdminPassword, setIsConfirmAdminPassword] =
    useState<boolean>(true);

  const adminPasswordInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const confirmAdminPasswordInputRef = useRef<
    InputForwardedRefContent<'string'>
  >({});
  const organizationNameInputRef = useRef<InputForwardedRefContent<'string'>>(
    {},
  );
  const organizationPrefixInputRef = useRef<InputForwardedRefContent<'string'>>(
    {},
  );
  const domainNameInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const hostNumberInputRef = useRef<InputForwardedRefContent<'number'>>({});
  const hostNameInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const setOrganizationPrefixInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 1, message),
    [],
  );
  const setHostNumberInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 2, message),
    [],
  );
  const setDomainNameInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 3, message),
    [],
  );
  const setHostNameInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 4, message),
    [],
  );
  const setAdminPasswordInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 5, message),
    [],
  );
  const setConfirmAdminPasswordInputMessage = useCallback(
    (message?: Message) =>
      messageGroupRef.current.setMessage?.call(null, 6, message),
    [],
  );

  const inputTests: InputTestBatches = useMemo(
    () => ({
      [INPUT_TEST_IDS.adminPassword]: {
        defaults: {
          getValue: () => adminPasswordInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setAdminPasswordInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setAdminPasswordInputMessage({
                children: (
                  <MessageChildren>
                    Admin password cannot contain single-quote ({ms("'")}),
                    double-quote ({ms('"')}), slash ({ms('/')}), backslash (
                    {ms('\\')}), angle brackets ({ms('<>')}), curly brackets (
                    {ms('{}')}).
                  </MessageChildren>
                ),
              });
            },
            test: ({ value }) => !/['"/\\><}{]/g.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.confirmAdminPassword]: {
        defaults: {
          getValue: () =>
            isConfirmAdminPassword
              ? confirmAdminPasswordInputRef.current.getValue?.call(null)
              : adminPasswordInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setConfirmAdminPasswordInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setConfirmAdminPasswordInputMessage({
                children: 'Admin password confirmation failed.',
              });
            },
            test: ({ value }) =>
              value === adminPasswordInputRef.current.getValue?.call(null),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.domainName]: {
        defaults: {
          getValue: () => domainNameInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setDomainNameInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setDomainNameInputMessage({
                children: (
                  <MessageChildren>
                    Domain name can only contain lowercase alphanumeric, hyphen
                    ({ms('-')}), and dot ({ms('.')}) characters.
                  </MessageChildren>
                ),
              });
            },
            test: ({ value }) => REP_DOMAIN.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.hostName]: {
        defaults: {
          getValue: () => hostNameInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setHostNameInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setHostNameInputMessage({
                children: (
                  <MessageChildren>
                    Host name can only contain lowercase alphanumeric, hyphen (
                    {ms('-')}), and dot ({ms('.')}) characters.
                  </MessageChildren>
                ),
              });
            },
            test: ({ value }) => REP_DOMAIN.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.hostNumber]: {
        defaults: {
          getValue: () => hostNumberInputRef.current.getValue?.call(null),
          onSuccess: () => {
            setHostNumberInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: () => {
              setHostNumberInputMessage({
                children: 'Host number can only contain digits.',
              });
            },
            test: ({ value }) => /^\d+$/.test(value as string),
          },
          { test: testNotBlank },
        ],
      },
      [INPUT_TEST_IDS.organizationName]: {
        defaults: {
          getValue: () => organizationNameInputRef.current.getValue?.call(null),
        },
        tests: [{ test: testNotBlank }],
      },
      [INPUT_TEST_IDS.organizationPrefix]: {
        defaults: {
          getValue: () =>
            organizationPrefixInputRef.current.getValue?.call(null),
          max: MAX_ORGANIZATION_PREFIX_LENGTH,
          min: MIN_ORGANIZATION_PREFIX_LENGTH,
          onSuccess: () => {
            setOrganizationPrefixInputMessage(undefined);
          },
        },
        tests: [
          {
            onFailure: ({ max, min }) => {
              setOrganizationPrefixInputMessage({
                children: `Organization prefix must be ${min} to ${max} lowercase alphanumeric characters.`,
              });
            },
            test: ({ max, min, value }) =>
              RegExp(`^[a-z0-9]{${min},${max}}$`).test(value as string),
          },
        ],
      },
    }),
    [
      isConfirmAdminPassword,
      setAdminPasswordInputMessage,
      setConfirmAdminPasswordInputMessage,
      setDomainNameInputMessage,
      setHostNameInputMessage,
      setHostNumberInputMessage,
      setOrganizationPrefixInputMessage,
    ],
  );
  const testInput = useMemo(
    () => createTestInputFunction(inputTests),
    [inputTests],
  );

  const testAllInputs = useCallback(
    (...excludeTestIds: string[]) =>
      testInput({ excludeTestIds, isIgnoreOnCallbacks: true }),
    [testInput],
  );
  const testInputSeparate = useCallback(
    (id: string, input: InputTestInputs[string]) => {
      const isLocalValid = testInput({
        inputs: { [id]: input },
      });
      toggleSubmitDisabled?.call(null, isLocalValid && testAllInputs(id));
    },
    [testInput, testAllInputs, toggleSubmitDisabled],
  );
  const populateOrganizationPrefixInput = useCallback(
    ({
      organizationName = organizationNameInputRef.current.getValue?.call(null),
    } = {}) => {
      const organizationPrefix = buildOrganizationPrefix(organizationName);

      organizationPrefixInputRef.current.setValue?.call(
        null,
        organizationPrefix,
      );

      return organizationPrefix;
    },
    [],
  );
  const populateHostNameInput = useCallback(
    ({
      organizationPrefix = organizationPrefixInputRef.current.getValue?.call(
        null,
      ),
      hostNumber = hostNumberInputRef.current.getValue?.call(null),
      domainName = domainNameInputRef.current.getValue?.call(null),
    } = {}) => {
      const hostName = buildHostName({
        organizationPrefix,
        hostNumber,
        domainName,
      });

      hostNameInputRef.current.setValue?.call(null, hostName);

      return hostName;
    },
    [],
  );
  const isOrganizationPrefixPrereqFilled = useCallback(
    () =>
      isEmpty([organizationNameInputRef.current.getValue?.call(null)], {
        not: true,
      }),
    [],
  );
  const isHostNamePrereqFilled = useCallback(
    () =>
      isEmpty(
        [
          organizationPrefixInputRef.current.getValue?.call(null),
          hostNumberInputRef.current.getValue?.call(null),
          domainNameInputRef.current.getValue?.call(null),
        ],
        {
          not: true,
        },
      ),
    [],
  );
  const populateOrganizationPrefixInputOnBlur: OutlinedInputWithLabelOnBlur =
    useCallback(() => {
      if (organizationPrefixInputRef.current.getIsChangedByUser?.call(null)) {
        setIsShowOrganizationPrefixSuggest(isOrganizationPrefixPrereqFilled());
      } else {
        populateOrganizationPrefixInput();
      }
    }, [isOrganizationPrefixPrereqFilled, populateOrganizationPrefixInput]);
  const populateHostNameInputOnBlur: OutlinedInputWithLabelOnBlur =
    useCallback(() => {
      if (hostNameInputRef.current.getIsChangedByUser?.call(null)) {
        setIsShowHostNameSuggest(isHostNamePrereqFilled());
      } else {
        populateHostNameInput();
      }
    }, [isHostNamePrereqFilled, populateHostNameInput]);
  const handleOrganizationPrefixSuggest = useCallback(() => {
    const organizationPrefix = populateOrganizationPrefixInput();

    if (!hostNameInputRef.current.getIsChangedByUser?.call(null)) {
      populateHostNameInput({ organizationPrefix });
    }
  }, [populateHostNameInput, populateOrganizationPrefixInput]);
  const handlerHostNameSuggest = useCallback(() => {
    populateHostNameInput();
  }, [populateHostNameInput]);
  const buildHelpMessage = useCallback(
    (text: string) => (previous?: string) =>
      previous === text ? undefined : text,
    [],
  );

  useImperativeHandle(ref, () => ({
    get: () => ({
      adminPassword: adminPasswordInputRef.current.getValue?.call(null),
      organizationName: organizationNameInputRef.current.getValue?.call(null),
      organizationPrefix:
        organizationPrefixInputRef.current.getValue?.call(null),
      domainName: domainNameInputRef.current.getValue?.call(null),
      hostNumber: hostNumberInputRef.current.getValue?.call(null),
      hostName: hostNameInputRef.current.getValue?.call(null),
    }),
  }));

  return (
    <FlexBox>
      <MUIGrid columns={{ xs: 1, sm: 2, md: 3 }} container spacing="1em">
        <MUIGrid item xs={1}>
          <FlexBox>
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id="striker-init-general-organization-name"
                  inputProps={{
                    onBlur: populateOrganizationPrefixInputOnBlur,
                  }}
                  inputLabelProps={{ isNotifyRequired: true }}
                  label="Organization name"
                  onChange={() => {
                    toggleSubmitDisabled?.call(null, testAllInputs());
                  }}
                  onHelp={() => {
                    setHelpMessage(
                      buildHelpMessage(
                        'Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you.',
                      ),
                    );
                  }}
                />
              }
              ref={organizationNameInputRef}
            />
            <FlexBox
              row
              sx={{
                '& > :first-child': {
                  flexGrow: 1,
                },
              }}
            >
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-organization-prefix"
                    inputProps={{
                      endAdornment: (
                        <SuggestButton
                          show={isShowOrganizationPrefixSuggest}
                          onClick={handleOrganizationPrefixSuggest}
                        />
                      ),
                      inputProps: {
                        maxLength: MAX_ORGANIZATION_PREFIX_LENGTH,
                        sx: {
                          minWidth: '2.5em',
                        },
                      },
                      onBlur: populateHostNameInputOnBlur,
                    }}
                    inputLabelProps={{ isNotifyRequired: true }}
                    label="Prefix"
                    onChange={({ target: { value } }) => {
                      testInputSeparate(INPUT_TEST_IDS.organizationPrefix, {
                        [INPUT_TEST_IDS.organizationPrefix]: {
                          max: MAX_ORGANIZATION_PREFIX_LENGTH,
                          min: MIN_ORGANIZATION_PREFIX_LENGTH,
                          value,
                        },
                      });
                      setIsShowOrganizationPrefixSuggest(
                        isOrganizationPrefixPrereqFilled(),
                      );
                    }}
                    onHelp={() => {
                      setHelpMessage(
                        buildHelpMessage(
                          "Alphanumberic short-form of the organization name. It's used as the prefix for host names.",
                        ),
                      );
                    }}
                  />
                }
                ref={organizationPrefixInputRef}
              />
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-host-number"
                    inputProps={{
                      inputProps: {
                        maxLength: MAX_HOST_NUMBER_LENGTH,
                        sx: {
                          minWidth: '2em',
                        },
                      },
                      onBlur: populateHostNameInputOnBlur,
                    }}
                    inputLabelProps={{ isNotifyRequired: true }}
                    label="Striker #"
                    onChange={({ target: { value } }) => {
                      testInputSeparate(INPUT_TEST_IDS.hostNumber, { value });
                    }}
                    onHelp={() => {
                      setHelpMessage(
                        buildHelpMessage(
                          "Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such.",
                        ),
                      );
                    }}
                  />
                }
                ref={hostNumberInputRef}
                valueType="number"
              />
            </FlexBox>
          </FlexBox>
        </MUIGrid>
        <MUIGrid item xs={1}>
          <FlexBox>
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id="striker-init-general-domain-name"
                  inputProps={{
                    onBlur: populateHostNameInputOnBlur,
                  }}
                  inputLabelProps={{ isNotifyRequired: true }}
                  label="Domain name"
                  onChange={({ target: { value } }) => {
                    testInputSeparate(INPUT_TEST_IDS.domainName, { value });
                  }}
                  onHelp={() => {
                    setHelpMessage(
                      buildHelpMessage(
                        "Domain name for this striker. It's also the default domain used when creating new install manifests.",
                      ),
                    );
                  }}
                />
              }
              ref={domainNameInputRef}
            />

            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id="striker-init-general-host-name"
                  inputProps={{
                    endAdornment: (
                      <SuggestButton
                        show={isShowHostNameSuggest}
                        onClick={handlerHostNameSuggest}
                      />
                    ),
                  }}
                  inputLabelProps={{ isNotifyRequired: true }}
                  label="Host name"
                  onChange={({ target: { value } }) => {
                    testInputSeparate(INPUT_TEST_IDS.hostName, { value });
                    setIsShowHostNameSuggest(isHostNamePrereqFilled());
                  }}
                  onHelp={() => {
                    setHelpMessage(
                      buildHelpMessage(
                        "Host name for this striker. It's usually a good idea to use the auto-generated value.",
                      ),
                    );
                  }}
                />
              }
              ref={hostNameInputRef}
            />
          </FlexBox>
        </MUIGrid>
        <MUIGrid item xs={1} sm={2} md={1}>
          <MUIGrid
            columns={{ xs: 1, sm: 2, md: 1 }}
            container
            spacing="1em"
            sx={{
              '& > * > *': {
                width: '100%',
              },
            }}
          >
            <MUIGrid item xs={1}>
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id="striker-init-general-admin-password"
                    inputProps={{
                      inputProps: {
                        type: INPUT_TYPES.password,
                      },
                      onPasswordVisibilityAppend: (inputType) => {
                        setIsConfirmAdminPassword(
                          inputType === INPUT_TYPES.password,
                        );
                      },
                    }}
                    inputLabelProps={{ isNotifyRequired: true }}
                    label="Admin password"
                    onChange={({ target: { value } }) => {
                      testInputSeparate(INPUT_TEST_IDS.adminPassword, {
                        value,
                      });
                    }}
                    onHelp={() => {
                      setHelpMessage(
                        buildHelpMessage(
                          "Password use to login to this Striker and connect to its database. Don't provide an used password here because it'll be stored as plaintext.",
                        ),
                      );
                    }}
                  />
                }
                ref={adminPasswordInputRef}
              />
            </MUIGrid>
            {isConfirmAdminPassword && (
              <MUIGrid item xs={1}>
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id="striker-init-general-confirm-admin-password"
                      inputProps={{
                        inputProps: {
                          type: INPUT_TYPES.password,
                        },
                      }}
                      inputLabelProps={{
                        isNotifyRequired: isConfirmAdminPassword,
                      }}
                      label="Confirm password"
                      onChange={({ target: { value } }) => {
                        testInputSeparate(INPUT_TEST_IDS.confirmAdminPassword, {
                          value,
                        });
                      }}
                    />
                  }
                  ref={confirmAdminPasswordInputRef}
                />
              </MUIGrid>
            )}
          </MUIGrid>
        </MUIGrid>
      </MUIGrid>
      <MessageGroup
        count={INPUT_COUNT}
        defaultMessageType="warning"
        ref={messageGroupRef}
      />
      {helpMessage && (
        <MessageBox
          onClose={() => {
            setHelpMessage(undefined);
          }}
        >
          {helpMessage}
        </MessageBox>
      )}
    </FlexBox>
  );
});

GeneralInitForm.defaultProps = { toggleSubmitDisabled: undefined };
GeneralInitForm.displayName = 'GeneralInitForm';

export type { GeneralInitFormForwardRefContent };

export default GeneralInitForm;
