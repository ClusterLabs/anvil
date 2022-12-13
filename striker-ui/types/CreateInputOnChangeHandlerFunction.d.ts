type MapToInputType = Pick<MapToType, 'number' | 'string'>;

type InputOnChangeParameters = Parameters<
  Exclude<import('@mui/material').InputBaseProps['onChange'], undefined>
>;

type StateSetter = (value: unknown) => void;

type CreateInputOnChangeHandlerOptions<TypeName extends keyof MapToInputType> =
  {
    postSet?: (...args: InputOnChangeParameters) => void;
    preSet?: (...args: InputOnChangeParameters) => void;
    set?: StateSetter;
    setType?: TypeName;
  };
