const hostsSanitizer = (data: Array<AnvilStatusHost>): Array<AnvilStatusHost> =>
  data?.filter((host) => host.host_uuid);

export default hostsSanitizer;
