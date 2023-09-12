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

type UncontrolledInputEventHandler<HandlerType> = (
  toolbox: { handlers: { base?: HandlerType; origin?: HandlerType } },
  ...rest: Parameters<HandlerType>
) => ReturnType<HandlerType>;

type UncontrolledInputComponentMountEventHandler = () => void;

type UncontrolledInputComponentUnmountEventHandler = () => void;

type UncontrolledInputOptionalProps = {
  onBlur?: UncontrolledInputEventHandler<MuiInputBasePropsBlurEventHandler>;
  onChange?: UncontrolledInputEventHandler<ReactChangeEventHandler>;
  onFocus?: UncontrolledInputEventHandler<MuiInputBasePropsFocusEventHandler>;
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
