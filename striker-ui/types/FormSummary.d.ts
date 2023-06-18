type FormEntry = boolean | null | number | string;

type FormEntries = {
  [key: string]: FormEntries | FormEntry;
};

type GetFormEntryLabelFunction = (key: string, entry: FormEntry) => string;

type GetFormEntryPropsFunction = (
  key: string,
  entry: FormEntry,
  depth: number,
) => import('@mui/material').ListItemProps;

type GetFormEntriesPropsFunction = (
  key: string | undefined,
  entries: FormEntries,
  depth: number,
) => import('@mui/material').ListProps;

type RenderFormValueFunction = (
  key: string,
  entry: FormEntry,
) => import('react').ReactElement;

type RenderFormEntryFunction = (
  key: string,
  entry: FormEntry,
  getLabel: GetFormEntryLabelFunction,
  renderValue: RenderFormValueFunction,
) => import('react').ReactElement;

type FormSummaryOptionalProps = {
  getEntryLabel?: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction;
  getListItemProps?: GetFormEntryPropsFunction;
  hasPassword?: boolean;
  maxDepth?: number;
  renderEntry?: RenderFormEntryFunction;
  renderEntryValue?: RenderFormValueFunction;
};

type FormSummaryProps<T extends FormEntries> = FormSummaryOptionalProps & {
  entries: T;
};
