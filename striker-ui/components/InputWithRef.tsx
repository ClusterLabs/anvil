import {
  CheckboxProps as MuiCheckboxProps,
  InputProps as MuiInputProps,
} from '@mui/material';
import { debounce } from 'lodash';
import {
  cloneElement,
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
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
  debounceWait?: number;
  inputTestBatch?: InputTestBatch;
  onBlurAppend?: MuiInputProps['onBlur'];
  onFirstRender?: InputFirstRenderFunction;
  onFocusAppend?: MuiInputProps['onFocus'];
  onUnmount?: () => void;
  valueKey?: CreateInputOnChangeHandlerOptions<TypeName>['valueKey'];
};

type InputWithRefOptionalProps<TypeName extends keyof MapToInputType> =
  InputWithRefOptionalPropsWithDefault<TypeName> &
    InputWithRefOptionalPropsWithoutDefault<TypeName>;

type InputWithRefProps<
  TypeName extends keyof MapToInputType,
  InputComponent extends React.ReactElement<
    MuiInputProps & Pick<MuiCheckboxProps, 'checked'>
  >,
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

const InputWithRef = forwardRef(
  <
    TypeName extends keyof MapToInputType,
    InputComponent extends React.ReactElement<
      MuiInputProps & Pick<MuiCheckboxProps, 'checked'>
    >,
  >(
    {
      debounceWait = 500,
      input,
      inputTestBatch,
      onBlurAppend,
      onFirstRender,
      onFocusAppend,
      onUnmount,
      required: isRequired = false,
      valueKey,
      valueType = 'string' as TypeName,
      // Props with initial value that depend on others.
      createInputOnChangeHandlerOptions: {
        postSet: postSetAppend,
        valueKey: onChangeValueKey = valueKey,
        ...restCreateInputOnChangeHandlerOptions
      } = {} as CreateInputOnChangeHandlerOptions<TypeName>,
    }: InputWithRefProps<TypeName, InputComponent>,
    ref: React.ForwardedRef<InputForwardedRefContent<TypeName>>,
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
      [vKey]: unknownValue = MAP_TO_INITIAL_VALUE[valueType],
      ...restInitProps
    } = inputProps;

    const initValue = unknownValue as MapToInputType[TypeName];

    const [inputValue, setInputValue] =
      useState<MapToInputType[TypeName]>(initValue);

    const changedByUserRef = useRef<boolean>(false);
    const validRef = useRef<boolean>(false);

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

    const doTestAndSet = useCallback(
      (value: MapToInputType[TypeName]) => {
        const valid =
          testInput?.call(null, {
            inputs: { [INPUT_TEST_ID]: { value } },
            isIgnoreOnCallbacks: true,
          }) ?? false;

        validRef.current = valid;

        onFirstRender?.call(null, { isValid: valid });
      },
      [onFirstRender, testInput],
    );

    const debounceDoTestAndSet = useMemo(
      () => debounce(doTestAndSet, debounceWait),
      [debounceWait, doTestAndSet],
    );

    const onBlur = useMemo<MuiInputProps['onBlur']>(
      () =>
        initOnBlur ??
        (testInput &&
          ((...args) => {
            const {
              0: {
                target: { value },
              },
            } = args;

            const valid = testInput({
              inputs: { [INPUT_TEST_ID]: { value } },
            });

            validRef.current = valid;

            onBlurAppend?.call(null, ...args);
          })),
      [initOnBlur, onBlurAppend, testInput],
    );
    const onChange = useMemo(
      () =>
        createInputOnChangeHandler<TypeName>({
          postSet: (...args) => {
            changedByUserRef.current = true;

            initOnChange?.call(null, ...args);
            postSetAppend?.call(null, ...args);
          },
          set: (value) => {
            setValue(value);
            debounceDoTestAndSet(value as MapToInputType[TypeName]);
          },
          setType: valueType,
          valueKey: vKey,
          ...restCreateInputOnChangeHandlerOptions,
        }),
      [
        debounceDoTestAndSet,
        initOnChange,
        postSetAppend,
        restCreateInputOnChangeHandlerOptions,
        setValue,
        vKey,
        valueType,
      ],
    );
    const onFocus = useMemo<MuiInputProps['onFocus']>(
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
      doTestAndSet(inputValue);

      return onUnmount;

      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    /**
     * Update the input value to the init value until it's changed by the user.
     * This allows us to populate the input based on value from other field(s).
     */
    useEffect(() => {
      if (changedByUserRef.current || inputValue === initValue || !initValue)
        return;

      doTestAndSet(initValue);

      setInputValue(initValue);
    }, [doTestAndSet, initValue, inputValue]);

    useImperativeHandle(
      ref,
      () => ({
        getIsChangedByUser: () => changedByUserRef.current,
        getValue: () => inputValue,
        isValid: () => validRef.current,
        setValue,
      }),
      [inputValue, setValue],
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

InputWithRef.displayName = 'InputWithRef';

export type { InputForwardedRefContent, InputWithRefProps };

export default InputWithRef;
