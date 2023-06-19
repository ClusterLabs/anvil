import {
  List as MUIList,
  ListItem as MUIListItem,
  capitalize,
} from '@mui/material';
import { FC, ReactElement, createElement } from 'react';

import FlexBox from './FlexBox';
import { BodyText, MonoText, SensitiveText } from './Text';

const renderEntryValueWithPassword: RenderFormValueFunction = (key, entry) => {
  const textElement = /passw/i.test(key) ? SensitiveText : MonoText;

  return createElement(textElement, { monospaced: true }, String(entry));
};

const buildEntryList = ({
  depth = 0,
  entries,
  getEntryLabel,
  getListProps,
  getListItemProps,
  listKey,
  maxDepth,
  renderEntry,
  renderEntryValue,
}: {
  depth?: number;
  entries: FormEntries;
  getEntryLabel: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction;
  getListItemProps?: GetFormEntryPropsFunction;
  listKey?: string;
  maxDepth: number;
  renderEntry: RenderFormEntryFunction;
  renderEntryValue: RenderFormValueFunction;
}): ReactElement => {
  const result: ReactElement[] = [];

  Object.entries(entries).forEach(([itemKey, entry]) => {
    const itemId = `form-summary-entry-${itemKey}`;

    const nest = entry !== null && typeof entry === 'object';
    const value = nest ? null : entry;

    result.push(
      <MUIListItem
        key={itemId}
        sx={{ paddingLeft: `.${depth * 2}em` }}
        {...getListItemProps?.call(null, itemKey, value, depth)}
      >
        {renderEntry(itemKey, value, getEntryLabel, renderEntryValue)}
      </MUIListItem>,
    );

    if (nest && depth < maxDepth) {
      result.push(
        buildEntryList({
          depth: depth + 1,
          entries: entry,
          getEntryLabel,
          listKey: itemKey,
          maxDepth,
          renderEntry,
          renderEntryValue,
        }),
      );
    }
  });

  const listId = `form-summary-list-${listKey ?? 'root'}`;

  return (
    <MUIList
      dense
      key={listId}
      {...getListProps?.call(null, listKey, entries, depth)}
    >
      {result}
    </MUIList>
  );
};

const FormSummary = <T extends FormEntries>({
  entries,
  getEntryLabel = (key) => {
    const spaced = key.replace(/([a-z\d])([A-Z])/g, '$1 $2');
    const lcased = spaced.toLowerCase();

    return capitalize(lcased);
  },
  getListProps,
  getListItemProps,
  hasPassword,
  maxDepth = 3,
  renderEntry = (key, entry, getLabel, renderValue) => (
    <FlexBox fullWidth growFirst row>
      <BodyText>{getLabel(key, entry)}</BodyText>
      {renderValue(key, entry)}
    </FlexBox>
  ),
  // Prop(s) that rely on other(s).
  renderEntryValue = hasPassword
    ? renderEntryValueWithPassword
    : (key, entry) => <MonoText>{String(entry)}</MonoText>,
}: FormSummaryProps<T>): ReturnType<FC<FormSummaryProps<T>>> =>
  buildEntryList({
    entries,
    getEntryLabel,
    getListProps,
    getListItemProps,
    maxDepth,
    renderEntry,
    renderEntryValue,
  });

export default FormSummary;
