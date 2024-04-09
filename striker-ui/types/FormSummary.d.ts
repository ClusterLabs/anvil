type FormEntry = boolean | null | number | string;

type FormEntries = {
  [key: string]: FormEntries | FormEntry;
};

type CommonFormEntryHandlerArgs = {
  depth: number;
  entry: FormEntry;
  hasPassword: boolean;
  key: string;
};

type CapFormEntryLabel = (value: string) => string;

type GetFormEntryLabelFunction = (
  args: CommonFormEntryHandlerArgs & {
    cap: CapFormEntryLabel;
  },
) => string;

type GetFormEntryPropsFunction = (
  args: CommonFormEntryHandlerArgs,
) => import('@mui/material').ListItemProps;

type GetFormEntriesPropsFunction = (args: {
  depth: number;
  entries: FormEntries;
  key?: string;
}) => import('@mui/material').ListProps;

type RenderFormValueFunction = (
  args: CommonFormEntryHandlerArgs,
) => import('react').ReactElement;

type RenderFormEntryFunction = (
  args: CommonFormEntryHandlerArgs & {
    getLabel: GetFormEntryLabelFunction;
    nest: boolean;
    renderValue: (
      base: RenderFormValueFunction,
      ...rfvargs: Parameters<RenderFormValueFunction>
    ) => ReturnType<RenderFormValueFunction>;
  },
) => import('react').ReactElement;

type SkipFormEntryFunction = (args: CommonFormEntryHandlerArgs) => boolean;

type FormSummaryOptionalProps = {
  getEntryLabel?: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction;
  getListItemProps?: GetFormEntryPropsFunction;
  hasPassword?: boolean;
  maxDepth?: number;
  renderEntry?: RenderFormEntryFunction;
  renderEntryValue?: (
    base: RenderFormValueFunction,
    ...args: Parameters<RenderFormValueFunction>
  ) => ReturnType<RenderFormValueFunction>;
  skip?: (
    base: SkipFormEntryFunction,
    ...args: Parameters<SkipFormEntryFunction>
  ) => ReturnType<SkipFormEntryFunction>;
};

type FormSummaryProps<T extends FormEntries> = FormSummaryOptionalProps & {
  entries: T;
};
