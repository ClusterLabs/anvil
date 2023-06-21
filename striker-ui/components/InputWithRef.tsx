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
  onBlurAppend?: InputBaseProps['onBlur'];
  onFirstRender?: InputFirstRenderFunction;
  onFocusAppend?: InputBaseProps['onFocus'];
  onUnmount?: () => void;
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
      onBlurAppend,
      onFirstRender,
      onFocusAppend,
      onUnmount,
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
          ((...args) => {
            const {
              0: {
                target: { value },
              },
            } = args;
            const isValid = testInput({
              inputs: { [INPUT_TEST_ID]: { value } },
            });

            setIsInputValid(isValid);
            onBlurAppend?.call(null, ...args);
          })),
      [initOnBlur, onBlurAppend, testInput],
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
          ((...args) => {
            inputTestBatch.defaults?.onSuccess?.call(null, { append: {} });
            onFocusAppend?.call(null, ...args);
          })),
      [initOnFocus, inputTestBatch, onFocusAppend],
    );

    /**
     * Using any setState function synchronously in the render function
     * directly will trigger the 'cannot update a component while readering a
     * different component' warning. This can be solved by wrapping the
     * setState call(s) in a useEffect hook because it executes **after** the
     * render function completes.
     */
    useEffect(() => {
      const isValid =
        testInput?.call(null, {
          inputs: { [INPUT_TEST_ID]: { value: inputValue } },
          isIgnoreOnCallbacks: true,
        }) ?? false;

      onFirstRender?.call(null, { isValid });

      return onUnmount;

      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

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
