import { DataSizeUnit } from 'format-data-size';

const units: DataSizeUnit[] = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];

const options = units.map<SelectItem<DataSizeUnit>>((unit) => ({
  value: unit,
}));

export { options as DSIZE_SELECT_ITEMS, units as DSIZE_UNITS };
