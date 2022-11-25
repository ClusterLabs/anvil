import { InputBaseProps } from '@mui/material';
import {
  cloneElement,
  ForwardedRef,
  forwardRef,
  ReactElement,
  useEffect,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import createInputOnChangeHandler, {
  CreateInputOnChangeHandlerOptions,
  MapToStateSetter,
} from '../lib/createInputOnChangeHandler';
import { createTestInputFunction } from '../lib/test_input';
import useIsFirstRender from '../hooks/useIsFirstRender';

type InputWithRefTypeMap = Pick<MapToType, 'number' | 'string'>;

type InputWithRefOptionalPropsWithDefault<
  TypeName extends keyof InputWithRefTypeMap,
> = {
  createInputOnChangeHandlerOptions?: Omit<
    CreateInputOnChangeHandlerOptions<TypeName>,
    'set'
  >;
  required?: boolean;
  valueType?: TypeName | 'string';
};
type InputWithRefOptionalPropsWithoutDefault = {
  inputTestBatch?: InputTestBatch;
  onFirstRender?: (args: { isRequired: boolean }) => void;
};

type InputWithRefOptionalProps<TypeName extends keyof InputWithRefTypeMap> =
  InputWithRefOptionalPropsWithDefault<TypeName> &
    InputWithRefOptionalPropsWithoutDefault;

type InputWithRefProps<
  TypeName extends keyof InputWithRefTypeMap,
  InputComponent extends ReactElement,
> = InputWithRefOptionalProps<TypeName> & {
  input: InputComponent;
};

type InputForwardedRefContent<TypeName extends keyof InputWithRefTypeMap> = {
  getIsChangedByUser?: () => boolean;
  getValue?: () => InputWithRefTypeMap[TypeName];
  isValid?: () => boolean;
  setValue?: MapToStateSetter[TypeName];
};

const INPUT_TEST_ID = 'input';
const MAP_TO_INITIAL_VALUE: InputWithRefTypeMap = {
  number: 0,
  string: '',
};

const INPUT_WITH_REF_DEFAULT_PROPS: Required<
  InputWithRefOptionalPropsWithDefault<'string'>
> &
  InputWithRefOptionalPropsWithoutDefault = {
  createInputOnChangeHandlerOptions: {},
  required: false,
  valueType: 'string',
};

const InputWithRef = forwardRef(
  <
    TypeName extends keyof InputWithRefTypeMap,
    InputComponent extends ReactElement,
  >(
    {
      createInputOnChangeHandlerOptions: {
        postSet: postSetAppend,
        ...restCreateInputOnChangeHandlerOptions
      } = INPUT_WITH_REF_DEFAULT_PROPS.createInputOnChangeHandlerOptions,
      input,
      inputTestBatch,
      onFirstRender,
      required: isRequired = INPUT_WITH_REF_DEFAULT_PROPS.required,
      valueType = INPUT_WITH_REF_DEFAULT_PROPS.valueType,
    }: InputWithRefProps<TypeName, InputComponent>,
    ref: ForwardedRef<InputForwardedRefContent<TypeName>>,
  ) => {
    const {
      props: {
        onBlur: initOnBlur,
        onChange: initOnChange,
        onFocus: initOnFocus,
        value: initValue = MAP_TO_INITIAL_VALUE[valueType],
        ...restInitProps
      },
    } = input;

    const isFirstRender = useIsFirstRender();

    const [inputValue, setInputValue] = useState<InputWithRefTypeMap[TypeName]>(
      initValue,
    ) as [InputWithRefTypeMap[TypeName], MapToStateSetter[TypeName]];
    const [isChangedByUser, setIsChangedByUser] = useState<boolean>(false);
    const [isInputValid, setIsInputValid] = useState<boolean>(false);

    const testInput: TestInputFunction | undefined = useMemo(() => {
      let result;

      if (inputTestBatch) {
        inputTestBatch.isRequired = isRequired;

        result = createTestInputFunction({
          [INPUT_TEST_ID]: inputTestBatch,
        });
      }

      return result;
    }, [inputTestBatch, isRequired]);

    const onBlur = useMemo<InputBaseProps['onBlur']>(
      () =>
        initOnBlur ??
        (testInput &&
          (({ target: { value } }) => {
            const isValid = testInput({
              inputs: { [INPUT_TEST_ID]: { value } },
            });

            setIsInputValid(isValid);
          })),
      [initOnBlur, testInput],
    );
    const onFocus = useMemo<InputBaseProps['onFocus']>(
      () =>
        initOnFocus ??
        (inputTestBatch &&
          (() => {
            inputTestBatch.defaults?.onSuccess?.call(null, { append: {} });
          })),
      [initOnFocus, inputTestBatch],
    );

    const onChange = createInputOnChangeHandler<TypeName>({
      postSet: (...args) => {
        setIsChangedByUser(true);
        initOnChange?.call(null, ...args);
        postSetAppend?.call(null, ...args);
      },
      set: setInputValue,
      setType: valueType,
      ...restCreateInputOnChangeHandlerOptions,
    });

    useEffect(() => {
      if (isFirstRender) {
        onFirstRender?.call(null, { isRequired });
      }
    }, [isFirstRender, isRequired, onFirstRender]);

    useImperativeHandle(
      ref,
      () => ({
        getIsChangedByUser: () => isChangedByUser,
        getValue: () => inputValue,
        isValid: () => isInputValid,
        setValue: setInputValue,
      }),
      [inputValue, isChangedByUser, isInputValid],
    );

    return cloneElement(input, {
      ...restInitProps,
      onBlur,
      onChange,
      onFocus,
      required: isRequired,
      value: inputValue,
    });
  },
);

InputWithRef.defaultProps = INPUT_WITH_REF_DEFAULT_PROPS;
InputWithRef.displayName = 'InputWithRef';

export type { InputForwardedRefContent, InputWithRefProps };

export default InputWithRef;
