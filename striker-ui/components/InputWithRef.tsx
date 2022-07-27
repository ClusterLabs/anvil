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

type InputWithRefOptionalProps<TypeName extends keyof MapToType> = {
  createInputOnChangeHandlerOptions?: Omit<
    CreateInputOnChangeHandlerOptions<TypeName>,
    'set'
  >;
  valueType?: TypeName | 'string';
};

type InputWithRefProps<
  TypeName extends keyof MapToType,
  InputComponent extends ReactElement,
> = InputWithRefOptionalProps<TypeName> & {
  input: InputComponent;
};

type InputForwardedRefContent<TypeName extends keyof MapToType> = {
  getIsChangedByUser?: () => boolean;
  getValue?: () => MapToType[TypeName];
  setValue?: MapToStateSetter[TypeName];
};

const MAP_TO_INITIAL_VALUE: MapToType = {
  number: 0,
  string: '',
  undefined,
};

const INPUT_WITH_REF_DEFAULT_PROPS: Required<
  InputWithRefOptionalProps<'string'>
> = {
  createInputOnChangeHandlerOptions: {},
  valueType: 'string',
};

const InputWithRef = forwardRef(
  <TypeName extends keyof MapToType, InputComponent extends ReactElement>(
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
    const [value, setValue] = useState<MapToType[TypeName]>(
      MAP_TO_INITIAL_VALUE[valueType] as MapToType[TypeName],
    ) as [MapToType[TypeName], MapToStateSetter[TypeName]];
    const [isChangedByUser, setIsChangedByUser] = useState<boolean>(false);

    const onChange = createInputOnChangeHandler<TypeName>({
      postSet: (...args) => {
        setIsChangedByUser(true);
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

    return cloneElement(input, { ...input.props, onChange, value });
  },
);

InputWithRef.defaultProps = INPUT_WITH_REF_DEFAULT_PROPS;
InputWithRef.displayName = 'InputWithRef';

export type { InputForwardedRefContent, InputWithRefProps };

export default InputWithRef;
