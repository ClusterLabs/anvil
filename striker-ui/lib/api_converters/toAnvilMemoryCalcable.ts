const toAnvilMemoryCalcable = (data: AnvilMemory): AnvilMemoryCalcable => {
  const {
    allocated: rAllocated,
    available: rAvailable,
    reserved: rReserved,
    total: rTotal,
  } = data;

  const allocated = BigInt(rAllocated);
  const available = BigInt(rAvailable);
  const reserved = BigInt(rReserved);
  const total = BigInt(rTotal);

  return {
    allocated,
    available,
    reserved,
    total,
  };
};

export default toAnvilMemoryCalcable;
