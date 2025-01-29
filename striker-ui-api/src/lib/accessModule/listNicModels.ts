import { XMLParser } from 'fast-xml-parser';

import { SERVER_PATHS } from '../consts';

import { readFileSync } from 'fs';

const alwaysArray = ['qemu.host', 'qemu.host.nics.nic_model'];

export const listNicModels = async (hostUuid: string) => {
  const xmlParser = new XMLParser({
    ignoreAttributes: false,
    isArray: (tagName, jPath) => alwaysArray.includes(jPath),
    parseAttributeValue: true,
  });

  const xml = readFileSync(SERVER_PATHS.opt.alteeve['qemu-cache.xml'].self, {
    encoding: 'utf-8',
  });

  const parsed = xmlParser.parse(xml);

  const hosts = parsed?.qemu?.host;

  if (!(hosts instanceof Array)) {
    throw new Error(`'${alwaysArray[0]}' is not an array`);
  }

  const host = hosts.find((host) => {
    const { '@_uuid': uuid } = host;

    return uuid === hostUuid;
  });

  const nicModels = host?.nics?.nic_model;

  if (!(nicModels instanceof Array)) {
    throw new Error(`'${alwaysArray[1]}' is not an array`);
  }

  return nicModels;
};
