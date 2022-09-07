import {
  cloneElement,
  ForwardedRef,
  forwardRef,
  ReactElement,
  useImperativeHandle,
  useState,
} from 'react';

import createInputOnChangeHandler, {
  CreateInputOnChangeHandlerOptions,
  MapToStateSetter,
} from '../lib/createInputOnChangeHandler';

type InputWithRefTypeMap = Pick<MapToType, 'number' | 'string'>;

type InputWithRefOptionalProps<TypeName extends keyof InputWithRefTypeMap> = {
  createInputOnChangeHandlerOptions?: Omit<
    CreateInputOnChangeHandlerOptions<TypeName>,
    'set'
  >;
  valueType?: TypeName | 'string';
};

type InputWithRefProps<
  TypeName extends keyof InputWithRefTypeMap,
  InputComponent extends ReactElement,
> = InputWithRefOptionalProps<TypeName> & {
  input: InputComponent;
};

type InputForwardedRefContent<TypeName extends keyof InputWithRefTypeMap> = {
  getIsChangedByUser?: () => boolean;
  getValue?: () => InputWithRefTypeMap[TypeName];
  setValue?: MapToStateSetter[TypeName];
};

const MAP_TO_INITIAL_VALUE: InputWithRefTypeMap = {
  number: 0,
  string: '',
};

const INPUT_WITH_REF_DEFAULT_PROPS: Required<
  InputWithRefOptionalProps<'string'>
> = {
  createInputOnChangeHandlerOptions: {},
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
      valueType = INPUT_WITH_REF_DEFAULT_PROPS.valueType,
    }: InputWithRefProps<TypeName, InputComponent>,
    ref: ForwardedRef<InputForwardedRefContent<TypeName>>,
  ) => {
    const {
      props: { onChange: initOnChange, value: initValue, ...restInitProps },
    } = input;

    const [value, setValue] = useState<InputWithRefTypeMap[TypeName]>(
      initValue ?? MAP_TO_INITIAL_VALUE[valueType],
    ) as [InputWithRefTypeMap[TypeName], MapToStateSetter[TypeName]];
    const [isChangedByUser, setIsChangedByUser] = useState<boolean>(false);

    const onChange = createInputOnChangeHandler<TypeName>({
      postSet: (...args) => {
        setIsChangedByUser(true);
        initOnChange?.call(null, ...args);
        postSetAppend?.call(null, ...args);
      },
      set: setValue,
      setType: valueType,
      ...restCreateInputOnChangeHandlerOptions,
    });

    useImperativeHandle(
      ref,
      () => ({
        getIsChangedByUser: () => isChangedByUser,
        getValue: () => value,
        setValue,
      }),
      [isChangedByUser, value],
    );

    return cloneElement(input, { ...restInitProps, onChange, value });
  },
);

InputWithRef.defaultProps = INPUT_WITH_REF_DEFAULT_PROPS;
InputWithRef.displayName = 'InputWithRef';

export type { InputForwardedRefContent, InputWithRefProps };

export default InputWithRef;
