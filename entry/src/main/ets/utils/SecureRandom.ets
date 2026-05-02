import { cryptoFramework } from '@kit.CryptoArchitectureKit';

// Cryptographically secure random source for UI-safe sampling.
// Returns a number in [0, 1).
export function secureRandomNumber(): number {
  const rand = cryptoFramework.createRandom();
  const randData = rand.generateRandomSync(8);
  const bytes = randData.data;
  let v = BigInt(0);
  for (let i = 0; i < 8; i++) {
    v = (v << BigInt(8)) | BigInt(bytes[i]);
  }
  return Number(v >> BigInt(11)) / Number(BigInt(1) << BigInt(53));
}
