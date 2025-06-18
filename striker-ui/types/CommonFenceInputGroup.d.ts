type FenceParameterInputBuilderParameters<M extends MapToInputTestID> = {
  formUtils: FormUtils<M>;
  id: string;
  isChecked?: boolean;
  isRequired?: boolean;
  isSensitive?: boolean;
  label?: string;
  name?: string;
  selectOptions?: string[];
  value?: string;
};

type FenceParameterInputBuilder<M extends MapToInputTestID> = (
  args: FenceParameterInputBuilderParameters<M>,
) => React.ReactElement;

type MapToInputBuilder<M extends MapToInputTestID> = Partial<
  Record<Exclude<FenceParameterType, 'string'>, FenceParameterInputBuilder<M>>
> & { string: FenceParameterInputBuilder<M> };

type CommonFenceInputGroupOptionalProps = {
  fenceId?: string;
  fenceTemplate?: APIFenceTemplate;
  previousFenceName?: string;
  previousFenceParameters?: FenceParameters;
  fenceParameterTooltipProps?: import('@mui/material/Tooltip').TooltipProps;
};

type CommonFenceInputGroupProps<M extends MapToInputTestID> =
  CommonFenceInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };
