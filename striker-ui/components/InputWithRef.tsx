import { InputBaseProps } from '@mui/material';
import {
  cloneElement,
  ForwardedRef,
  forwardRef,
  ReactElement,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import createInputOnChangeHandler from '../lib/createInputOnChangeHandler';
import { createTestInputFunction } from '../lib/test_input';
import useIsFirstRender from '../hooks/useIsFirstRender';

type InputWithRefOptionalPropsWithDefault<
  TypeName extends keyof MapToInputType,
> = {
  createInputOnChangeHandlerOptions?: CreateInputOnChangeHandlerOptions<TypeName>;
  required?: boolean;
  valueType?: TypeName;
};
type InputWithRefOptionalPropsWithoutDefault<
  TypeName extends keyof MapToInputType,
> = {
  inputTestBatch?: InputTestBatch;
  onFirstRender?: (args: { isRequired: boolean }) => void;
  valueKey?: CreateInputOnChangeHandlerOptions<TypeName>['valueKey'];
};

type InputWithRefOptionalProps<TypeName extends keyof MapToInputType> =
  InputWithRefOptionalPropsWithDefault<TypeName> &
    InputWithRefOptionalPropsWithoutDefault<TypeName>;

type InputWithRefProps<
  TypeName extends keyof MapToInputType,
  InputComponent extends ReactElement,
> = InputWithRefOptionalProps<TypeName> & {
  input: InputComponent;
};

type InputForwardedRefContent<TypeName extends keyof MapToInputType> = {
  getIsChangedByUser?: () => boolean;
  getValue?: () => MapToInputType[TypeName];
  isValid?: () => boolean;
  setValue?: StateSetter;
};

const INPUT_TEST_ID = 'input';
const MAP_TO_INITIAL_VALUE: MapToInputType = {
  boolean: false,
  number: 0,
  string: '',
};

const INPUT_WITH_REF_DEFAULT_PROPS: Required<
  InputWithRefOptionalPropsWithDefault<'string'>
> &
  InputWithRefOptionalPropsWithoutDefault<'string'> = {
  createInputOnChangeHandlerOptions: {},
  required: false,
  valueType: 'string',
};

const InputWithRef = forwardRef(
  <TypeName extends keyof MapToInputType, InputComponent extends ReactElement>(
    {
      input,
      inputTestBatch,
      onFirstRender,
      required: isRequired = INPUT_WITH_REF_DEFAULT_PROPS.required,
      valueKey,
      valueType = INPUT_WITH_REF_DEFAULT_PROPS.valueType as TypeName,
      // Props with initial value that depend on others.
      createInputOnChangeHandlerOptions: {
        postSet: postSetAppend,
        valueKey: onChangeValueKey = valueKey,
        ...restCreateInputOnChangeHandlerOptions
      } = INPUT_WITH_REF_DEFAULT_PROPS.createInputOnChangeHandlerOptions as CreateInputOnChangeHandlerOptions<TypeName>,
    }: InputWithRefProps<TypeName, InputComponent>,
    ref: ForwardedRef<InputForwardedRefContent<TypeName>>,
  ) => {
    const { props: inputProps } = input;

    const vKey = useMemo(
      () => onChangeValueKey ?? ('checked' in inputProps ? 'checked' : 'value'),
      [inputProps, onChangeValueKey],
    );

    const {
      onBlur: initOnBlur,
      onChange: initOnChange,
      onFocus: initOnFocus,
      [vKey]: initValue = MAP_TO_INITIAL_VALUE[valueType],
      ...restInitProps
    } = inputProps;

    const isFirstRender = useIsFirstRender();

    const [inputValue, setInputValue] =
      useState<MapToInputType[TypeName]>(initValue);
    const [isChangedByUser, setIsChangedByUser] = useState<boolean>(false);
    const [isInputValid, setIsInputValid] = useState<boolean>(false);

    const setValue: StateSetter = useCallback((value) => {
      setInputValue(value as MapToInputType[TypeName]);
    }, []);

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
    const onChange = useMemo(
      () =>
        createInputOnChangeHandler<TypeName>({
          postSet: (...args) => {
            setIsChangedByUser(true);
            initOnChange?.call(null, ...args);
            postSetAppend?.call(null, ...args);
          },
          set: setValue,
          setType: valueType,
          valueKey: vKey,
          ...restCreateInputOnChangeHandlerOptions,
        }),
      [
        initOnChange,
        postSetAppend,
        restCreateInputOnChangeHandlerOptions,
        setValue,
        vKey,
        valueType,
      ],
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
        setValue,
      }),
      [inputValue, isChangedByUser, isInputValid, setValue],
    );

    return cloneElement(input, {
      ...restInitProps,
      onBlur,
      onChange,
      onFocus,
      required: isRequired,
      [vKey]: inputValue,
    });
  },
);

InputWithRef.defaultProps = INPUT_WITH_REF_DEFAULT_PROPS;
InputWithRef.displayName = 'InputWithRef';

export type { InputForwardedRefContent, InputWithRefProps };

export default InputWithRef;
