type FenceParameterInputBuilder = (args: {
  id: string;
  isChecked?: boolean;
  isRequired?: boolean;
  label?: string;
  selectOptions?: string[];
  value?: string;
}) => ReactElement;

type MapToInputBuilder = Partial<
  Record<Exclude<FenceParameterType, 'string'>, FenceParameterInputBuilder>
> & { string: FenceParameterInputBuilder };

type CommonFenceInputGroupOptionalProps = {
  fenceId?: string;
  fenceTemplate?: APIFenceTemplate;
  previousFenceName?: string;
  previousFenceParameters?: FenceParameters;
};

type CommonFenceInputGroupProps = CommonFenceInputGroupOptionalProps;
