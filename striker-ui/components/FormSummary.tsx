import { Box, List as MUIList, ListItem as MUIListItem } from '@mui/material';
import { FC, ReactElement } from 'react';

import FlexBox from './FlexBox';
import { BodyText, MonoText, SensitiveText } from './Text';
import disassembleCamel from '../lib/disassembleCamel';

const renderEntryValueWithMono: RenderFormValueFunction = ({ entry }) => (
  <MonoText whiteSpace="nowrap">{String(entry)}</MonoText>
);

const renderEntryValueWithPassword: RenderFormValueFunction = (args) => {
  const { entry, key } = args;

  return /passw/i.test(key) ? (
    <SensitiveText monospaced>{String(entry)}</SensitiveText>
  ) : (
    renderEntryValueWithMono(args)
  );
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
  skip,
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
  skip: Exclude<FormSummaryOptionalProps['skip'], undefined>;
}): ReactElement => {
  const result: ReactElement[] = [];

  Object.entries(entries).forEach(([itemKey, entry]) => {
    const itemId = `form-summary-entry-${itemKey}`;

    const nest = entry !== null && typeof entry === 'object';

    const value = nest ? null : entry;

    const fnArgs: CommonFormEntryHandlerArgs = {
      depth,
      entry: value,
      key: itemKey,
    };

    if (skip(({ key }) => !/confirm/i.test(key), fnArgs)) {
      result.push(
        <MUIListItem
          key={itemId}
          sx={{ paddingLeft: `${depth}em` }}
          {...getListItemProps?.call(null, fnArgs)}
        >
          {renderEntry({
            depth,
            entry: value,
            getLabel: getEntryLabel,
            key: itemKey,
            nest,
            renderValue: renderEntryValue,
          })}
        </MUIListItem>,
      );
    }

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
          skip,
        }),
      );
    }
  });

  const listId = `form-summary-list-${listKey ?? 'root'}`;

  return (
    <MUIList
      dense
      disablePadding
      key={listId}
      {...getListProps?.call(null, { depth, entries, key: listKey })}
    >
      {result}
    </MUIList>
  );
};

const FormSummary = <T extends FormEntries>({
  entries,
  getEntryLabel = ({ cap, key }) => cap(key),
  getListProps,
  getListItemProps,
  hasPassword,
  maxDepth = 3,
  renderEntry = ({ depth, entry, getLabel, key, nest, renderValue }) => (
    <FlexBox fullWidth growFirst row maxWidth="100%">
      <BodyText>
        {getLabel({ cap: disassembleCamel, depth, entry, key })}
      </BodyText>
      <Box sx={{ maxWidth: '100%', overflowX: 'scroll' }}>
        {!nest && renderValue({ depth, entry, key })}
      </Box>
    </FlexBox>
  ),
  // Prop(s) that rely on other(s).
  renderEntryValue = (args) => {
    const { entry } = args;

    if (['', null, undefined].some((bad) => entry === bad)) {
      return <BodyText>none</BodyText>;
    }

    return hasPassword
      ? renderEntryValueWithPassword(args)
      : renderEntryValueWithMono(args);
  },
  skip = (base, ...args) => base(...args),
}: FormSummaryProps<T>): ReturnType<FC<FormSummaryProps<T>>> =>
  buildEntryList({
    entries,
    getEntryLabel,
    getListProps,
    getListItemProps,
    maxDepth,
    renderEntry,
    renderEntryValue,
    skip,
  });

export default FormSummary;
