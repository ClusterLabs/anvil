import fetchJSON from '../fetchers/fetchJSON';

async function getOneAnvil(anvilUUID: string): Promise<GetOneAnvilResponse> {
  const response: GetOneAnvilResponse = {
    anvilStatus: {
      nodes: [],
      timestamp: 0,
    },
    error: null,
  };

  try {
    response.anvilStatus = await fetchJSON(
      `${process.env.DATA_ENDPOINT_BASE_URL}/get_anvil_status?anvil_uuid=${anvilUUID}`,
    );
  } catch (fetchError) {
    response.error = fetchError;
  }

  return response;
}

export default getOneAnvil;
