import fetchJSON from '../fetchers/fetchJSON';

async function getAllAnvil(): Promise<GetAllAnvilResponse> {
  const response: GetAllAnvilResponse = {
    anvilList: {
      anvils: [],
    },
    error: null,
  };

  try {
    response.anvilList = await fetchJSON(
      `${process.env.DATA_ENDPOINT_BASE_URL}/get_anvils`,
    );
  } catch (fetchError) {
    response.error = fetchError;
  }

  return response;
}

export default getAllAnvil;
