import { sub } from './sub';

export const encrypt: EncryptFunction = async (params) => {
  const [result]: [Encrypted] = await sub('encrypt_password', {
    params: [params],
    pre: ['Account'],
  });

  return result;
};
