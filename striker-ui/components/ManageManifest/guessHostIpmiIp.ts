const guessHostIpmiIp = (bcnIp = '', used = '') =>
  used ||
  bcnIp
    .split('.')
    .map<number>((part, index) => {
      let octet = Number(part);

      if (index === 2) {
        octet += 1;
      }

      return octet;
    })
    .join('.');

export default guessHostIpmiIp;
