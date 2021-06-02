const hostsSanitizer = (
  data: Array<AnvilStatusHost>,
): Array<AnvilStatusHost> => {
  return data?.filter((host) => host.host_uuid);
};

export default hostsSanitizer;
