
export function storeInitializer(initializer: () => Promise<void>, timeout?: number) {
  setTimeout(async () => {
    while (!globalThis.window) {
      await new Promise((resolve) => setTimeout(resolve, 10));
    }

    await initializer();
  }, timeout);
}
