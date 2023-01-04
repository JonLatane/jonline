export async function fetchFunFact(num: number): Promise<string> {
  const response = await fetch(`http://numbersapi.com/${num}/math`);
  return response.text();
}
