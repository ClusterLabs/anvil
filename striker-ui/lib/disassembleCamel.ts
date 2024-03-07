import { capitalize } from 'lodash';

const disassembleCamel = (value: string) => {
  const spaced = value.replace(/([a-z\d])([A-Z])/g, '$1 $2');

  return capitalize(spaced);
};

export default disassembleCamel;
