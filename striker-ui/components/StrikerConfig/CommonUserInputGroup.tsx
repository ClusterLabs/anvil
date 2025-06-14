import { useMemo, useRef, useState } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import Grid from '../Grid';
import InputWithRef, { InputForwardedRefContent } from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildPeacefulStringTestBatch,
  testNotBlank,
} from '../../lib/test_input';

const INPUT_ID_USER_CONFIRM_PASSWORD = 'common-user-input-confirm-password';
const INPUT_ID_USER_NAME = 'common-user-input-name';
const INPUT_ID_USER_PASSWORD = 'common-user-input-password';

const INPUT_LABEL_USER_CONFIRM_PASSWORD = 'Confirm password';
const INPUT_LABEL_USER_NAME = 'Username';
const INPUT_LABEL_USER_PASSWORD = 'Password';

const CommonUserInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_USER_CONFIRM_PASSWORD
      | typeof INPUT_ID_USER_NAME
      | typeof INPUT_ID_USER_PASSWORD]: string;
  },
>(
  ...[props]: Parameters<React.FC<CommonUserInputGroupProps<M>>>
): ReturnType<React.FC<CommonUserInputGroupProps<M>>> => {
  const {
    formUtils: {
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      setMessage,
      setValidity,
    },
    previous: { name: previousName } = {},
    readOnlyUserName,
    requirePassword = false,
    showPasswordField,
  } = props;

  const userPasswordInputRef = useRef<InputForwardedRefContent<'string'>>({});
  const userConfirmPasswordInputRef = useRef<
    InputForwardedRefContent<'string'>
  >({});

  const [requireConfirmPassword, setRequireConfirmPassword] =
    useState<boolean>(requirePassword);

  const userPasswordInputGroup = useMemo(
    () =>
      showPasswordField
        ? {
            'common-user-input-cell-password': {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id={INPUT_ID_USER_PASSWORD}
                      label={INPUT_LABEL_USER_PASSWORD}
                      type={INPUT_TYPES.password}
                    />
                  }
                  inputTestBatch={buildPeacefulStringTestBatch(
                    INPUT_LABEL_USER_PASSWORD,
                    () => {
                      setMessage(INPUT_ID_USER_PASSWORD);
                    },
                    {
                      onFinishBatch: buildFinishInputTestBatchFunction(
                        INPUT_ID_USER_PASSWORD,
                      ),
                    },
                    (message) => {
                      setMessage(INPUT_ID_USER_PASSWORD, { children: message });
                    },
                  )}
                  onBlurAppend={({ target: { value } }) => {
                    setRequireConfirmPassword(value.length > 0);
                    setValidity(
                      INPUT_ID_USER_CONFIRM_PASSWORD,
                      value ===
                        userConfirmPasswordInputRef.current.getValue?.call(
                          null,
                        ),
                    );
                  }}
                  onFirstRender={buildInputFirstRenderFunction(
                    INPUT_ID_USER_PASSWORD,
                  )}
                  ref={userPasswordInputRef}
                  required={requirePassword}
                />
              ),
            },
            'common-user-input-cell-confirm-password': {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id={INPUT_ID_USER_CONFIRM_PASSWORD}
                      inputProps={{ readOnly: !requireConfirmPassword }}
                      label={INPUT_LABEL_USER_CONFIRM_PASSWORD}
                      type={INPUT_TYPES.password}
                    />
                  }
                  inputTestBatch={{
                    defaults: {
                      onSuccess: () => {
                        setMessage(INPUT_ID_USER_CONFIRM_PASSWORD);
                      },
                    },
                    onFinishBatch: buildFinishInputTestBatchFunction(
                      INPUT_ID_USER_CONFIRM_PASSWORD,
                    ),
                    tests: [
                      { test: testNotBlank },
                      {
                        onFailure: () => {
                          setMessage(INPUT_ID_USER_CONFIRM_PASSWORD, {
                            children: 'The passwords do not match.',
                          });
                        },
                        test: ({ value }) =>
                          value ===
                          userPasswordInputRef.current.getValue?.call(null),
                      },
                    ],
                  }}
                  onFirstRender={buildInputFirstRenderFunction(
                    INPUT_ID_USER_CONFIRM_PASSWORD,
                  )}
                  ref={userConfirmPasswordInputRef}
                  required={requireConfirmPassword}
                />
              ),
            },
          }
        : undefined,
    [
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      requireConfirmPassword,
      requirePassword,
      setMessage,
      setValidity,
      showPasswordField,
    ],
  );

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3 }}
      layout={{
        'common-user-input-cell-name': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_USER_NAME}
                  inputProps={{ readOnly: readOnlyUserName }}
                  label={INPUT_LABEL_USER_NAME}
                  value={previousName}
                />
              }
              inputTestBatch={buildPeacefulStringTestBatch(
                INPUT_LABEL_USER_NAME,
                () => {
                  setMessage(INPUT_ID_USER_NAME);
                },
                {
                  onFinishBatch:
                    buildFinishInputTestBatchFunction(INPUT_ID_USER_NAME),
                },
                (message) => {
                  setMessage(INPUT_ID_USER_NAME, { children: message });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(INPUT_ID_USER_NAME)}
              required
            />
          ),
          md: 1,
          sm: 2,
        },
        ...userPasswordInputGroup,
      }}
      spacing="1em"
    />
  );
};

export {
  INPUT_ID_USER_CONFIRM_PASSWORD,
  INPUT_ID_USER_NAME,
  INPUT_ID_USER_PASSWORD,
};

export default CommonUserInputGroup;
