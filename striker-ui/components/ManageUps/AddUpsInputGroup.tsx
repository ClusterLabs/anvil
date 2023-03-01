import { FC, ReactElement, useMemo, useState } from 'react';

import CommonUpsInputGroup from './CommonUpsInputGroup';
import FlexBox from '../FlexBox';
import SelectWithLabel from '../SelectWithLabel';
import Spinner from '../Spinner';
import { BodyText } from '../Text';

const AddUpsInputGroup: FC<AddUpsInputGroupProps> = ({
  loading: isExternalLoading,
  upsTemplate,
}) => {
  const [inputUpsAgentValue, setInputUpsAgentValue] = useState<string>('');

  const upsAgentOptions = useMemo<SelectItem[]>(
    () =>
      upsTemplate
        ? Object.entries(upsTemplate).map<SelectItem>(
            ([upsTypeId, { brand, description }]) => ({
              displayValue: (
                <FlexBox spacing={0}>
                  <BodyText inverted>{brand}</BodyText>
                  <BodyText inverted>{description}</BodyText>
                </FlexBox>
              ),
              value: upsTypeId,
            }),
          )
        : [],
    [upsTemplate],
  );

  const pickUpsAgentElement = useMemo(
    () =>
      upsTemplate && (
        <SelectWithLabel
          formControlProps={{ sx: { marginTop: '.3em' } }}
          id="add-ups-select-agent"
          label="UPS type"
          onChange={({ target: { value: rawNewValue } }) => {
            const newValue = String(rawNewValue);

            setInputUpsAgentValue(newValue);
          }}
          selectItems={upsAgentOptions}
          selectProps={{
            onClearIndicatorClick: () => {
              setInputUpsAgentValue('');
            },
            renderValue: (rawValue) => {
              const upsTypeId = String(rawValue);
              const { brand } = upsTemplate[upsTypeId];

              return brand;
            },
          }}
          value={inputUpsAgentValue}
        />
      ),
    [inputUpsAgentValue, upsAgentOptions, upsTemplate],
  );
  const content = useMemo<ReactElement>(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <FlexBox>
          {pickUpsAgentElement}
          {inputUpsAgentValue && <CommonUpsInputGroup />}
        </FlexBox>
      ),
    [inputUpsAgentValue, isExternalLoading, pickUpsAgentElement],
  );

  return content;
};

export default AddUpsInputGroup;
