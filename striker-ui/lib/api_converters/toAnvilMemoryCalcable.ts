const toAnvilMemoryCalcable = (data: AnvilMemory): AnvilMemoryCalcable => {
  const { allocated: rAllocated, reserved: rReserved, total: rTotal } = data;

  const allocated = BigInt(rAllocated);
  const reserved = BigInt(rReserved);
  const total = BigInt(rTotal);

  return {
    allocated,
    reserved,
    total,
  };
};

export default toAnvilMemoryCalcable;
