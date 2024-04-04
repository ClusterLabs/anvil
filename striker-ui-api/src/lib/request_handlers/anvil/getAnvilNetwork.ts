import assert from 'assert';
import { RequestHandler } from 'express';

import { REP_UUID } from '../../consts';

import { getAnvilData, getHostData, getNetworkData } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

const degrade = (current: string) =>
  current === 'optimal' ? 'degraded' : current;

const compare = (a: string, b: string) => (a > b ? 1 : -1);

const buildSubnodeBonds = (
  ifaces: AnvilDataSubnodeNetwork['interface'],
): AnvilDetailSubnodeBond[] => {
  const bondList = Object.entries(ifaces)
    .sort(([an, { type: at }], [bn, { type: bt }]) => {
      const ab = at === 'bond';
      const bb = bt === 'bond';

      if (ab && bb) return compare(an, bn);
      if (ab) return -1;
      if (bb) return 1;

      return compare(an, bn);
    })
    .reduce<{
      [bondUuid: string]: AnvilDetailSubnodeBond;
    }>((previous, [ifname, ifvalue]) => {
      const { type } = ifvalue;

      if (type === 'bond') {
        const { active_interface, uuid: bondUuid } =
          ifvalue as AnvilDataHostNetworkBond;

        previous[bondUuid] = {
          active_interface,
          bond_name: ifname,
          bond_uuid: bondUuid,
          links: [],
        };
      } else if (type === 'interface') {
        const {
          bond_uuid: bondUuid,
          operational,
          speed,
          uuid: linkUuid,
        } = ifvalue as AnvilDataHostNetworkLink;

        // Link without bond UUID can be ignored
        if (!REP_UUID.test(bondUuid)) return previous;

        const {
          [bondUuid]: { active_interface, links },
        } = previous;

        let linkState: string = operational === 'up' ? 'optimal' : 'down';

        links.forEach((xLink) => {
          const { link_speed: xlSpeed, link_state: xlState } = xLink;

          if (xlSpeed < speed) {
            // Seen link is slower than current link, mark seen link as 'degraded'
            xLink.link_state = degrade(xlState);
          } else if (xlSpeed > speed) {
            // Current link is slower than seen link, mark current link as 'degraded'
            linkState = degrade(linkState);
          }
        });

        links.push({
          is_active: ifname === active_interface,
          link_name: ifname,
          link_speed: speed,
          link_state: linkState,
          link_uuid: linkUuid,
        });
      }

      return previous;
    }, {});

  return Object.values(bondList);
};

export const getAnvilNetwork: RequestHandler<
  AnvilDetailParamsDictionary
> = async (request, response) => {
  const {
    params: { anvilUuid: rAnUuid },
  } = request;

  const anUuid = sanitize(rAnUuid, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_UUID.test(anUuid),
      `Param UUID must be a valid UUIDv4; got [${anUuid}]`,
    );
  } catch (error) {
    perr(`Failed to assert value during get anvil network; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let ans: AnvilDataAnvilListHash;
  let hosts: AnvilDataHostListHash;

  try {
    ans = await getAnvilData();
    hosts = await getHostData();
  } catch (error) {
    perr(`Failed to get anvil and host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const {
    anvil_uuid: {
      [anUuid]: {
        anvil_node1_host_uuid: n1uuid,
        anvil_node2_host_uuid: n2uuid,
      },
    },
  } = ans;

  const rsbody: AnvilDetailNetworkSummary = { hosts: [] };

  for (const hostUuid of [n1uuid, n2uuid]) {
    try {
      const {
        host_uuid: {
          [hostUuid]: { short_host_name: hostName },
        },
      } = hosts;

      const { [hostName]: subnodeNetwork } = await getNetworkData(
        hostUuid,
        hostName,
      );

      const { interface: ifaces } = subnodeNetwork as AnvilDataSubnodeNetwork;

      rsbody.hosts.push({
        bonds: buildSubnodeBonds(ifaces),
        host_name: hostName,
        host_uuid: hostUuid,
      });
    } catch (error) {
      perr(`Failed to get host ${hostUuid} network data; CAUSE: ${error}`);

      return response.status(500).send();
    }
  }

  return response.json(rsbody);
};
