type MuiInputBaseProps = import('@mui/material').InputBaseProps;

type ReactChangeEventHandler =
  import('react').ChangeEventHandler<HTMLInputElement>;

type MuiInputBasePropsBlurEventHandler = Exclude<
  MuiInputBaseProps['onBlur'],
  undefined
>;

type MuiInputBasePropsFocusEventHandler = Exclude<
  MuiInputBaseProps['onFocus'],
  undefined
>;

type UncontrolledInputComponentMountEventHandler = () => void;

type UncontrolledInputComponentUnmountEventHandler = () => void;

type UncontrolledInputOptionalProps = {
  onBlur?: ExtendableEventHandler<MuiInputBasePropsBlurEventHandler>;
  onChange?: ExtendableEventHandler<ReactChangeEventHandler>;
  onFocus?: ExtendableEventHandler<MuiInputBasePropsFocusEventHandler>;
  onMount?: UncontrolledInputComponentMountEventHandler;
  onUnmount?: UncontrolledInputComponentUnmountEventHandler;
};

type UncontrolledInputProps<InputElement extends import('react').ReactElement> =
  UncontrolledInputOptionalProps & {
    input: InputElement;
  };

type UncontrolledInputForwardedRefContent<
  ValueType extends keyof MapToInputType,
> = {
  get: () => MapToInputType[ValueType];
  set: (value: MapToInputType[ValueType]) => void;
};
