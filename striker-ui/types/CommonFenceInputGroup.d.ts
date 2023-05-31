type FenceParameterInputBuilderParameters = {
  id: string;
  isChecked?: boolean;
  isRequired?: boolean;
  isSensitive?: boolean;
  label?: string;
  name?: string;
  selectOptions?: string[];
  value?: string;
};

type FenceParameterInputBuilder = (
  args: FenceParameterInputBuilderParameters,
) => ReactElement;

type MapToInputBuilder = Partial<
  Record<Exclude<FenceParameterType, 'string'>, FenceParameterInputBuilder>
> & { string: FenceParameterInputBuilder };

type CommonFenceInputGroupOptionalProps = {
  fenceId?: string;
  fenceTemplate?: APIFenceTemplate;
  previousFenceName?: string;
  previousFenceParameters?: FenceParameters;
  fenceParameterTooltipProps?: import('@mui/material').TooltipProps;
};

type CommonFenceInputGroupProps = CommonFenceInputGroupOptionalProps;
