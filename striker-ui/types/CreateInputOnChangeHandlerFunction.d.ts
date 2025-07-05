type MapToInputType = Pick<MapToType, 'boolean' | 'number' | 'string'>;

type InputOnChangeParameters = Parameters<
  Exclude<
    import('@mui/material/InputBase').InputBaseProps['onChange'],
    undefined
  >
>;

type StateSetter = (value: unknown) => void;

type CreateInputOnChangeHandlerOptions<TypeName extends keyof MapToInputType> =
  {
    postSet?: (...args: InputOnChangeParameters) => void;
    preSet?: (...args: InputOnChangeParameters) => void;
    set?: StateSetter;
    setType?: TypeName;
    valueKey?: Extract<
      keyof import('react').ChangeEvent<HTMLInputElement>['target'],
      'checked' | 'value'
    >;
  };
