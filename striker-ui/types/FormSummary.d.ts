type FormEntries = {
  [key: string]: FormEntries | unknown;
};

type CommonFormEntryHandlerArgs = {
  depth: number;
  entry: unknown;
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
) => import('@mui/material/ListItem').ListItemProps;

type GetFormEntriesPropsFunction<T extends FormEntries> = (args: {
  depth: number;
  entries: T;
  key?: string;
}) => import('@mui/material/List').ListProps;

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

type FormSummaryOptionalProps<T extends FormEntries> = {
  getEntryLabel?: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction<T>;
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

type FormSummaryProps<T extends FormEntries> = FormSummaryOptionalProps<T> & {
  entries: T;
};
